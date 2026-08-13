#!/usr/bin/env bash
# Update package.nix and package-lock.json to the latest @deepseek-ai/dsh
# release. Requires curl, jq, npm, nix, prefetch-npm-deps (all provided by
# `nix develop`). Pass a dist-tag as $1 to track something other than latest.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

tag="${1:-latest}"
latest=$(curl -fsSL "https://registry.npmjs.org/@deepseek-ai%2Fdsh" | jq -r --arg tag "$tag" '."dist-tags"[$tag]')
current=$(sed -n 's/^ *version = "\([^"]*\)";/\1/p' package.nix | head -1)

if [ "$latest" = "$current" ]; then
  echo "Already up to date: $current"
  exit 0
fi

echo "Updating $current -> $latest"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# Regenerate the lockfile from the published package.json, minus
# devDependencies (see package.nix for why they are dropped).
curl -fsSL "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-$latest.tgz" | tar -xz -C "$workdir"
jq 'del(.devDependencies)' "$workdir/package/package.json" > "$workdir/package.json"
(cd "$workdir" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)
cp "$workdir/package-lock.json" package-lock.json

src_hash=$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --unpack "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-$latest.tgz")")
npm_deps_hash=$(prefetch-npm-deps package-lock.json)

sed -i \
  -e "s|version = \"$current\";|version = \"$latest\";|" \
  -e "s|srcHash = \"[^\"]*\";|srcHash = \"$src_hash\";|" \
  -e "s|npmDepsHash = \"[^\"]*\";|npmDepsHash = \"$npm_deps_hash\";|" \
  package.nix

echo "Updated to $latest"

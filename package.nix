{ lib
, buildNpmPackage
, fetchzip
, nodejs_24
, python3
, jq
}:

let
  version = "0.1.0-rc.6";
  srcHash = "sha256-caYhF/Q3wBGCs6nW80RCEzWPF5eS3vs5kw7dyGjlLdo=";
  npmDepsHash = "sha256-9pkQ50fOb2pv44zDWRdW5PnZCv7gvJX9I9tKsblAIXA=";
in
(buildNpmPackage.override { nodejs = nodejs_24; }) {
  pname = "deepseek-harness";
  inherit version npmDepsHash;

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${version}.tgz";
    hash = srcHash;
  };

  # python3 is required for the node-gyp fallback when node-pty has no
  # usable prebuild for the current platform.
  nativeBuildInputs = [ python3 ];

  # The npm tarball ships prebuilt JS; devDependencies only exist for the
  # monorepo build. Drop them so the vendored lockfile (generated without
  # them) stays in sync with package.json for `npm ci`. jq is referenced by
  # absolute path because this hook also runs inside the fetchNpmDeps
  # derivation, which does not get our nativeBuildInputs.
  postPatch = ''
    ${jq}/bin/jq 'del(.devDependencies)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    description = "DeepSeek Harness (dsh) - open-source agent harness by DeepSeek AI";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "dsh";
  };
}

# deepseek-harness-nix

Nix package for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`),
the plugin-based agent harness by DeepSeek AI. Packages the
[`@deepseek-ai/dsh`](https://www.npmjs.com/package/@deepseek-ai/dsh) npm release.

DeepSeek Harness is in developer preview; expect breaking changes between versions.

## Run without installing

```sh
nix run github:chinrw/deepseek-harness-nix -- web
```

## Install

```sh
nix profile install github:chinrw/deepseek-harness-nix
```

### Flake input

```nix
{
  inputs.deepseek-harness.url = "github:chinrw/deepseek-harness-nix";
}
```

Then add to your packages:

```nix
environment.systemPackages = [
  inputs.deepseek-harness.packages.${pkgs.system}.default
];
```

### Overlay

```nix
{
  nixpkgs.overlays = [ inputs.deepseek-harness.overlays.default ];
  environment.systemPackages = [ pkgs.deepseek-harness ];
}
```

## Binary cache

CI pushes builds for x86_64-linux, aarch64-linux, and aarch64-darwin to
[Cachix](https://app.cachix.org/cache/chinrw):

```sh
cachix use chinrw
```

Or in flake config:

```nix
{
  nixConfig = {
    extra-substituters = [ "https://chinrw.cachix.org" ];
    extra-trusted-public-keys = [ "chinrw.cachix.org-1:TShvVLuNeWsGoLW2/VGdUT4k8T+03RuQEXA6ZiN16Rw=" ];
  };
}
```

## How the package works

The npm tarball of `@deepseek-ai/dsh` ships prebuilt JS but pulls in ~600
dependencies, so the build uses `buildNpmPackage` with a vendored
`package-lock.json` (generated without devDependencies, which only exist for
the upstream monorepo build). `scripts/update.sh` bumps the version,
regenerates the lockfile, and refreshes both hashes; CI runs it daily.

## Update manually

```sh
nix develop -c ./scripts/update.sh
```

## License

MIT, same as upstream DeepSeek Harness.

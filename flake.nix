{
  description = "Nix package for DeepSeek Harness (dsh) - open-source agent harness by DeepSeek AI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { self
    , nixpkgs
    , systems
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.foldl' lib.recursiveUpdate { } (map f (import systems));

      overlay = final: prev: {
        deepseek-harness = final.callPackage ./package.nix { };
      };
    in
    eachSystem
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages.${system} = {
          default = pkgs.deepseek-harness;
          deepseek-harness = pkgs.deepseek-harness;
          dsh = pkgs.deepseek-harness;
        };

        apps.${system} = {
          default = {
            type = "app";
            program = "${pkgs.deepseek-harness}/bin/dsh";
          };
          dsh = {
            type = "app";
            program = "${pkgs.deepseek-harness}/bin/dsh";
          };
        };

        devShells.${system}.default = pkgs.mkShell {
          packages = with pkgs; [
            nixpkgs-fmt
            cachix
            nodejs_24
            prefetch-npm-deps
            jq
          ];
        };
      }) // {
      overlays.default = overlay;
    };
}

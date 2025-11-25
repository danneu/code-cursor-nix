{
  description = "Nix package for Cursor - AI-powered code editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: {
        code-cursor = final.callPackage ./package.nix {
          vscode-generic = "${nixpkgs}/pkgs/applications/editors/vscode/generic.nix";
        };
      };
      # Only support Linux (AppImage doesn't work on Darwin)
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.code-cursor;
          code-cursor = pkgs.code-cursor;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.code-cursor}/bin/cursor";
          };
          code-cursor = {
            type = "app";
            program = "${pkgs.code-cursor}/bin/cursor";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            nix-prefetch-url
            cachix
          ];
        };
      }
    )
    // {
      overlays.default = overlay;
      homeManagerModules.default = import ./hm-module.nix;
    };
}

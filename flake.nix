{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    {
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShell = pkgs.mkShell {
        packages = [
          pkgs.alejandra
          pkgs.biome
          pkgs.bun
        ];
      };

      formatter = pkgs.alejandra;

      packages.update-overlays = pkgs.writeShellScript "update-overlays" ''
        ${pkgs.bun}/bin/bun ${./gen.ts}
      '';
    });
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs-python = {
      url = "github:cachix/nixpkgs-python";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nixpkgs-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    flake-utils,
    ...
  }:
    {
      overlays = {
        nodejs = import ./nodejs/overlay.nix;
        python = import ./python/overlay.nix inputs.nixpkgs-python;
        rust = import ./rust/overlay.nix inputs.rust-overlay;
        ruby = import ./ruby/overlay.nix inputs.nixpkgs-ruby;
      };
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
          pkgs.nodePackages_latest.typescript-language-server
        ];
      };

      formatter = pkgs.alejandra;

      packages.update-overlays = pkgs.writeShellScriptBin "update-overlays" ''
        ${pkgs.bun}/bin/bun ./gen.ts
      '';

      packages.nodejsVersions = pkgs.callPackage ./nodejs {};
      packages.pythonVersions = pkgs.callPackage ./python {inherit (inputs) nixpkgs-python;};
      packages.rustVersions = pkgs.callPackage ./rust {inherit (inputs) rust-overlay;};
      packages.rubyVersions = pkgs.callPackage ./ruby {inherit (inputs) nixpkgs-ruby;};
    });
}

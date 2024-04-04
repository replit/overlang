{
  buildPackages,
  callPackage,
  fetchurl,
  lib,
  llvmPackages,
  llvmPackages_15,
  overrideCC,
  python3,
  stdenv,
}: let
  patches = lib.mapAttrs (_: fetchurl) {
    bypass-darwin-xcrun-node16 = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/bypass-darwin-xcrun-node16.patch";
      hash = "sha256-z8QFSyXq0WuNheJIJyfN/SaVjjOVaHlEgT9H8Rt52Dg=";
    };

    disable-darwin-v8-system-instrumentation = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/disable-darwin-v8-system-instrumentation.patch";
      hash = "sha256-YlHUgJE2+gTNRICl5+S1QoBka+ySXB5ExdnjkbHj9/k=";
    };

    disable-darwin-v8-system-instrumentation-node19 = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/disable-darwin-v8-system-instrumentation-node19.patch";
      hash = "sha256-Q10WBoETfgNkiMKLDGTTmW6b0jbEaWZBKPjoQ3qVkNw=";
    };

    node-npm-build-npm-package-logic = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/node-npm-build-npm-package-logic.patch";
      hash = "sha256-whn2axmgKc1WM2cuNYNtb4zyxT9ibNaC0eEFhd1NDt4=";
    };

    revert-arm64-pointer-auth = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/revert-arm64-pointer-auth.patch";
      hash = "sha256-0tX41vi4vgGKiR+564KwHAy2pb260hnshqryUinEzyE=";
    };

    trap-handler-backport = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/trap-handler-backport.patch";
      hash = "sha256-gghfFTZdTaMOyaoC+5vg70+rpTAKLHngSj/oVTTElw0=";
    };
  };

  mkArgs = version: sha256: let
    major = lib.versions.major version;

    patches-18 = [
      patches.bypass-darwin-xcrun-node16
      patches.disable-darwin-v8-system-instrumentation
      patches.node-npm-build-npm-package-logic
      patches.revert-arm64-pointer-auth
      patches.trap-handler-backport
    ];

    patches-19 = [
      patches.bypass-darwin-xcrun-node16
      patches.disable-darwin-v8-system-instrumentation-node19
      patches.revert-arm64-pointer-auth
    ];

    patches-20 = [
      patches.bypass-darwin-xcrun-node16
      patches.disable-darwin-v8-system-instrumentation-node19
      patches.node-npm-build-npm-package-logic
      patches.revert-arm64-pointer-auth
    ];

    patches-21 = [
      patches.bypass-darwin-xcrun-node16
      patches.disable-darwin-v8-system-instrumentation-node19
      patches.node-npm-build-npm-package-logic
    ];

    version-patches =
      if major == "21"
      then patches-21
      else if major == "20"
      then patches-20
      else if major == "19"
      then patches-19
      else if major == "18"
      then patches-18
      else builtins.throw "unrecognized major version ${builtins.toString major}";
  in {
    inherit sha256 version;
    patches = version-patches;
  };

  mkOverrides = version: data: let
    major = lib.versions.major version;

    stdenv15 = overrideCC buildPackages.llvmPackages_15.stdenv (buildPackages.llvmPackages_15.stdenv.cc.override {
      inherit (buildPackages.llvmPackages) libcxx;
    });

    actual-stdenv =
      if major == "18" && lib.versionAtLeast (lib.getVersion buildPackages.stdenv.cc.cc) "16"
      then stdenv15
      else stdenv;
  in {
    python = python3;
    stdenv = actual-stdenv;
    buildPackages = buildPackages // {stdenv = actual-stdenv;};
  };
in
  lib.mapAttrs
  (version: data:
    (callPackage ./build-node.nix (mkOverrides version data) (mkArgs version data)).overrideAttrs (old: {
      buildPhase = ''
        echo "$(clang --version)"
        echo "$(which clang)"

        ${old.buildPhase or ""}
      '';
    }))
  (builtins.fromJSON (builtins.readFile ./versions.json))

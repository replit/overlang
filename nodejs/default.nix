{
  callPackage,
  fetchurl,
  lib,
  python3,
}: let
  registry = builtins.fromJSON (builtins.readFile ./versions.json);

  patches = lib.mapAttrs (_: fetchurl) {
    bypass-darwin-xcrun-node16 = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/bypass-darwin-xcrun-node16.patch";
      hash = "sha256-z8QFSyXq0WuNheJIJyfN/SaVjjOVaHlEgT9H8Rt52Dg=";
    };

    disable-darwin-v8-system-instrumentation-node19 = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/disable-darwin-v8-system-instrumentation-node19.patch";
      hash = "sha256-Q10WBoETfgNkiMKLDGTTmW6b0jbEaWZBKPjoQ3qVkNw=";
    };

    node-npm-build-npm-package-logic = {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-23.11/pkgs/development/web/nodejs/node-npm-build-npm-package-logic.patch";
      hash = "sha256-whn2axmgKc1WM2cuNYNtb4zyxT9ibNaC0eEFhd1NDt4=";
    };
  };

  mkArgs = version: sha256: let
    major = lib.versions.major version;

    patches-21 = [
      patches.bypass-darwin-xcrun-node16
      patches.disable-darwin-v8-system-instrumentation-node19
      patches.node-npm-build-npm-package-logic
    ];

    version-patches =
      if major == "21"
      then patches-21
      else builtins.throw "unrecognized major version ${builtins.toString major}";
  in {
    inherit sha256 version;
    patches = version-patches;
  };
in
  lib.mapAttrs
  (version: data: callPackage ./build-node.nix {python = python3;} (mkArgs version data))
  registry

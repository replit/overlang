{
  lib,
  nixpkgs-python,
  system,
}: let
  python-pkgs = nixpkgs-python.packages.${system};

  isPythonVersion = version: let
    semver-parts = lib.splitString "." version;

    is-v3-release = (lib.elemAt semver-parts 0) == "3";
    is-three-version-parts = builtins.length semver-parts == 3;
    is-3-0-0 = semver-parts == ["3" "0"];
  in
    is-3-0-0 || is-v3-release && is-three-version-parts;

  versions = lib.filterAttrs (version: _: isPythonVersion version) python-pkgs;
in
  versions

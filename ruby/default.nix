{
  lib,
  nixpkgs-ruby,
  system,
}: let
  isRubyVersion = version: let
    version-part = builtins.elemAt (lib.splitString "-" version);

    is-ruby = version-part 0 == "ruby";

    is-star-alias = lib.hasSuffix "*" version;
    is-other-alias = lib.pipe (version-part 1) [
      (lib.splitString ".")
      builtins.length
      (len: len != 3)
    ];
    is-alias = is-star-alias || is-other-alias;

    is-not-supported = lib.hasPrefix "1." (version-part 1);
  in
    is-ruby && !is-alias && !is-not-supported;

  versions = lib.pipe nixpkgs-ruby.packages.${system} [
    (lib.filterAttrs (version: _: isRubyVersion version))
    lib.attrsToList
    (builtins.map ({
      name,
      value,
    }: {
      inherit value;
      name = lib.removePrefix "ruby-" name;
    }))
    builtins.listToAttrs
  ];
in
  versions

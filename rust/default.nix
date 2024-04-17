{
  extend,
  lib,
  rust-overlay,
  symlinkJoin,
  system,
}: let
  pkgs = extend rust-overlay.overlays.default;

  mkDistribution = toolchain:
    toolchain.default.overrideAttrs (prev: {
      passthru =
        prev.passthru
        // {
          components = let
            component-names = [
              "cargo"
              "clippy"
              "clippy-preview"
              "llvm-tools"
              "llvm-tools-preview"
              "rls"
              "rls-preview"
              "rust"
              "rust-analysis"
              "rust-analyzer"
              "rust-analyzer-preview"
              "rust-docs"
              "rust-src"
              "rust-std"
              "rustc"
              "rustc-dev"
              "rustfmt"
              "rustfmt-preview"
            ];
          in
            lib.getAttrs component-names toolchain;

          profiles = lib.getAttrs ["complete" "default" "minimal"] toolchain;

          withComponents = components:
            symlinkJoin {
              name = "rust-toolchain-with-components";
              paths = lib.getAttrs components toolchain;
            };
        };
    });

  stable = lib.mapAttrs (version: mkDistribution) (lib.attrsets.removeAttrs pkgs.rust-bin.stable ["latest"]);
  beta = lib.mapAttrs (version: mkDistribution) (lib.attrsets.removeAttrs pkgs.rust-bin.beta ["latest"]);
  nightly = lib.mapAttrs (version: mkDistribution) (lib.attrsets.removeAttrs pkgs.rust-bin.nightly ["latest"]);
in {
  inherit stable beta nightly;
}

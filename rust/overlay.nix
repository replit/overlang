rust-overlay: final: prev: {
  rustVersions = final.callPackage ./default.nix {
    inherit rust-overlay;
  };
}

nixpkgs-python: final: prev: {
  pythonVersions = final.callPackage ./. {inherit nixpkgs-python;};
}

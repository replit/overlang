nixpkgs-ruby: final: prev: {
  rubyVersions = final.callPackage ./. {inherit nixpkgs-ruby;};
}

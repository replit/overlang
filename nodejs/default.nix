{
  callPackage,
  fetchurl,
}: let
  build = {v21 = callPackage ./build/v21.nix {};};

  versions = {
    "21.0.0" = build.v21 {
      version = "21.0.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.0.0/node-v21.0.0.tar.xz";
        sha256 = "bc56192b951ad183506dca9acf7a4d0c02591140b7fc8f25661375199266f3f2";
      };
    };

    "21.1.0" = build.v21 {
      version = "21.1.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.1.0/node-v21.1.0.tar.xz";
        sha256 = "91ac72e4444c5e5ab4b448030a61ffa95acd35d34a9d31d2d220ee2bed01b925";
      };
    };

    "21.2.0" = build.v21 {
      version = "21.2.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.2.0/node-v21.2.0.tar.xz";
        sha256 = "d57c9cea394764fa1d9af51e52c7449f71193e9d44c4a81fbedec653ec827707";
      };
    };

    "21.3.0" = build.v21 {
      version = "21.3.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.3.0/node-v21.3.0.tar.xz";
        sha256 = "ab4172ec827f770c6c3b4b6f30824104137eda474848e84d55ed55b341e67725";
      };
    };

    "21.4.0" = build.v21 {
      version = "21.4.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.4.0/node-v21.4.0.tar.xz";
        sha256 = "7a80f6527654602d7358c5be2eefc4f80a64c8901630a83977b073c34f25479c";
      };
    };

    "21.5.0" = build.v21 {
      version = "21.5.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.5.0/node-v21.5.0.tar.xz";
        sha256 = "afd7d4713573cd814f7e4df320de8d5c8e147b4101bc9fbbe2a6d52eb5f8b072";
      };
    };

    "21.6.0" = build.v21 {
      version = "21.6.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.6.0/node-v21.6.0.tar.xz";
        sha256 = "20265bfcfa73c8b46b32378641d38b009dfc980eb28192c3d5ab7f6986fdb1e3";
      };
    };

    "21.6.1" = build.v21 {
      version = "21.6.1";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.6.1/node-v21.6.1.tar.xz";
        sha256 = "7a82f356d1dcba5d766f0e1d4c750e2e18d6290b710b7d19a8725241e7af1f60";
      };
    };

    "21.6.2" = build.v21 {
      version = "21.6.2";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.6.2/node-v21.6.2.tar.xz";
        sha256 = "191294d445d1e6800359acc8174529b1e18e102147dc5f596030d3dce96931e5";
      };
    };

    "21.7.0" = build.v21 {
      version = "21.7.0";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.7.0/node-v21.7.0.tar.xz";
        sha256 = "e41eefe1e59624ee7f312c38f8f7dfc11595641acb2293d21176f03d2763e9d4";
      };
    };

    "21.7.1" = build.v21 {
      version = "21.7.1";
      src = fetchurl {
        url = "https://nodejs.org/download/release/v21.7.1/node-v21.7.1.tar.xz";
        sha256 = "1272b6e129d564dbde17527b844210b971c20a70ae729268186b7cb9d990a64b";
      };
    };
  };

  latest-aliases = {
    latest = latest-aliases."21.latest";
    "21.latest" = latest-aliases."21.7.latest";
    "21.0.latest" = versions."21.0.0";
    "21.1.latest" = versions."21.1.0";
    "21.2.latest" = versions."21.2.0";
    "21.3.latest" = versions."21.3.0";
    "21.4.latest" = versions."21.4.0";
    "21.5.latest" = versions."21.5.0";
    "21.6.latest" = versions."21.6.2";
    "21.7.latest" = versions."21.7.1";
  };
in
  versions // latest-aliases

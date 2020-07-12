self: super:
let
  buildNodejs =
    super.callPackage <nixpkgs/pkgs/development/web/nodejs/nodejs.nix> { };
in {
  jruby_9_2_9_0 = super.jruby.overrideAttrs (oldAtrrs: rec {
    version = "9.2.9.0";
    src = super.fetchurl {
      url =
        "https://s3.amazonaws.com/jruby.org/downloads/${version}/jruby-bin-${version}.tar.gz";
      sha256 = "04grdf57c1dgragm17yyjk69ak8mwiwfc1vjzskzcaag3fwgplyf";
    };
    # Apply this patch if you want the default GEM_HOME to be the user directory
    #patches = [ ./pkgs/ruby/jruby-9.2.9.0.patch ];
  });

  jruby_9_2_12_0 = super.jruby.overrideAttrs (oldAtrrs: rec {
    version = "9.2.12.0";
    src = super.fetchurl {
      url =
        "https://s3.amazonaws.com/jruby.org/downloads/${version}/jruby-bin-${version}.tar.gz";
      sha256 = "013c1q1n525y9ghp369z1jayivm9bw8c1x0g5lz7479hqhj62zrh";
    };
  });

  nodejs-12_13_0 = buildNodejs {
    version = "12.13.0";
    sha256 = "1xmy73q3qjmy68glqxmfrk6baqk655py0cic22h1h0v7rx0iaax8";
  };

  rbenv = super.callPackage ./pkgs/ruby/rbenv.nix { };
  ruby-build = super.callPackage ./pkgs/ruby/ruby-build.nix { };

  nodenv = super.callPackage ./pkgs/node/nodenv.nix { };
  node-build = super.callPackage ./pkgs/node/node-build.nix { };

  comma = import (super.fetchFromGitHub {
    owner = "Shopify";
    repo = "comma";
    rev = "4a62ec17e20ce0e738a8e5126b4298a73903b468";
    sha256 = "0n5a3rnv9qnnsrl76kpi6dmaxmwj1mpdd2g0b4n1wfimqfaz6gi1";
  }) { };
}

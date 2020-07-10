self: super: {

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

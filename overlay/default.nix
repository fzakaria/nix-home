self: super:
# this tracks the unstable branch
let nixpkgs = import (import ../nix/sources.nix).nixpkgs { };
in {
  comma = import (super.fetchFromGitHub {
    owner = "Shopify";
    repo = "comma";
    rev = "4a62ec17e20ce0e738a8e5126b4298a73903b468";
    sha256 = "0n5a3rnv9qnnsrl76kpi6dmaxmwj1mpdd2g0b4n1wfimqfaz6gi1";
  }) { };

  cachix =
    (import (fetchTarball "https://cachix.org/api/v1/install") { }).cachix;

  tailscale = nixpkgs.tailscale;
}

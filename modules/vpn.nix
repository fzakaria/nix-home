{ config, pkgs, ... }:
let nixpkgs = (import ../nix/sources.nix).nixos;
in {

  # We use tailscale to setup our VPN across our machines
  imports = [ (nixpkgs + "/nixos/modules/services/networking/tailscale.nix") ];

  services.tailscale = {
  	enable = true;
  };
}

{ config, pkgs, ... }: 
let sources = import ../nix/sources.nix;
in
{

  nixpkgs = {
    # Add the global overlay for all machines
    overlays = [ (import ../nixpkgs/overlay.nix) ];
    config = import ../nixpkgs/config.nix;
  };

  # Put nixpkgs into /etc/nixpkgs for convenience
  environment.etc.nixpkgs.source = sources.nixpkgs;
  # Point nixpath to that nixpkgs so that the system uses the same nix
  nix = {
    nixPath =
      [ "nixpkgs=/etc/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" ];
  };

}

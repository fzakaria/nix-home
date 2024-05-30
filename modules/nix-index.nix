# lets enable nix-index
# but let's use nix-index-database that has a prebuilt database of packages
{ config, pkgs, ... }:
let sources = import ../nix/sources.nix;
in
{
  imports = [
    (sources.nix-index-database + "/nixos-module.nix")
  ];
  
  # this is needed for the nix-index-database nixos module since we are not using flakes
  _module.args.databases = import (sources.nix-index-database + "/packages.nix");
  programs.nix-index-database.comma.enable = true;
  # nix-index provides it's own command-not-found functionality
  programs.command-not-found.enable = false;
}
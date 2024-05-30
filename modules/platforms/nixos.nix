{ config, pkgs, ... }:
let sources = import ../../nix/sources.nix;
in
{

  imports = [ 
    (sources.home-manager + "/nixos") 
    (sources.nix-index-database + "/nixos-module.nix")
  ];

  # useful NixOS home-manager settings
  # https://nix-community.github.io/home-manager/index.xhtml#sec-install-nixos-module
  home-manager = {
    # By default packages will be installed to $HOME/.nix-profile
    # but they can be installed to /etc/profiles if useUserPackages is true
    # This is necessary if, for example, you wish to use nixos-rebuild build-vm
    useUserPackages = true;

    # By default, Home Manager uses a private pkgs instance that is configured via the home-manager.users.<name>.nixpkgs options.
    # To instead use the global pkgs that is configured via the system level nixpkgs options, set
    useGlobalPkgs = true;
  };

  # lets enable nix-index
  # this is needed for the nix-index-database nixos module since we are not using flakes
  _module.args.databases = import (sources.nix-index-database + "/packages.nix");
  programs.nix-index-database.comma.enable = true;
  # nix-index provides it's own command-not-found functionality
  programs.command-not-found.enable = false;

}

{ config, pkgs, ... }:
let
  sources = import ../../nix/sources.nix;
  nixpkgs' = sources.nixos;
  home-manager = sources.home-manager;
in {

  imports = [
    (home-manager + "/nixos")
  ];

  nixpkgs = {
    pkgs = import "${nixpkgs'}" { inherit (config.nixpkgs) config; };
    nixPath = [ "nixpkgs=${nixpkgs'}" ];
  };

  # useful NixOS home-manager settings
  # https://rycee.gitlab.io/home-manager/index.html#sec-install-nixos-module
  home-manager = {
    # By default packages will be installed to $HOME/.nix-profile
    # but they can be installed to /etc/profiles if useUserPackages is true
    # This is necessary if, for example, you wish to use nixos-rebuild build-vm
    useUserPackages = true;

    # By default, Home Manager uses a private pkgs instance that is configured via the home-manager.users.<name>.nixpkgs options.
    # To instead use the global pkgs that is configured via the system level nixpkgs options, set
    useGlobalPkgs = true;
  };
}

{ config, pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
    ../../modules/users.nix
    ../../modules/acme.nix
    ../../modules/quassel.nix
    ../../modules/vpn.nix
  ];

  networking = {
    hostName = "altaria";
    domain = "fzakaria.com";
  };

}

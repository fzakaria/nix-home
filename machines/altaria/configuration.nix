{ config, pkgs, ... }:
let nixpkgs = (import ../../nix/sources.nix).nixos;
in {
  imports = [
    ./hardware-configuration.nix
    (nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
    ../../modules/users.nix
  ];

  networking = {
  	hostName = "altaria.fzakaria.com";
  };
}

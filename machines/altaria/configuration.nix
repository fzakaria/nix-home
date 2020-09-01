{ config, pkgs, ... }:
let nixpkgs = (import ../../nix/sources.nix).nixos;
in {
  imports = [
    ./hardware-configuration.nix
    (nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
  ];

  users.extraUsers.fmzakari = {
    # This automatically sets group to users, createHome to true,
    # home to /home/username, useDefaultShell to true, and isSystemUser to false
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.fmzakari = import ../../modules/home-manager.nix;

}

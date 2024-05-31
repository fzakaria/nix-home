{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
    ../../modules/users.nix
    ./acme.nix
    ./uassel.nix
    ../../modules/vpn.nix
  ];

  networking = {
    hostName = "altaria";
    domain = "fzakaria.com";
  };

  # testing lametun
  networking.firewall.allowedUDPPorts = [1234];
}

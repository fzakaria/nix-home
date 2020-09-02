{ config, pkgs, ... }: {

  # Quassel IRC is a modern, cross-platform, distributed IRC client.
  # https://nixos.wiki/wiki/Quassel
  services.quassel = {
    enable = true;
    interfaces = [ "0.0.0.0" ];
  };

  networking.firewall.allowedTCPPorts = [ 4242 ];

}

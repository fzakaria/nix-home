{ config, pkgs, ... }: {
  # Add quassel to the acme group
  users.groups.acme.members = [ "quassel" ];
  # Quassel IRC is a modern, cross-platform, distributed IRC client.
  # https://nixos.wiki/wiki/Quassel
  services.quassel = {
    enable = true;
    requireSSL = true;
    certificateFile =
      "${security.acme.certs."altaria.fzakaria.com".directory}/full.pem";
    interfaces = [ "0.0.0.0" ];
  };

  networking.firewall.allowedTCPPorts = [ 4242 ];

}

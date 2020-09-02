{ config, pkgs, ... }: {

  # We will run quassel behind Nginx
  # https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
  security.acme.acceptTerms = true;
  security.acme.email = "acme+farid.m.zakaria@gmail.com";
  services.nginx = {
    enable = true;
    virtualHosts = {
      "altaria.fzakaria.com" = {
        forceSSL = true;
        enableACME = true;
        # All serverAliases will be added as extra domains on the certificate.
        serverAliases = [ "bar.example.com" ];
        locations."/" = { root = "/var/www"; };
      };
    };
  };
  # Quassel IRC is a modern, cross-platform, distributed IRC client.
  # https://nixos.wiki/wiki/Quassel
  services.quassel = {
    enable = true;
    interfaces = [ "0.0.0.0" ];
  };

  networking.firewall.allowedTCPPorts = [ 4242 ];

}

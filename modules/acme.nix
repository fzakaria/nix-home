{ config, pkgs, ... }: {

  # We will setup HTTP authentication to receive our ACME (Let's encrypt) certificate
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

}

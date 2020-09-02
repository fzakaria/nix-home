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
        locations."/" = { root = "/var/www"; };
      };
    };
  };

  # Set the group to acme and that anyone in the group can read the keys
  users.groups = [ "acme" ];
  security.acme.certs."altaria.fzakaria.com".allowKeysForGroup = true;
  security.acme.certs."altaria.fzakaria.com".group = "acme";
}

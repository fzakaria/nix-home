{config, ...}: {
  # We will setup HTTP authentication to receive our ACME (Let's encrypt) certificate
  # https://nixos.org/manual/nixos/stable/#module-security-acme-nginx
  security = {
    acme = {
      acceptTerms = true;
      defaults.email = "farid.m.zakaria+acme@gmail.com";
      certs."altaria.fzakaria.com".group = config.users.groups.acme.name;
    };
  };
  services.nginx = {
    enable = true;
    # best practices
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    virtualHosts = {
      "altaria.fzakaria.com" = {
        forceSSL = true;
        enableACME = true;
        # for now just return HTTP 302 which is moved temporarily
        locations."/" = {return = "302 https://fzakaria.com";};
      };
    };
  };
  networking.firewall.allowedTCPPorts = [80 443];
  # Set the group to acme and that anyone in the group can read the keys
  users.groups.acme = {
    members = [
      # You could also do users.nginx.extraGroups also
      config.services.nginx.user
    ];
  };
}

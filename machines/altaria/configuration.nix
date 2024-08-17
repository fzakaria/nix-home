{
  config,
  pkgs,
  lib,
  outputs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./acme.nix
    ./quassel.nix
    ../../modules/nixpkgs.nix
    ../../modules/nix.nix
    ../../users
    inputs.agenix.nixosModules.default
    outputs.nixosModules.vpn
  ];

  networking = {
    hostName = "altaria";
    domain = "fzakaria.com";
  };

  services = {
    # Enable the tailscale VPN
    vpn.enable = true;

    openssh = {
      enable = true;
      startWhenNeeded = true;
      banner = ''
        Welcome to my EC2 instance. Happy hacking!
      '';
      settings = {
        PasswordAuthentication = false;
      };
    };
  };

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11";
}

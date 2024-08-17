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
    inputs.agenix.nixosModules.default
    outputs.nixosModules.vpn
  ];

  networking = {
    hostName = "altaria";
    domain = "fzakaria.com";
  };

  # testing lametun
  networking.firewall.allowedUDPPorts = [1234];

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11";
}

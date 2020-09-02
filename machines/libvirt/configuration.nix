{ config, pkgs, ... }:
let nixpkgs = (import ../../nix/sources.nix).nixos;
in {
  imports = [
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
    ../../modules/users.nix
  ];

  # As this is just for testing; we don't need a password
  # to login as any user
  users.extraUsers.root.password = "";
  users.extraUsers.fmzakari.password = "";
}

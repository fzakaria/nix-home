{ config, pkgs, lib, ... }:

with pkgs;
with lib.strings; {
  imports = [
    ../../modules/common.nix
    ../../modules/platforms/linux.nix
    ../../users/fmzakari
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Place packages here that you would like only on this laptop
  home.packages = with pkgs; [ quasselClient ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  # This must match the users.users module value
  home.username = "fmzakari";
  # https://github.com/rycee/home-manager/issues/1471
  home.homeDirectory = "/home/fmzakari";
  home.email = "fmzakari@google.com";

  home.file = {
    ".ssh/config" = {
      source = ./ssh/config;
      target = ".ssh/config";
    };
  };

}

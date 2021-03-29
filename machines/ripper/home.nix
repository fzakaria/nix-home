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
  home.packages = with pkgs; [
    # I want the NixOS manpages even when not on nixos
    ((import <nixpkgs/nixos> {
      configuration = { };
    }).config.system.build.manual.manpages)
    # I want NixOS tooling even when not on NixOS
    (nixos { }).nixos-rebuild
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  # This must match the users.users module value
  home.username = "fzakaria";
  # https://github.com/rycee/home-manager/issues/1471
  home.homeDirectory = "/home/fzakaria";
  home.email = "farid.m.zakaria@gmail.com";

}

{
  config,
  pkgs,
  lib,
  ...
}: {

  imports = [
    ../fmzakari
  ];

  home.username = lib.mkForce "fzakaria";
  home.homeDirectory = lib.mkForce "/Users/fzakaria";
  programs.git.userEmail = lib.mkForce "fzakaria@confluent.io";
}

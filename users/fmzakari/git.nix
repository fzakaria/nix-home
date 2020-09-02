{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    ignores = [ "*~" "*.swp" "*.orig" ];
    userEmail = "farid.m.zakaria@gmail.com";
  };
}

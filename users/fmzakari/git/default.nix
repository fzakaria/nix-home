{ config, pkgs, ... }: {
  home.packages = with pkgs; [ git gitAndTools.delta ];

  home.file = {
    ".gitconfig" = {
      source = pkgs.substituteAll {
        src = ./gitconfig;
        email = "${config.home.email}";
      };
      target = ".gitconfig";
    };
    ".gitignore_global" = {
      source = ./gitignore_global;
      target = ".gitignore_global";
    };
  };
}

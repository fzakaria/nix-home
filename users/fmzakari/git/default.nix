{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [ git ];

  home.file = {
    ".gitconfig" = {
      source = pkgs.substituteAll {
        src = ./gitconfig;
        email = "${lib.traceVal config.home.email}";
      };
      target = ".gitconfig";
    };
    ".gitignore_global" = {
      source = ./gitignore_global;
      target = ".gitignore_global";
    };
  };
}

{ config, pkgs, ... }: {
  home.packages = with pkgs;
    [
      # Collect your thoughts and notes without leaving the command line.
      # https://github.com/jrnl-org/jrnl
      jrnl
    ];

  home.file = {
    ".jrnl_config" = {
      source = ./jrnl_config;
      target = ".jrnl_config";
    };
  };
}

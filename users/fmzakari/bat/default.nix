{ config, pkgs, ... }: {
  home.packages = with pkgs;
    [
      # A cat clone written in rust
      # https://github.com/sharkdp/bat
      bat
    ];

  home.sessionVariables = { BAT_CONFIG_PATH = "~/.batrc"; };

  home.file = {
    ".batrc" = {
      source = ./batrc;
      target = ".batrc";
    };
  };
}

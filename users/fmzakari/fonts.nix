{ config, pkgs, ... }: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [ vistafonts source-code-pro ];
}

{ config, pkgs, ... }: {
  targets.genericLinux.enable = false;

  # Place packages here that are
  home.packages = with pkgs; [ ];
}

{ config, pkgs, ... }: {

  targets.genericLinux.enable = true;

  # Place packages here that are
  home.packages = with pkgs; [ ];
}

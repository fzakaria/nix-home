{ config, pkgs, ... }:
let ohmytmux = (import ../../../nix/sources.nix).ohmytmux;
in {
  home.packages = with pkgs; [ tmux ];

  home.file = {
    ".tmux.conf" = {
      source = ohmytmux + "/.tmux.conf";
      target = ".tmux.conf";
    };
    ".tmux.conf.local" = {
      source = ./tmux.conf.local;
      target = ".tmux.conf.local";
    };
  };
}

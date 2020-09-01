{ config, pkgs, ... }: {
  # Place packages here that are
  home.packages = with pkgs; [
    # Rust CLI Tools! I love rust.
    exa
    fd
    fzf
    ripgrep
    bat
    comma
    nix-index
    nix-diff
    # https://github.com/zimbatm/h
    h
    autojump
    # fonts
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
    dejavu_fonts
    powerline-fonts
    teleconsole
    cachix
    jrnl
    asciinema
    redo-apenwarr
    jq
    htop
    tmux
    nixfmt
    gitAndTools.delta
    gitAndTools.gitFull
  ];
}

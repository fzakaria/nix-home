# Place common home-manager setup here
{ config, pkgs, ... }: {

  imports = [ ./git.nix ./zsh.nix];

  # Place packages here that are
  home.packages = with pkgs; [
    # A modern version of ls written in rust
    # https://github.com/ogham/exa
    exa
    # A simple, fast and user-friendly alternative to 'find'
    # https://github.com/sharkdp/fd
    fd
    # A command-line fuzzy finder
    # https://github.com/junegunn/fzf
    fzf
    # ripgrep recursively searches directories for a regex pattern
    # https://github.com/BurntSushi/ripgrep
    ripgrep
    # A cat clone written in rust
    # https://github.com/sharkdp/bat
    bat
    comma
    # Quickly locate nix packages with specific files
    # https://github.com/bennofs/nix-index
    nix-index
    nix-diff
    # faster shell navigation of projects
    # https://github.com/zimbatm/h
    h
    # A cd command that learns - easily navigate directories from the command line
    # https://github.com/wting/autojump
    autojump
    # Command line tool to share your UNIX terminal and forward local TCP ports to people you trust.
    # https://github.com/gravitational/teleconsole
    teleconsole
    cachix
    # Collect your thoughts and notes without leaving the command line.
    # https://github.com/jrnl-org/jrnl
    jrnl
    # Terminal session recorder
    # https://github.com/asciinema/asciinema
    asciinema
    redo-apenwarr
    # Command-line JSON processor
    # https://github.com/stedolan/jq
    jq
    # htop is an interactive text-mode process viewe
    # https://github.com/hishamhm/htop
    htop
    tmux
    # A formatter for Nix code
    # https://github.com/serokell/nixfmt
    nixfmt
  ];
}

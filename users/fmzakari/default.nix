# Place common home-manager setup here
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./git.nix
    ./zsh
    inputs.h.homeModules.default
  ];

  home = {
    username = "fmzakari";
    homeDirectory = "/home/fmzakari";
  };

  # List of additional package outputs of the packages home.packages
  # that should be installed into the user environment.
  home.extraOutputsToInstall = ["man" "doc" "info" "devdoc"];
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  home.sessionVariables = {
    LESS = "--quit-if-one-screen --RAW-CONTROL-CHARS";
    EDITOR = "vim";
    # TODO(fmzakari): I might want this if I use home-manager on Linux non-NixOS
    # https://nixos.org/manual/nixpkgs/stable/#locales
    # LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };

  # Place packages here that are
  home.packages = with pkgs; [
    # a tool to help review other nixpkgs PR requests
    nixpkgs-review
    # age is a simple, modern and secure file encryption tool, format, and library.
    # https://github.com/FiloSottile/age
    age
    # A modern version of ls written in rust
    # https://github.com/eza-community/eza
    eza
    # A simple, fast and user-friendly alternative to 'find'
    # https://github.com/sharkdp/fd
    fd
    # ripgrep recursively searches directories for a regex pattern
    # https://github.com/BurntSushi/ripgrep
    ripgrep
    # Quickly locate nix packages with specific files
    # https://github.com/bennofs/nix-index
    # TODO(fzakaria): We bring it in with nix-index-database as a NixOS module
    # nix-index
    # Command line tool to share your UNIX terminal and forward local TCP ports to people you trust.
    # https://github.com/gravitational/teleconsole
    # archived by upstream
    #teleconsole
    cachix
    # Terminal session recorder
    # https://github.com/asciinema/asciinema
    asciinema
    # Command-line JSON processor
    # https://github.com/stedolan/jq
    jq
    # htop is an interactive text-mode process viewe
    # https://github.com/hishamhm/htop
    htop
    # A formatter for Nix code
    # https://github.com/kamadorueda/alejandra
    alejandra

    niv

    buildifier

    just

    arcanist
  ];

  programs = {
    # Let Home Manager install and manage itself.
    home-manager = {
      enable = true;
    };
    # https://github.com/zimbatm/h
    # Faster code checkout
    h = {
      codeRoot = "~/code";
    };
    # A cd command that learns - easily navigate directories from the command line
    # https://github.com/wting/autojump
    autojump = {
      enable = true;
    };
    # A command-line fuzzy finder
    # https://github.com/junegunn/fzf
    fzf = {
      enable = true;
      changeDirWidgetCommand = "fd --color always --hidden --follow --exclude .git --type d";
      changeDirWidgetOptions = ["--ansi --preview 'exa --color always --tree {} | head -500'"];
      fileWidgetCommand = "fd --color always --type f --hidden --follow --exclude .git";
      fileWidgetOptions = [
        "--ansi --preview-window=right:60% --preview 'bat --style=plain --color=always --line-range :500 {}'"
      ];
    };

    bat = {
      enable = true;
      config = {
      };
    };

    direnv = {
      enable = true;
      config = {
      };
      nix-direnv.enable = true;
    };

    ssh = {
      enable = true;
      forwardAgent = true;
      # TODO(fzakaria): Doesn't exist in 23.05 nixos release
      # addKeysToAgent = "confirm";
      serverAliveInterval = 0;
      controlMaster = "auto";
      controlPersist = "60m";
    };
  };
}

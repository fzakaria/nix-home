# Place common home-manager setup here
{ config, pkgs, lib, ... }:
with lib; {

  imports = [
    ./git
    ./zsh
    ./broot.nix
    ./direnv.nix
    ./fzf.nix
    ./tmux
    ./bat
    ./jrnl
    ./fonts.nix
  ];

  options.home.email = mkOption {
    type = types.str;
    default = "farid.m.zakaria@gmail.com";
    description = "The email to associate primarily with my user.";
  };

  config = {
    # List of additional package outputs of the packages home.packages
    # that should be installed into the user environment.
    home.extraOutputsToInstall = [ "man" "doc" "info" "devdoc" ];
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
      # https://nixos.org/manual/nixpkgs/stable/#locales
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    };

    # Place packages here that are
    home.packages = with pkgs; [
      # a tool to help review other nixpkgs PR requests
      nixpkgs-review
      # age is a simple, modern and secure file encryption tool, format, and library.
      # https://github.com/FiloSottile/age
      age
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
      # A formatter for Nix code
      # https://github.com/serokell/nixfmt
      nixfmt
    ];

  };
}

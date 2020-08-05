{ config, pkgs, lib, ... }:

with pkgs;
with lib.strings;
let
  variables = import ./variables.nix;
  spacevim = fetchFromGitHub {
    owner = "SpaceVim";
    repo = "SpaceVim";
    rev = "280b0b9b9b909c0f311e3e2bfbd24ebff4535acf";
    sha256 = "1nnnb6q7p2jziq96vdrb2iyl6wfh2qkrdhx8fx89w0lw7b5dkh69";
  };
in {
  imports = if (hasInfix builtins.currentSystem "linux") then
    [ ./platforms/linux.nix ]
  else if (hasInfix builtins.currentSystem "darwin") then
    [ ./platforms/darwin.nix ]
  else
    [ ];

  nixpkgs.overlays = [ (import ./overlay) ];
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

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

    # spacevim
    (neovim.override {
      withPython3 = true;
      vimAlias = true;
      viAlias = true;
    })
    ctags
    solargraph
    nodePackages.javascript-typescript-langserver
    nodePackages.typescript-language-server
    # fonts
    (nerdfonts.override { fonts = [ "SourceCodePro" ]; })
    dejavu_fonts
    powerline-fonts

    teleconsole
    discord
    cachix
    jrnl
    asciinema
    ruby
    redo-apenwarr
    jq
    htop
    tmux
    nixfmt
    gitAndTools.delta
    gitAndTools.gitFull
  ];

  # otherwise typing `man` shows
  # > ~/.nix-profile/bin/man: can't set the locale; make sure $LC_* and $LANG are correct
  # https://github.com/rycee/home-manager/issues/432
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];
  home.sessionVariables = {
    BAT_CONFIG_PATH = "~/.batrc";
    LESS = "--quit-if-one-screen --RAW-CONTROL-CHARS";
    EDITOR = "vim";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNixDirenvIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    history = {
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
    plugins = [
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "0.7.1";
          sha256 = "03r6hpb5fy4yaakqm3lbf4xcvd408r44jgpv4lnzl9asp4sb9qc0";
        };
      }
      {
        name = "powerlevel10k";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "powerlevel10k";
          rev = "v1.11.0";
          sha256 = "1z6abvp642n40biya88n86ff1wiry00dlwawqwxp7q5ds55jhbv1";
        };
        file = "powerlevel10k.zsh-theme";
      }
    ];
    initExtraBeforeCompInit = builtins.readFile ./programs/zsh/zshrc;

    initExtra = ''
      # Figure out the closure size for a certain package
      # ex. nix-closure-size $(which exa)
      nix-closure-size() {
        nix-store -q --size $(nix-store -qR $(readlink -e $1) ) | \
        awk '{ a+=$1 } END { print a }' | \
        ${pkgs.coreutils}/bin/numfmt --to=iec-i
      }
    '';

    shellAliases = {
      "cat" = "bat --style=plain";
      "l" = "exa";
      "la" = "exa -a";
      "ll" = "exa -lah";
      "ls" = "exa --color=auto";
      "pbcopy" = "xsel --clipboard --input";
      "idea"= "/opt/intellij-ue-stable/bin/idea.sh \"$@\" >/dev/null 2>&1";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "ssh-agent" "rake" ];
    };
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    changeDirWidgetCommand =
      "fd --color always --hidden --follow --exclude .git --type d";
    changeDirWidgetOptions =
      [ "--ansi --preview 'exa --color always --tree {} | head -500'" ];
    fileWidgetCommand =
      "fd --color always --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--ansi --preview-window=right:60% --preview 'bat --style=plain --color=always --line-range :500 {}'"
    ];
  };

  # Whether to enable fontconfig configuration.
  # This will, for example, allow fontconfig to discover fonts and
  # configurations installed through home.packages
  fonts.fontconfig.enable = true;

  home.file = {
    ".SpaceVim.d/init.toml" = {
      source = ./programs/spacevim/init.toml;
      target = ".SpaceVim.d/init.toml";
      onChange = "rm -rf ~/.cache/SpaceVim/conf";
    };
    ".config/nvim" = {
      source = spacevim;
      recursive = true;
    };
    ".tmux.conf" = {
      source = ./programs/tmux/ohmytmux/.tmux.conf;
      target = ".tmux.conf";
    };
    ".tmux.conf.local" = {
      source = ./programs/tmux/ohmytmux/.tmux.conf.local;
      target = ".tmux.conf.local";
    };
    ".gitconfig" = {
      source = pkgs.substituteAll {
        src = ./programs/git/gitconfig;
        full_name = "${variables.full_name}";
        email = "${variables.email}";
      };
      target = ".gitconfig";
    };
    ".gitignore_global" = {
      source = ./programs/git/gitignore_global;
      target = ".gitignore_global";
    };
    ".ssh/config" = {
      source = ./programs/ssh/config;
      target = ".ssh/config";
    };
    ".p10k.zsh" = {
      source = ./programs/zsh/p10k.zsh;
      target = ".p10k.zsh";
    };
    ".batrc" = {
      source = ./programs/bat/batrc;
      target = ".batrc";
    };
    ".jrnl_config" = {
      source = ./programs/jrnl/jrnl_config;
      target = ".jrnl_config";
    };
  };

}

{ config, pkgs, lib, ... }:

let variables = import ./variables.nix;                                                                                                                                               
in {
  imports = if builtins.currentSystem == "x86_64-linux"
  then [ ./platforms/linux.nix ]
  else if builtins.currentSystem == "x86_64-darwin"
  then [./platforms/darwin.nix]
  else [];

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

    redo-apenwarr
    jq
    htop
    tmux
    nixfmt
    gitAndTools.delta
    gitAndTools.gitFull
    (callPackage ./programs/ruby/rbenv.nix { })
    (callPackage ./programs/ruby/ruby-build.nix { })
    (callPackage ./programs/node/nodenv.nix { })
    (callPackage ./programs/node/node-build.nix { })
  ];

  # otherwise typing `man` shows
  # > /home/fmzakari/.nix-profile/bin/man: can't set the locale; make sure $LC_* and $LANG are correct
  # https://github.com/rycee/home-manager/issues/432
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];
  home.sessionVariables = { BAT_CONFIG_PATH = "~/.batrc"; };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.6.4";
          sha256 = "0h52p2waggzfshvy1wvhj4hf06fmzd44bv6j18k3l9rcx6aixzn6";
        };
      }
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
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "ssh-agent" "rake" ];
    };
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

  home.file = {
    ".tmux.conf" = {
      source = ./programs/tmux/ohmytmux/.tmux.conf;
      target = ".tmux.conf";
    };
    ".tmux.conf.local" = {
      source = ./programs/tmux/ohmytmux/.tmux.conf.local;
      target = ".tmux.conf.local";
    };
    ".vim_runtime" = {
      source = ./programs/vim/vim_runtime;
      target = ".vim_runtime";
    };
    ".vimrc" = {
      source = ./programs/vim/vimrc;
      target = ".vimrc";
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
  };

}

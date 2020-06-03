{ config, pkgs, lib, ... }:

let 
  variables = import ./variables.nix;
in {
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
    tmux
    (callPackage ./programs/ruby/rbenv.nix {})
    (callPackage ./programs/ruby/ruby-build.nix {})
  ]; 

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
    initExtra = 
      ''
         # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
         [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

         # FIXME: SSH or tooling that requires libnss-cache (https://github.com/google/libnss-cache)
         # seems to fail since the library is not present. When I have a better understanding of Nix
         # let's fix this.
         [[ ! -f /lib/x86_64-linux-gnu/libnss_cache.so.2 ]] || export LD_PRELOAD=/lib/x86_64-linux-gnu/libnss_cache.so.2:$LD_PRELOAD

         # Allow rbenv to function by adding the shims
         eval "$(rbenv init -)"
      '';
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "ssh-agent" "rake"];
    };
  };

  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = variables.username;
    userEmail = variables.email;
    aliases = {
      # List available aliases
      aliases = "!git config --get-regexp alias | sed -re 's/alias\\.(\\S*)\\s(.*)$/\\1 = \\2/g'";
      # get a diff not fancy!
      patch = "!git --no-pager diff --no-color";
      # Command shortcuts
      co = "checkout";
      st = "status";
      ci = "commit";
      br = "branch";
      # Display tree-like log, because default log is a pain…
      lg = "log --graph --date=relative --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ad)%Creset'";
      # Useful when you have to update your last commit
      # with staged files without editing the commit message.
      oops = "commit --amend --no-edit";
      # Edit last commit message
      reword = "commit --amend";
      # Undo last commit but keep changed files in stage
      uncommit = "reset --soft HEAD~1";
      # Remove file(s) from Git but not from disk
      untrack = "rm --cache --";
      # Print recent branches used
      brv = "branch --sort=-committerdate -vvv";
    };
    extraConfig = {
      http = {
        cookiefile = "~/.gitcookies";
      };
      color = {
        ui = "auto";
      };
      core = {
        editor = "vim";
        # Don't consider trailing space change as a cause for merge conflicts
        whitespace = "-trailing-space";
      };
      status = {
        # Display submodule rev change summaries in status
        submoduleSummary = true;
        # Recursively traverse untracked directories to display all contents
        showUntrackedFiles = "all";
      };
      diff = {
        tool = "bc3";
      };
      "difftool \"bc3\"" = {
        trustExitCode = true;
      };
      difftool = {
        prompt = false;
      };
      merge = {
        tool = "bc3";
      };
      "mergetool \"bc3\"" = {
        trustExitCode = true;
      };
    };
    delta = {
      enable = true;
      options = ["--dark"];
    };
    ignores = ["*~" "*.swp" "*.orig"];
  };

  programs.bat = {
    enable = true;
    config = { 
      pager = "less -FR";
      theme = "TwoDark"; 
    };
  };

  programs.htop = {
    enable = true;
  };

  programs.jq = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };

  programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPersist = "60m";
    extraConfig = ''
      Host cloudtop
        Hostname ${variables.username}.c.googlers.com
    '';
    forwardAgent = true;
  };

  home.file.".p10k.zsh".text = builtins.readFile ./programs/zsh/p10k.zsh;
}

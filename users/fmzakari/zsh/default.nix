{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = false;
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
          rev = "v1.19.0";
          sha256 = "sha256-+hzjSbbrXr0w1rGHm6m2oZ6pfmD6UUDBfPd7uMg5l5c=";
        };
        file = "powerlevel10k.zsh-theme";
      }
    ];
    initExtraBeforeCompInit = builtins.readFile ./zshrc;

    initExtra = ''
      # Figure out the closure size for a certain package
      # ex. nix-closure-size $(which exa)
      nix-closure-size() {
        nix-store -q --size $(nix-store -qR $(readlink -e $1) ) | \
        awk '{ a+=$1 } END { print a }' | \
        ${pkgs.coreutils}/bin/numfmt --to=iec-i
      }
      # setup autojump
      . ${pkgs.autojump}/share/autojump/autojump.zsh

      # https://github.com/zimbatm/h
      # setup h
      eval "$(${pkgs.h}/bin/h --setup ~/code)"
    '';

    shellAliases = {
      "cat" = "bat --style=plain";
      "l" = "exa";
      "la" = "exa -a";
      "ll" = "exa -lah";
      "ls" = "exa --color=auto";
      "pbcopy" = "xsel --clipboard --input";
      "idea" = ''/opt/intellij-ue-stable/bin/idea.sh "$@" >/dev/null 2>&1'';
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "ssh-agent" "rake" ];
      extraConfig = ''
        zstyle :omz:plugins:ssh-agent agent-forwarding on
      '';
    };
  };

  home.file = {
    ".p10k.zsh" = {
      source = ./p10k.zsh;
      target = ".p10k.zsh";
    };
  };

}

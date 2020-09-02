{ config, pkgs, ... }: {
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
    };
  };

  home.file = {
    ".p10k.zsh" = {
      source = ./p10k.zsh;
      target = ".p10k.zsh";
    };
  };

}

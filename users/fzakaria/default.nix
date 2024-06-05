{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../fmzakari
    ../fmzakari/zsh
  ];

  home = {
    username = lib.mkForce "fzakaria";
    homeDirectory = lib.mkForce "/Users/fzakaria";
  };

  home.packages = with pkgs; [
  ];

  programs = {
    zsh = {
      enable = lib.mkForce true;
      initExtraFirst = ''
        source ~/code/github.com/confluentinc/cc-dotfiles/caas.sh
        #TODO(fzakaria): This should be from nixpkgs assume
        alias assume="source /opt/homebrew/bin/assume"

        export PYENV_ROOT="$HOME/.pyenv"
        [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
      '';
    };

    git.userEmail = lib.mkForce "fzakaria@confluent.io";
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
  };
}

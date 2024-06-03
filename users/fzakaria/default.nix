{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../fmzakari
  ];

  home = {
    username = lib.mkForce "fzakaria";
    homeDirectory = lib.mkForce "/Users/fzakaria";
  };

  programs = {
    zsh.enable = true;

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

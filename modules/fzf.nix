{ config, pkgs, ... }: {
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  environment.variables = {
    FZF_ALT_C_COMMAND =
      "fd --color always --hidden --follow --exclude .git --type d";
    FZF_ALT_C_OPTS =
      [ "--ansi --preview 'eza --color always --tree {} | head -500'" ];

    FZF_CTRL_T_COMMAND =
      "fd --color always --type f --hidden --follow --exclude .git";

    FZF_CTRL_T_OPTS = [
      "--ansi --preview-window=right:60% --preview 'bat --style=plain --color=always --line-range :500 {}'"
    ];
  };
}

{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;

    autocd = true;
    enableCompletion = true;
    history = {
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [];
    };
    historySubstringSearch = {
      enable = true;
    };
    enableAutosuggestions = true;
    sessionVariables = {
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [];
    };

    initExtra = builtins.readFile ./zshrc;

    shellAliases = {
      "cat" = "bat --style=plain";
      "pbcopy" = "xsel --clipboard --input";
    };
  };
}

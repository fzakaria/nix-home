{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    autocd = true;
    history = {
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
    syntaxHighlighting.enable = true;
    plugins = [
    ];

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
      "pbcopy" = "xsel --clipboard --input";
    };
  };

}

{ config, pkgs, ... }: {

  programs.zsh = {
    enable = true;

    shellAliases = {

    };

    setOptions = lib.mkForce [
      "auto_cd"
      "auto_pushd"
      "beep"
      "correct"
      "dvorak"
      "extended_glob"
      "extended_history"
      "hist_fcntl_lock"
      "hist_ignore_dups"
      "hist_no_store"
      "hist_reduce_blanks"
      "interactive_comments"
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

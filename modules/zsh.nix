{ config, pkgs, ... }: {

  programs.zsh = {
    enable = true;

    # Enable zsh completion for all interactive zsh shells.
    enableCompletion = true;
    # Enable compatibility with bash's programmable completion system.
    enableBashCompletion = true;
    # Enable extra colors in directory listings (used by `ls` and `tree`).
    enableLsColors = true;

    # zsh-autosuggestions
    autosuggestions.enable = true;
    # zsh-syntax-highlighting.
    syntaxHighlighting.enable = true;

    # See all options at https://zsh.sourceforge.io/Doc/Release/Options.html
    setOptions = [
      # Change directory even if user forgot to put 'cd' command in front, but entered path is valid
      "auto_cd"
      # Make cd push the old directory onto the directory stack.
      "auto_pushd"
      # Beep on error.
      "beep"
      # Try to correct the spelling of commands.
      "correct"
      # Enable extended globs to interpret things like rm ^(file|file2)
      "extended_glob"
      # Use OS file locking
      "hist_fcntl_lock"
      # Remove the history (fc -l) command from the history list when invoked.
      "hist_no_store"
      # Remove superfluous blanks from each command line being added to the history list.
      "hist_reduce_blanks"
      # Allow comments even in interactive shells.
      "interactive_comments"
      # imports new commands from the history file
      # commands to be appended to the history file
      "share_history"
      # Report the status of background jobs immediately, rather than waiting until just before printing a prompt
      "notify"
      # Don't save any commands beginning with space
      "hist_ignore_space"
      # When searching for history entries in the line editor, do not display duplicates of a line
      # previously found, even if the duplicates are not contiguo
      "hist_find_no_dups"
    ];

    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';

    shellInit = ''
      # Stop new-user prompting if there is no zshrc in the user directory
      zsh-newuser-install () {}

      # Figure out the closure size for a certain package
      # ex. nix-closure-size $(which exa)
      nix-closure-size() {
        nix-store -q --size $(nix-store -qR $(readlink -e $1) ) | \
        awk '{ a+=$1 } END { print a }' | \
        ${pkgs.coreutils}/bin/numfmt --to=iec-i
      }

      # Got this sweet function from HackerNews
      function frg {
          result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
            fzf --ansi \
                --color 'hl:-1:underline,hl+:-1:underline:reverse' \
                --delimiter ':' \
                --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
          file=''${result%%:*}
          linenumber=$(echo "''${result}" | cut -d: -f2)
          if [[ -n "$file" ]]; then
                  $EDITOR +"''${linenumber}" "$file"
          fi
        }

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

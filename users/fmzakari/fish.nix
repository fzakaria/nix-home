{
  config,
  pkgs,
  ...
}: {
  programs.fish = {
    enable = true;

    shellAliases = {
    };

    functions = {
      # disable welcome message
      fish_greeting = "";
      nix-closure-size = {
        body = ''
          nix path-info --recursive --size --closure-size \
                        --human-readable $(readlink -f $(which $program))
        '';
        argumentNames = ["program"];
      };
      # Got this sweet function from HackerNews
      frg = ''
            set result (rg --ignore-case --color=always --line-number --no-heading "$argv" |
            fzf --ansi \
                --color 'hl:-1:underline,hl+:-1:underline:reverse' \
                --delimiter ':' \
                --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
        set file (echo $result | cut -d: -f1)
        set linenumber (echo $result | cut -d: -f2)
        if test -n "$file"
            $EDITOR +"$linenumber" "$file"
        end
      '';
    };

    shellInit = ''
      tide configure --auto --style=Lean --prompt_colors='True color' \
                     --show_time='24-hour format' --lean_prompt_height='Two lines' \
                     --prompt_connection=Disconnected --prompt_spacing=Sparse \
                     --icons='Many icons' --transient=Yes
      fzf_configure_bindings --directory=\cf --processes=\cp --git_log=\cl

      set fzf_diff_highlighter delta --paging=never --width=20
    '';
  };

  home.packages = with pkgs.fishPlugins; [
    fzf-fish
    done
    tide
  ];
}

{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;

    shellAliases = {
    };

    functions = {
      # to avoid going into a loop from bash -> fish -> bash
      # set the environment variable which stops that.
      bash = {
        body = ''
          NO_FISH_BASH="1" command bash $argv
        '';
        wraps = "bash";
      };

      # disable welcome message
      fish_greeting = "fish_prompt";
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

    interactiveShellInit = ''
      set -U fish_greeting
      fish_config theme choose "Dracula"
      set __fish_git_prompt_showcolorhints 1
    '';
  };

  home.packages = with pkgs.fishPlugins; [
  ];
}

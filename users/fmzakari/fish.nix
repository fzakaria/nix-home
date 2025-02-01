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

      # Based on https://gist.github.com/hroi/d0dc0e95221af858ee129fd66251897e
      fish_jj_prompt = ''
        # Is jj installed?
        if not command -sq jj
            return 1
        end

        # Are we in a jj repo?
        if not jj root --quiet &>/dev/null
            return 1
        end

        # Generate prompt
            jj log --ignore-working-copy --no-graph --color always -r @ -T '
        surround(
            " (",
            ")",
            separate(
                " ",
                bookmarks.join(", "),
                coalesce(
                    surround(
                        "\"",
                        "\"",
                        if(
                            description.first_line().substr(0, 24).starts_with(description.first_line()),
                            description.first_line().substr(0, 24),
                            description.first_line().substr(0, 23) ++ "…"
                        )
                    ),
                    "(no description set)"
                ),
                change_id.shortest(),
                commit_id.shortest(),
                if(conflict, "(conflict)"),
                if(empty, "(empty)"),
                if(divergent, "(divergent)"),
                if(hidden, "(hidden)"),
            )
        )
        '
      '';

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

      fish_vcs_prompt = ''
        fish_jj_prompt $argv
        or fish_git_prompt $argv
        or fish_hg_prompt $argv
        or fish_fossil_prompt $argv
        # The svn prompt is disabled by default because it's quite slow on common svn repositories.
        # To enable it uncomment it.
        # You can also only use it in specific directories by checking $PWD.
        # or fish_svn_prompt
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

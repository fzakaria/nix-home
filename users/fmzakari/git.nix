{pkgs, ...}: {
  programs.git = {
    enable = true;
    # Track git from unstable for the latest features/fixes.
    package = pkgs.unstable.git;

    settings = {
      user = {
        name = "Farid Zakaria";
        email = "farid.m.zakaria@gmail.com";
      };

      alias = {
        # List available aliases
        aliases = "!git config --get-regexp alias | sed -re 's/alias\\.(\\S*)\\s(.*)$/\\1 = \\2/g'";
        # get a diff not fancy!
        patch = "!git --no-pager diff --no-color";
        co = "checkout";
        st = "status";
        ci = "commit";
        br = "branch";
        # One-line graph log: colored per field + relative age. Also the
        # shallow-clone fallback for `git sl` below.
        lg = "log --graph --date=relative --pretty=tformat:'%C(bold yellow)%h%Creset %C(auto)%d%Creset %s %C(dim white)- %an%Creset %C(bold green)(%ar)%Creset'";
        # Smart log: full clone -> git-graph (branch-column layout); shallow clone
        # (git-graph can't read those) -> fall back to `git lg`.
        sl = "!f() { if [ \"$(git rev-parse --is-shallow-repository 2>/dev/null)\" = \"true\" ]; then git lg \"$@\"; else git-graph --format '%h%d %s (%an, %as)' \"$@\"; fi; }; f";
        # Useful when you have to update your last commit
        # with staged files without editing the commit message.
        oops = "commit --amend --no-edit";
        # Edit last commit message
        reword = "commit --amend";
        # Undo last commit but keep changed files in stage
        uncommit = "reset --soft HEAD~1";
        # Remove file(s) from Git but not from disk
        untrack = "rm --cache --";
        # Print recent branches used
        brv = "branch --sort=-committerdate -vvv";
      };

      color = {
        # # Enable colors in color-supporting terminals
        ui = "auto";
      };
      core = {
        # Don't consider trailing space change as a cause for merge conflicts
        whitespace = "-trailing-space";
        editor = "vim";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        # this is the safest option. if you want to merge do so explicitly.
        ff = "only";
      };
      diff = {
        tool = "bc";
      };
      difftool = {
        prompt = false;
        bc = {
          trustExitCode = true;
        };
      };
      merge = {
        tool = "bc";
      };
      mergetool = {
        prompt = false;
        bc = {
          keepBackup = false;
          trustExitCode = true;
        };
      };
    };

    ignores = [
      "*~"
      "*.swp"
      "*.orig"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      syntax-theme = "Dracula";
    };
  };
}

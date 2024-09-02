{config, ...}: {
  programs.git = {
    enable = true;

    userName = "Farid Zakaria";
    userEmail = "farid.m.zakaria@gmail.com";
    aliases = {
      # List available aliases
      aliases = "!git config --get-regexp alias | sed -re 's/alias\\.(\\S*)\\s(.*)$/\\1 = \\2/g'";
      # get a diff not fancy!
      patch = "!git --no-pager diff --no-color";
      co = "checkout";
      st = "status";
      ci = "commit";
      br = "branch";
      # Display tree-like log, because default log is a pain…
      lg = "log --graph --date=relative --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ad)%Creset'";
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

    delta = {
      enable = true;
      options = {
        syntax-theme = "Dracula";
      };
    };

    ignores = [
      "*~"
      "*.swp"
      "*.orig"
    ];

    extraConfig = {
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
      merge = {
        tool = "smerge";
      };
      mergetool = {
        smerge.cmd = "smerge mergetool \"$BASE\" \"$LOCAL\" \"$REMOTE\" -o \"$MERGED\"";
        keepBackup = false;
        trustExitCode = true;
      };
    };
  };
}

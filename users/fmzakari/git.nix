{config, ...}: {
  programs.git = {
    enable = true;

    userName = "Farid Zakaria";
    userEmail = "farid.m.zakaria@gmail.com";
    aliases = {
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
  };
}

{ config, pkgs, ... }: {

  # users.mutableUsers = false;

  users.extraUsers.fmzakari = {
    # This automatically sets group to users, createHome to true,
    # home to /home/username, useDefaultShell to true, and isSystemUser to false
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    description = "Farid Zakaria";
  };

}

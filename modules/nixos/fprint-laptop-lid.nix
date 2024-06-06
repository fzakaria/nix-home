# https://unix.stackexchange.com/questions/678609/how-to-disable-fingerprint-authentication-when-laptop-lid-is-closed
# TODO(fzakaria): When I 'sudo -v' something else is turning on fprintd even when we mask it
# I should figure out another solution maybe mucking with PAM directly.
# see: https://github.com/dani0854/nixos-vidar/blob/e7522ec353d0caf3dfc6779cc577c2a61318d264/config/core/doas.nix#L20
{ config, lib, pkgs, ... }:
let cfg = config.services.fprint-laptop-lid;
    laptop-lid = pkgs.writeShellScript "laptop-lid" ''
      lock=$HOME/fprint-disabled

      # match for either display port or hdmi port
      if grep -Fq closed /proc/acpi/button/lid/LID0/state &&
         (grep -Fxq connected /sys/class/drm/card0-DP-*/status ||
          grep -Fxq connected /sys/class/drm/card0-HDMI-*/status)
      then
        touch "$lock"
        systemctl stop fprintd
        systemctl --runtime mask fprintd
      elif [ -f "$lock" ]
      then
        systemctl unmask fprintd
        systemctl start fprintd
        rm "$lock"
      fi
    '';
in {

  options.services.fprint-laptop-lid = {
      enable = lib.mkEnableOption
        (lib.mdDoc "Disable finger print reader when laptop lid is closed.");
  };

  config = lib.mkIf cfg.enable {

    services.acpid = {
      enable = true;
      lidEventCommands = "${laptop-lid}";
    };

    systemd.services.fprint-laptop-lid = {
      enable = true;
      description = "Disable fprint when laptop lid closes";
      serviceConfig = { ExecStart = laptop-lid; };
      wantedBy = [ "multi-user.target" "suspend.target" ];
      after = [ "suspend.target" ];
    };

  };
}
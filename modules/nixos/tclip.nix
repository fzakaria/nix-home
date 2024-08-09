{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.tclip;
in {
  options.services.tclip = {
    enable = mkEnableOption "Enable tclip service";

    package = mkOption {
      type = types.package;
      description = ''
        tclip package to use
      '';
      default = inputs.tailscale-tclip.packages."${pkgs.system}".tclipd;
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tclip";
      description = "Path to data dir";
    };

    hostname = mkOption {
      type = types.str;
      default = "paste";
      description = "Hostname to use on your tailnet";
    };

    funnel = mkOption {
      type = types.bool;
      default = false;
      description = "if set, expose individual pastes to the public internet with Funnel";
    };

    user = mkOption {
      type = types.str;
      default = "tclip";
      description = "User account under which tclip runs.";
    };

    group = mkOption {
      type = types.str;
      default = "tclip";
      description = "Group account under which tclip runs.";
    };

    tailscaleAuthKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing the Tailscale Auth Key";
    };

    verbose = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      inputs.tailscale-tclip.packages."${pkgs.system}".tclip
    ];

    users.users."${cfg.user}" = {
      home = cfg.dataDir;
      createHome = true;
      group = "${cfg.group}";
      isSystemUser = true;
      isNormalUser = false;
      description = "User for tclip service";
    };
    users.groups."${cfg.group}" = {};

    systemd.services.tclip = {
      enable = true;
      script = let
        args =
          [
            "--data-dir"
            cfg.dataDir
            "--hostname"
            cfg.hostname
          ]
          ++ lib.optionals cfg.verbose ["--tsnet-verbose"]
          ++ lib.optionals cfg.funnel ["--use-funnel"];
      in ''
        ${lib.optionalString (cfg.tailscaleAuthKeyFile != null) ''
          export TS_AUTHKEY="$(head -n1 ${lib.escapeShellArg cfg.tailscaleAuthKeyFile})"
        ''}
        ${cfg.package}/bin/tclipd ${builtins.concatStringsSep " " args};
      '';
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "always";
        RestartSec = "15";
        WorkingDirectory = "${cfg.dataDir}";
      };
    };
  };
}

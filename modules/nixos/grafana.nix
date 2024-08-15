{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.grafana-proxy;
in {
  options.services.grafana-proxy = {
    enable = mkEnableOption "Enable Grafana service with a Tailscale reverse proxy";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/grafana-proxy";
      description = "Path to data dir";
    };

    hostname = mkOption {
      type = types.str;
      default = "grafana";
      description = "Hostname to use for your Grafana with MagicDNS";
    };

    user = mkOption {
      type = types.str;
      default = "grafana-proxy";
      description = "User account under which grafana-proxy runs.";
    };

    group = mkOption {
      type = types.str;
      default = "grafana-proxy";
      description = "Group account under which grafana-proxy runs.";
    };

    tailscaleAuthKeyFile = mkOption {
      type = types.path;
      description = "Path to file containing the Tailscale Auth Key";
    };
  };
  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          httpAddr = "127.0.0.1";
          httpPort = 3000;
          domain = cfg.hostname;
        };

        # https://github.com/tailscale/tailscale/blob/db4247f705b9b8c7f38a5e8e4dc2795d2fef6741/cmd/proxy-to-grafana/proxy-to-grafana.go#L14
        "auth.proxy" = {
          enabled = true;
          header_name = "X-WEBAUTH-USER";
          header_property = "username";
          auto_sign_up = true;
          whitelist = "127.0.0.1";
          headers = "Name:X-WEBAUTH-NAME";
          enable_login_token = true;
        };
      };
    };

    users.users."${cfg.user}" = {
      home = cfg.dataDir;
      createHome = true;
      group = "${cfg.group}";
      isSystemUser = true;
      isNormalUser = false;
      description = "User for grafana-proxy service";
    };
    users.groups."${cfg.group}" = {};

    systemd.services.grafana-proxy = {
      enable = true;
      script = let
        args = [
          "--use-https=true"
          "--state-dir"
          cfg.dataDir
          "--hostname"
          cfg.hostname
          "--backend-addr"
          "${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}"
        ];
      in ''
        ${lib.optionalString (cfg.tailscaleAuthKeyFile != null) ''
          export TS_AUTHKEY="$(head -n1 ${lib.escapeShellArg cfg.tailscaleAuthKeyFile})"
        ''}
        ${pkgs.tailscale}/bin/proxy-to-grafana ${builtins.concatStringsSep " " args};
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

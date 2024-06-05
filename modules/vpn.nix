{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.vpn;
in {
  options.vpn = {
    # zw = [zakaria williams];
    enable = mkEnableOption "ZW Tailscale VPN";

    udpPort = mkOption {
      type = types.int;
      default = 41641;
      description = ''
        The UDP port tailscale is using.
      '';
    };

    package = mkPackageOption pkgs "tailscale" {};
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.allowedUDPPorts = [cfg.udpPort];
    environment.systemPackages = [cfg.package];
  };
}

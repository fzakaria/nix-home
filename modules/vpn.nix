{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.zw.tailscale;
in {
  # zw = [zakaria williams];
  options.services.zw.tailscale = {
    enable = mkEnableOption "ZW Tailscale";

    allowedUDPPorts = mkOption {
      type = types.int;
      default = 41641;
      description = ''        UDP ports your firewall has to allow
              for Tailscale to work.'';
    };
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.allowedUDPPorts = [cfg.allowedUDPPorts];
    environment.systemPackages = [pkgs.tailscale];
  };
}

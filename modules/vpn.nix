{ config, pkgs, ... }: {
  services.tailscale = { enable = true; };

  networking.firewall.allowedUDPPorts = [ 41641 ];

  # Disable SSH access through the firewall
  # Only way into the machine will be through
  # This may cause a chicken & egg problem since you need to register a machine
  # first using `tailscale up`
  # Better to rely on EC2 SecurityGroups
  # services.openssh.openFirewall = false;

  environment.systemPackages = [ pkgs.tailscale ];
}

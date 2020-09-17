{ config, pkgs, ... }: {

	# We use tailscale to setup our VPN across our machines
	imports = [ (nixpkgs + "/nixos/modules/services/networking/tailscale.nix") ];

}

{
  inputs,
  outputs,
  config,
  pkgs,
  ...
}: {
  nixpkgs = {
    # Add the global overlay for all machines
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      # Allow non open source software
      # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
      allowUnfree = true;
    };
  };

  # Put nixpkgs into /etc/nixpkgs for convenience
  environment.etc.nixpkgs.source = inputs.nixpkgs;
  # Point nixpath to that nixpkgs so that the system uses the same nix
  nix = {
    nixPath = ["nixpkgs=/etc/nixpkgs" "nixos-config=/etc/nixos/configuration.nix"];

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "daily";
    };

    settings.experimental-features = ["nix-command" "flakes"];
  };
}

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

    settings = {
      experimental-features = ["nix-command" "flakes"];

      substituters = [
        "http://fzakaria.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "fzakaria.cachix.org-1:qWCiyGu0EmmRlo65Ro7b+L/QB0clhdeEofPxTOkRNng="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}

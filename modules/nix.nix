{
  inputs,
  config,
  pkgs,
  ...
}: {
  # Put nixpkgs into /etc/nixpkgs for convenience
  environment.etc.nixpkgs.source = inputs.nixpkgs;
  # Point nixpath to that nixpkgs so that the system uses the same nix
  nix = {
    # nixpkgs has been pinned to 2.18 for a long time since newer versions have
    # been buggy. Let's try newer versions and be on the bleeding eedge
    # Should be 2.23.2 as of 2021-07-12
    package = pkgs.unstable.nixVersions.latest;

    nixPath = ["nixpkgs=/etc/nixpkgs" "nixos-config=/etc/nixos/configuration.nix"];

    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
      dates = "weekly";
      persistent = true;
    };

    settings = {
      experimental-features = ["cgroups" "nix-command" "flakes" "dynamic-derivations" "ca-derivations" "recursive-nix"];
      trusted-users = [
        "fmzakari"
        "mrw"
      ];
      substituters = [
        "http://fzakaria.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "fzakaria.cachix.org-1:qWCiyGu0EmmRlo65Ro7b+L/QB0clhdeEofPxTOkRNng="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}

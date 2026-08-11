{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  # nh (https://github.com/nix-community/nh) is a nicer frontend for
  # nixos-rebuild / home-manager that gives pretty diffs and a unified CLI.
  programs.nh = {
    enable = true;
    # Point nh at our flake so `nh os switch` (etc.) work without arguments.
    flake = "/home/fmzakari/code/github.com/fzakaria/nix-home";
    # NOTE: nh.clean is intentionally left disabled; it is mutually exclusive
    # with the nix.gc.automatic below (the module asserts on both being set).
  };

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
      # Only the two features the flake actually needs. The rest
      # ("cgroups" "dynamic-derivations" "ca-derivations" "recursive-nix")
      # were more trouble than they were worth, so they stay commented out.
      # experimental-features = ["cgroups" "nix-command" "flakes" "dynamic-derivations" "ca-derivations" "recursive-nix"];
      experimental-features = ["nix-command" "flakes"];
      trusted-users = [
        "fmzakari"
        "mrw"
      ];

      substituters = [
        "http://fzakaria.cachix.org"
        "https://nix-community.cachix.org"
        "https://cache.numtide.com"
      ];

      trusted-public-keys = [
        "fzakaria.cachix.org-1:qWCiyGu0EmmRlo65Ro7b+L/QB0clhdeEofPxTOkRNng="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "harmonia-leviathan:iCmntZCA/nIZZ6rqdkJwUCpPv1G+259hZ8JTLrlfRz8="
      ];
    };
  };
}

let
  sources = (import ../../nix/sources.nix);
  nixos =
    import (sources.nixpkgs + "/nixos") { configuration = import ./configuration.nix; };
in nixos.system

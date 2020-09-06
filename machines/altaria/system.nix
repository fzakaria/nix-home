let
  nixpkgs = (import ../../nix/sources.nix).nixos;
  nixos =
    import (nixpkgs + "/nixos") { configuration = import ./configuration.nix; };
in nixos.system

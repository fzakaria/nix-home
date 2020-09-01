{ config, pkgs, ... }: {

  nixpkgs = {
    # Add the global overlay for all machines
    overlays = [ (import ../overlay) ];

    config = {
      # Allow non open source software
      # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
      allowUnfree = true;
    };

  };

}

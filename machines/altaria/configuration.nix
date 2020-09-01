let nixpkgs = (import ../../nix/sources.nix).nixos;
in {
  imports = [
  	./hardware-configuration.nix
    (nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/platforms/nixos.nix
  ];

}

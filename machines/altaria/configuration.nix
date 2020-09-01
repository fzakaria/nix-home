let nixpkgs = (import ./nix/sources.nix).nixos;
in {
  imports = [
    (nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/platforms/nixos.nix
  ];

  ec2.hvm = true;

}

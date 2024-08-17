{
  pkgs,
  modulesPath,
  lib,
  ...
}: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];
  ec2.hvm = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

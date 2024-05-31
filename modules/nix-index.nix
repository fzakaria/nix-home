# lets enable nix-index
# but let's use nix-index-database that has a prebuilt database of packages
{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];

  programs.nix-index-database.comma.enable = true;
  # nix-index provides it's own command-not-found functionality
  programs.command-not-found.enable = false;
}

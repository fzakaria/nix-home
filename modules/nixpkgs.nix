{
  inputs,
  outputs,
  config,
  ...
}: {
  nixpkgs = {
    # Add the global overlay for all machines
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      inputs.nix-vscode-extensions.overlays.default
    ];
    config = {
      # Allow non open source software
      # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
      allowUnfree = true;
    };
  };
}

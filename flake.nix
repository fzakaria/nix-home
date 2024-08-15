{
  # This template was copied from the excellent template
  # found at https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix
  description = "Our nix-home.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Flake Utils, added so we can dedupe it.
    flake-utils.url = "github:numtide/flake-utils";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Nix-index-database
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # h
    h.url = "github:zimbatm/h/main";
    h.inputs.nixpkgs.follows = "nixpkgs";

    # agenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";

    # vscode-extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.inputs.flake-utils.follows = "flake-utils";

    # tailscale golink
    tailscale-golink.url = "github:tailscale/golink";
    tailscale-golink.inputs.nixpkgs.follows = "nixpkgs";
    tailscale-golink.inputs.flake-utils.follows = "flake-utils";

    # tailscale tclip
    tailscale-tclip.url = "github:tailscale-dev/tclip";
    # Could not follow as nixpkgs; had to use nixpkgs-unstable
    tailscale-tclip.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-hardware,
    agenix,
    nix-vscode-extensions,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;

    machine = name: modules:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules =
          [
            ./machines/${name}/configuration.nix
          ]
          ++ modules;
      };
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild switch --flake .#your-hostname'
    # You can also build them individually using
    # 'nix build .#nixosConfigurations.nyx.config.system.build.toplevel'
    nixosConfigurations = {
      nyx = machine "nyx" [];
      nixie = machine "nixie" [];
      # As this is a raspberrypi, you might want to build the sdImage
      # nix build '.#nixosConfigurations.kuato.config.system.build.sdImage'
      # Alternatively, you can deploy it as follows:
      # nixos-rebuild switch --flake .#kuato \
      #                      --target-host fmzakari@kuato
      #                      --use-remote-sudo \
      #                      --fast
      # To biuld this remotely as it's aarch64-linux add:
      # --builders "@/etc/nix/machines" --max-jobs 0
      kuato = machine "kuato" [];
    };

    # Uncomment when we want to support individual home-manager
    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager switch --flake .#your-username'
    # You can test a build via 'nix build .#homeConfigurations.your-username.activationPackage'
    homeConfigurations = {
      "fmzakari@alakwan" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./users/fmzakari
          # > Our main home-manager configuration file <
          ./modules/nixpkgs.nix
          (
            {lib, ...}: {
              home = {
                username = lib.mkForce "fzakaria";
                homeDirectory = lib.mkForce "/home/fzakaria";
              };
            }
          )
        ];
      };
      "fzakaria@confluent.io" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages."aarch64-darwin";
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main home-manager configuration file <
          ./users/fzakaria
          ./modules/nixpkgs.nix
        ];
      };
    };

    nixosMachines = forAllSystems (
      system: let
        # Filter the configurations to those that match the current system
        matchingSystemConfigurations = nixpkgs.lib.filterAttrs (_: c: c.pkgs.system == system) self.nixosConfigurations;

        # Map each matching configuration to its top-level system derivation
        toplevelDerivations = nixpkgs.lib.mapAttrs (_: c: c.config.system.build.toplevel) matchingSystemConfigurations;
      in
        toplevelDerivations
    );

    checks =
      forAllSystems (
        system:
          {
          }
          # Add all our homemanager configurations
          // (nixpkgs.lib.mapAttrs (_: c: c.activationPackage) (nixpkgs.lib.filterAttrs (_: c: c.pkgs.system == system) self.homeConfigurations))
      )
      // self.nixosMachines;
  };
}

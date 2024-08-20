{
  config,
  pkgs,
  outputs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./acme.nix
    ./quassel.nix
    ../../modules/nixpkgs.nix
    ../../modules/nix.nix
    ../../users
    inputs.agenix.nixosModules.default
    outputs.nixosModules.vpn
  ];

  networking = {
    hostName = "altaria";
    domain = "fzakaria.com";
  };

  age.secrets = {
    "github-runner.token" = {
      file = ../../users/fmzakari/secrets/github-runner.token.age;
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  services = {
    # Enable the tailscale VPN
    vpn.enable = true;

    # Register a single GitHub Runner for our CI
    github-runners.${config.networking.hostName} = {
      enable = true;
      ephemeral = true;
      replace = true;
      tokenFile = config.age.secrets."github-runner.token".path;
      url = "https://github.com/fzakaria/nix-home";
      extraLabels = [pkgs.system];
      extraPackages = with pkgs; [cachix];
    };

    prometheus = {
      exporters = {
        node = {
          enable = true;
          # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
          # https://github.com/prometheus/node_exporter?tab=readme-ov-file#enabled-by-default
          enabledCollectors = ["systemd" "processes"];
          port = 9002;
        };
      };
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
      banner = ''
        Welcome to my EC2 instance. Happy hacking!
      '';
      settings = {
        PasswordAuthentication = false;
      };
    };
  };

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11";
}

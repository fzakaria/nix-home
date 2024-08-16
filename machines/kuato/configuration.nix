{
  config,
  pkgs,
  inputs,
  outputs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    # had a big discussion on Matrix on which to use for the Raspberry Pi 4
    # looks like there are pi specific modules but they told me to not use them.
    # Also don't use the vendored Linux kernel and just use the regular one.
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../../modules/nix.nix
    outputs.nixosModules.vpn
    outputs.nixosModules.tclip
    outputs.nixosModules.grafana
    # Feedback from Matrix was to disable this and it's unecessary unless you are using
    # some esoteric hardware.
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.agenix.nixosModules.default
    inputs.tailscale-golink.nixosModules.default
  ];

  # let's not build ZFS for the Raspberry Pi 4
  boot.supportedFilesystems.zfs = lib.mkForce false;
  # compressing image when using binfmt is very time consuming
  # disable it. Not sure why we want to compress anyways?
  sdImage.compressImage = false;
  # enable the touch screen
  hardware.raspberry-pi."4".touch-ft5406.enable = true;

  # we don't import ../../modules/nixpkgs.nix since we don't want the overlay
  # rebuilding for the Raspberry Pi 4 is expensive; try to stick to what is in the cache.
  nixpkgs = {
    hostPlatform = lib.mkDefault "aarch64-linux";
    config = {
      allowUnfree = true;
    };
    overlays = [
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      # Workaround: https://github.com/NixOS/nixpkgs/issues/154163
      # modprobe: FATAL: Module sun4i-drm not found in directory
      (final: super: {
        makeModulesClosure = x:
          super.makeModulesClosure (x // {allowMissing = true;});
      })
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };
  };

  networking = {
    networkmanager.enable = true;
    hostName = "kuato";
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  environment.systemPackages = with pkgs; [
    vim
    git
    libraspberrypi
    raspberrypi-eeprom
    firefox
    chromium
  ];

  services = {
    # Enable the tailscale VPN
    vpn.enable = true;

    grafana-proxy = {
      enable = true;
      tailscaleAuthKeyFile = config.age.secrets."tailscale-grafana.key".path;
    };

    # Right now this is not exported via a Tailscale host like Grafana
    # but we can access it via http://kuato:9001/
    # do we care to to do that? Not sure right now.
    # We can re-use grafana-to-proxy for this if so.
    # https://github.com/teevik/Config/blob/c1ac3d3f55d7c67077aa59ac8a5b2774b4ca36a2/modules/nixos/services/tailscale-proxy/default.nix#L9
    prometheus = {
      enable = true;
      port = 9001;
      extraFlags = [
        "--web.enable-admin-api"
        # if we want to expand default retention time
        #  "--storage.tsdb.retention.time=365d"
      ];
      exporters = {
        node = {
          enable = true;
          # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
          # https://github.com/prometheus/node_exporter?tab=readme-ov-file#enabled-by-default
          enabledCollectors = ["systemd" "processes"];
          port = 9002;
        };
      };
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = ["kuato:${toString config.services.prometheus.exporters.node.port}"];
            }
          ];
        }
      ];
    };

    openssh = {
      enable = true;
      startWhenNeeded = true;
      banner = ''
        Welcome to my RaspberryPi 4. Happy hacking!
      '';
      settings = {
        PasswordAuthentication = false;
      };
    };
    golink = {
      enable = true;
      tailscaleAuthKeyFile = config.age.secrets."tailscale-golink.key".path;
    };
    tclip = {
      enable = true;
      tailscaleAuthKeyFile = config.age.secrets."tailscale-tclip.key".path;
      funnel = true;
    };
    # Enable the X11 windowing system.
    xserver = {
      enable = true;
      desktopManager = {
        gnome.enable = true;
      };
      displayManager = {
        # Enable the GNOME Desktop Environment
        gdm = {
          enable = true;

          # FIXME: I want to disable wayland but the touch screen seems
          # to not work otherwise.
          # wayland = false;
        };
      };
    };
  };

  # Normally we would re-use the same user configurations in the users directory
  # but since this is a Raspberry Pi 4, lets make a much smaller closure.
  users.users.fmzakari = {
    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = ["wheel" "networkmanager"];
    description = "Farid Zakaria";
    openssh.authorizedKeys.keyFiles = [
      ../../users/fmzakari/keys
    ];
    # Allow the graphical user to login without password
    initialHashedPassword = "";
  };

  age.secrets = {
    "tailscale-golink.key" = {
      file = ../../users/fmzakari/secrets/tailscale-golink.key.age;
      owner = config.services.golink.user;
      group = config.services.golink.group;
    };
    "tailscale-tclip.key" = {
      file = ../../users/fmzakari/secrets/tailscale-tclip.key.age;
      owner = config.services.tclip.user;
      group = config.services.tclip.group;
    };
    "tailscale-grafana.key" = {
      file = ../../users/fmzakari/secrets/tailscale-grafana.key.age;
      owner = config.services.grafana-proxy.user;
      group = config.services.grafana-proxy.group;
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  # Allow the user to log in as root without a password.
  users.users.root.initialHashedPassword = "";

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}

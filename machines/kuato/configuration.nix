{
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
    # Feedback from Matrix was to disable this and it's unecessary unless you are using
    # some esoteric hardware.
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
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
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      })
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
    networkmanager.enable = false;
    hostName = "kuato";
    wireless = {
      enable = true;
      networks."Moose's Castle".psk = "blah";
      interfaces = ["wlan0"];
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  environment.systemPackages = with pkgs; [
    vim
    git
    libraspberrypi
    raspberrypi-eeprom
  ];

  services = {
    # Enable the tailscale VPN
    vpn.enable = true;
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

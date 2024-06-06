{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/nix.nix
    ../../modules/nixpkgs.nix
    ../../users
    ../../modules/nix-index.nix
    ../../modules/fonts.nix
    outputs.nixosModules.vpn
    outputs.nixosModules.fprint-laptop-lid
  ];

  # Use the systemd-boot EFI boot loader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "nyx";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  fonts.packages = with pkgs; [
    nerdfonts
  ];

  services = {
    # Enable turning off fingerprint reader when laptop lid is closd
    disable-fingerprint-reader-on-laptop-lid.enable = true;
    # Enable the tailscale VPN
    vpn.enable = true;
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

          # TODO(fzakaria): google-chrome doesn't respect fractional scaling
          # when wayland is toggled. Disable for now.
          wayland = false;
        };
      };
    };
    fwupd.enable = true;
    hardware.bolt.enable = true;
    yubikey-agent.enable = true;
    openssh = {
      enable = true;
      startWhenNeeded = true;
      banner = ''
        Welcome to my Framework AMD laptop. Happy hacking!
      '';
      settings = {
        PasswordAuthentication = false;
      };
    };
  };

  programs = {
    ssh.startAgent = false;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    vscode
    git
    google-chrome
    firefox
    yubikey-personalization
    yubikey-manager-qt
    yubikey-manager
    pstree
    niv
    ripgrep
    bat
    warp-terminal
    fd
    eza
    gnome.gnome-tweaks
    htop
    btop
    amdgpu_top
    signal-desktop
    linuxPackages_latest.perf
    bc
    gdb
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11";
}

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
    ../../users/fmzakari/remote.nix
    ../../modules/nixpkgs.nix
    ../../users
    inputs.agenix.nixosModules.default
    outputs.nixosModules.vpn
    outputs.nixosModules.fprint-laptop-lid
  ];

  # Use the systemd-boot EFI boot loader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Let's emulate aarch64-linux so we can build our raspberry pi images
    binfmt.emulatedSystems = ["aarch64-linux"];
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
    # Enable printing
    printing.enable = true;
    # https://nixos.wiki/wiki/Printing#Enable_autodiscovery_of_network_printers
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
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
    hardware = {
      bolt.enable = true;
    };
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

  virtualisation = {
    docker = {
      enable = true;
    };
  };

  security = {
    # This is to fix GDM prompting for fingerprint right away.
    # TODO(fzakaria): understand it.
    # https://github.com/NixOS/nixpkgs/issues/171136#issuecomment-1627779037
    pam.services = {
      login.fprintAuth = false;
      gdm-fingerprint = lib.mkIf (config.services.fprintd.enable) {
        text = ''
          auth       required                    pam_shells.so
          auth       requisite                   pam_nologin.so
          auth       requisite                   pam_faillock.so      preauth
          auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
          auth       optional                    pam_permit.so
          auth       required                    pam_env.so
          auth       [success=ok default=1]      ${pkgs.gnome.gdm}/lib/security/pam_gdm.so
          auth       optional                    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so

          account    include                     login

          password   required                    pam_deny.so

          session    include                     login
          session    optional                    ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
        '';
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
    sublime-merge
    python3
    sqlite-interactive
    inputs.agenix.packages.x86_64-linux.default
    jetbrains.clion
    file
    element-desktop
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

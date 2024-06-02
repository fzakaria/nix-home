# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
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
    ../../users
    ../../modules/nix-index.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-1b9f570b-04ee-40f2-b5c1-4966d5b6c573".device = "/dev/disk/by-uuid/1b9f570b-04ee-40f2-b5c1-4966d5b6c573";
  networking.hostName = "nixie"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      "/home"
      "/tmp"
      "/var/tmp"
      "/var/lib/systemd"
      "/etc/nixos"
      "/var/lib/nixos"
    ];
    files = [
      "/etc/adjtime"
      "/etc/machine-id"
      "/etc/passwd"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    emacs
    niv
    pinentry
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.

  # enable gnupg
  programs.gnupg.agent = {
    enable = true;
  };

  # List services that you want to enable:

  hardware.pulseaudio.enable = true;
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.fwupd.enable = true;
  programs.ssh.startAgent = true;
  programs.zsh.enable = true;

  # TODO - this is the default, do you need it?
  services.logind.lidSwitch = "suspend";

  # Use libinput to disable tap-to-click and move emulated buttons to
  # the bottom of the trackpad.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad.tapping = false;
  services.xserver.libinput.touchpad.clickMethod = "clickfinger";

  services.xserver.displayManager.lightdm.enable = true;
  # Emulate an old-fashioned session
  # https://github.com/NixOS/nixpkgs/issues/177555#issuecomment-1263498702
  # https://github.com/dwf/dotfiles/blob/eb783902a03a5c0259bb28843101746db31c5623/nixos/modules/user-xsession.nix
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "normal-user-session";
      start = ''exec $HOME/.xsessionrc'';
    }
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}

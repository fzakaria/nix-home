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
    inputs.rewind.nixosModules.default
    inputs.bootvine.nixosModules.default
    inputs.earwig.nixosModules.default
    outputs.nixosModules.vpn
    outputs.nixosModules.fprint-laptop-lid
  ];

  # Use the systemd-boot EFI boot loader
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # The ESP is 487M. Left unbounded, systemd-boot keeps an entry (and
        # nixos keeps a kernel + initrd) for every generation that survives
        # nix.gc, which eventually fails a rebuild with ENOSPC halfway through
        # installing the bootloader. Ten is plenty to roll back from.
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    # Let's emulate aarch64-linux so we can build our raspberry pi images
    binfmt.emulatedSystems = ["aarch64-linux"];

    # bootvine can only follow the boot from the initrd onward when the
    # initrd runs systemd. NixOS 26.05 already defaults to a systemd initrd;
    # the explicit setting records that bootvine depends on it.
    initrd.systemd.enable = true;

    # bootvine silences the kernel console once it starts, but kernel
    # messages printed before then still land on screen. Keep those to
    # errors so they do not scroll over the tree.
    consoleLogLevel = 3;
  };

  # High-DPI console
  console = {
    font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = "us";
    # prevents `systemd-vconsole-setup` failing during systemd initrd
    earlySetup = true;
  };
  systemd.services.systemd-vconsole-setup.unitConfig.After = "local-fs.target";

  # /etc/resolvconf.conf invalidates the nscd cache with a `try-restart` every
  # time resolv.conf is regenerated. During boot NetworkManager and tailscaled
  # rewrite it five-plus times in a few seconds, which trips systemd's default
  # limit of five starts per ten seconds and leaves nscd dead for the rest of
  # the session -- so every NSS lookup falls back to the slow path. The
  # restarts are legitimate, so drop the rate limit rather than the restarts.
  systemd.services.nscd.startLimitIntervalSec = 0;

  networking = {
    hostName = "nyx";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs.nerd-fonts; [
      fira-code
      fira-mono
      caskaydia-cove
      caskaydia-mono
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["CaskaydiaCove Nerd Font"];
        sansSerif = ["CaskaydiaCove Nerd Font"];
        monospace = ["CaskaydiaCove Nerd Font Mono"];
        emoji = ["CaskaydiaCove Nerd Font"];
      };
    };
  };

  hardware = {
    # enables support for SANE scanners
    sane.enable = true;

    # BAP is BlueZ's LE Audio profile, and it needs Bluetooth ISO sockets that
    # this kernel does not build (no CONFIG_BT_LE_AUDIO, nothing for ISO in
    # /proc/net/protocols). The plugin therefore fails its probe on every boot
    # and logs two errors before disabling itself. Nothing is lost by not
    # loading it -- A2DP still registers ldac/aptx/aac as before -- and it goes
    # quiet. Drop this if the kernel ever ships ISO socket support.
    bluetooth.disabledPlugins = ["bap"];
  };

  services = {
    # Show a live tree of pending systemd units on the console during boot
    # and shutdown, instead of the scrolling kernel and systemd log.
    bootvine.enable = true;
    guix = {
      enable = true;
    };
    # A fuse filesystem that dynamically populates contents of /bin
    # and /usr/bin/ so that it contains all executables from the PATH
    # of the requesting process.
    envfs = {
      enable = true;
      package = pkgs.unstable.envfs;
    };
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
    # Hold Super+Space and speak; earwig transcribes it locally and types the
    # result at the cursor.
    earwig.enable = true;
    # Enable the GNOME Desktop Environment
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    # Enable the X11 windowing system.
    xserver = {
      enable = true;
    };
    fwupd.enable = true;
    hardware = {
      bolt.enable = true;
    };
    yubikey-agent.enable = true;
    openssh = {
      enable = true;
      startWhenNeeded = true;
      settings = {
        Banner = toString (pkgs.writeText "sshd-banner" ''
          Welcome to my Framework AMD laptop. Happy hacking!
        '');
        PasswordAuthentication = false;
      };
    };
  };

  # GDM has no HideUsers knob -- its greeter list comes from AccountsService,
  # which offers up every account at or above UID_MIN (1000 here) that has a
  # login shell. The supported way to drop a single account from that list is
  # to mark it a system account in AccountsService's own per-user cache. root
  # needs no such entry: GDM filters anything below UID_MIN on its own.
  #
  # `f+` rewrites the file on every boot, so any greeter preference
  # AccountsService stores for mrw (icon, language, session) is reset -- moot
  # for an account that no longer appears in the greeter. mrw keeps a normal
  # login shell and can still sign in through "Not listed?".
  systemd.tmpfiles.rules = [
    ''f+ /var/lib/AccountsService/users/mrw 0600 root root - [User]\nSystemAccount=true\n''
  ];

  # Disable gcr-ssh-agent as it hijacks SSH_AUTH_SOCK and prevents
  # yubikey-agent from setting it correctly.
  systemd.user.services.gcr-ssh-agent.enable = false;
  systemd.user.sockets.gcr-ssh-agent.enable = false;

  virtualisation = {
    docker = {
      package = pkgs.docker_29;
      enable = true;
    };
  };

  age.secrets = {
    "atuin.key" = {
      file = ../../users/fmzakari/secrets/atuin.key.age;
      owner = "fmzakari";
    };
    # Gmail app-specific password consumed by aerc (users/fmzakari/aerc.nix).
    "gmail-app-password" = {
      file = ../../users/fmzakari/secrets/gmail-app-password.age;
      owner = "fmzakari";
    };
  };

  # security = {
  #   # This is to fix GDM prompting for fingerprint right away.
  #   # TODO(fzakaria): understand it.
  #   # https://github.com/NixOS/nixpkgs/issues/171136#issuecomment-1627779037
  #   pam.services = {
  #     login.fprintAuth = false;
  #     gdm-fingerprint = lib.mkIf (config.services.fprintd.enable) {
  #       text = ''
  #         auth       required                    pam_shells.so
  #         auth       requisite                   pam_nologin.so
  #         auth       requisite                   pam_faillock.so      preauth
  #         auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
  #         auth       optional                    pam_permit.so
  #         auth       required                    pam_env.so
  #         auth       [success=ok default=1]      ${pkgs.gdm}/lib/security/pam_gdm.so
  #         auth       optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

  #         account    include                     login

  #         password   required                    pam_deny.so

  #         session    include                     login
  #         session    optional                    ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
  #       '';
  #     };
  #   };
  # };

  programs = {
    noisetorch = {
      enable = true;
    };

    obs-studio = {
      package = pkgs.unstable.obs-studio;
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.unstable.obs-studio-plugins; [
        obs-pipewire-audio-capture
        obs-backgroundremoval
        wlrobs
      ];
    };

    ssh.startAgent = false;

    # 1Password CLI (`op`) and desktop app. Both go through their NixOS
    # modules rather than systemPackages: `op` needs a setgid wrapper to talk
    # to the desktop app, and the desktop app needs a polkit policy to unlock
    # with the system password (and fingerprint) instead of the master
    # password every time.
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["fmzakari"];
    };

    # I got tired of facing NixOS issues
    # Let's be more pragmatic and try to run binaries sometimes
    # at the cost of sweeping bugs under the rug.
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib # numpy
      ];
    };
  };

  # Disable this because we are using nix-ld instead
  environment.stub-ld.enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
    google-chrome
    firefox
    yubikey-personalization
    yubikey-manager
    pstree
    niv
    ripgrep
    bat
    fd
    eza
    gnome-tweaks
    htop
    btop
    amdgpu_top

    # Astra Monitor: system metrics in the GNOME top bar. Enabled for my user
    # in users/fmzakari. It reads most of what it shows through a GJS typelib
    # and shells out for the rest, so the pieces below are what turn its
    # panels from "n/a" into numbers:
    gnomeExtensions.astra-monitor
    # `gi://GTop` -- CPU, memory, swap and per-process accounting. Without it
    # the extension loads but those panels stay empty. Installing it at system
    # level is what puts GTop-2.0.typelib somewhere gnome-shell looks.
    libgtop
    lm_sensors # `sensors`, for the temperature readouts
    pciutils # `lspci`, to name the GPU
    iw # wifi link speed and signal
    # `amdgpu_top` above already covers the Radeon 780M.
    # the 24.11 expired
    unstable.signal-desktop
    perf
    bc
    gdb
    bcompare
    python3
    sqlite-interactive
    inputs.agenix.packages.x86_64-linux.default
    # (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea ["github-copilot"])
    unstable.jetbrains.idea
    unstable.jetbrains.clion
    file
    # web app better
    # element-desktop
    bazel_7
    unstable.code-cursor
    meson
  ];

  # ../../users gives mrw the full desktop package set he runs on nixie: an X11
  # session, IDEs, toolchains and games. On nyx the account only ever gets used
  # over ssh, so replace that list with the handful of things a shell session
  # needs. mkForce is required because users.users.<name>.packages is a list
  # option, and list options concatenate their definitions instead of
  # overriding them.
  users.extraUsers.mrw.packages = lib.mkForce (with pkgs; [
    emacs
    killall
    man-pages
  ]);

  # Rewind VM (https://rewindvm.dev): the rewind CLI and the desktop app. The
  # module also adds rewindvm.cachix.org to Nix's substituters.
  # /dev/kvm is already 0666 on this machine, so no kvm group is needed.
  programs.rewind = {
    enable = true;
    app.enable = true;
    # nyx is a Ryzen 7840U (Zen 4). Set rr's branch counter workaround at
    # every boot so runs use counter time instead of exit time. This sets an
    # MSR bit that changes how every CPU speculates around locked
    # instructions, for every program on the machine.
    amdBranchCounterWorkaround = true;
    # Add rewind-amd to Nix's system features, so derivations that run Rewind
    # in their build and name rewind-amd in requiredSystemFeatures build on
    # nyx. `rewind doctor` reports kvm, cpu and clock as ok here, which the
    # module asks for before setting the feature.
    systemFeature = "amd";
  };

  # Add leviathan which needs Tailscale.
  # mrw does not want to bug Alex to get onto it
  nix.settings.substituters = [
    "http://leviathan.cymric-daggertooth.ts.net:5000?priority=100"
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

# Omarchy on NixOS: one module that turns a machine into DHH's Hyprland
# desktop, system side and user side together.
#
# The split follows a single rule. Anything NixOS already models -- the
# compositor, the greeter, the boot splash, fonts, portals, audio, the package
# set -- is expressed as native NixOS options, because that is where the
# options are already correct and maintained. Everything that is Omarchy
# itself -- the Lua config tree, the Quickshell desktop, 314 shell commands,
# 22 themes -- is vendored from upstream by pkgs/omarchy and reached through
# $OMARCHY_PATH. Rewriting that second half in Nix would be a fork, and it
# would drift from upstream inside one release.
#
# What is deliberately gone: pacman, yay, the AUR, `omarchy update`, the
# per-user migration history, the ISO installer, and the Arch bootloader and
# snapshot integration. `nixos-rebuild` is the update mechanism here, so
# pkgs/omarchy drops those scripts rather than leaving commands on PATH that
# would half-run and leave the system inconsistent.
#
# This is the system half only. The user half -- the Hyprland config tree,
# the active theme, and the state Omarchy writes into $HOME -- is the
# home-manager module at modules/home-manager/omarchy.nix.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.omarchy;

  # The tree root Omarchy resolves its own data against. Every script and Lua
  # module derives its paths from this one value.
  omarchyPath = "${cfg.package}/${cfg.package.omarchyPath}";
in {
  options.services.omarchy = {
    enable = mkEnableOption "the Omarchy desktop";

    package = mkOption {
      type = types.package;
      default = pkgs.omarchy;
      defaultText = literalExpression "pkgs.omarchy";
      description = "The vendored Omarchy tree, as built by pkgs/omarchy.";
    };

    hyprlandPackage = mkOption {
      type = types.package;
      default = pkgs.unstable.hyprland;
      defaultText = literalExpression "pkgs.unstable.hyprland";
      description = "Hyprland package to run the session with.";
    };

    quickshellPackage = mkOption {
      type = types.package;
      default = pkgs.unstable.quickshell;
      defaultText = literalExpression "pkgs.unstable.quickshell";
      description = "Quickshell, which runs Omarchy's bar, menus, lock screen and notifications.";
    };

    greeterUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fmzakari";
      description = ''
        Account the greeter authenticates. Omarchy's SDDM theme shows a
        password box and no username: it reads `userModel.lastUser`, which
        SDDM takes from the `[Last] User=` key of /var/lib/sddm/state.conf.
        That file is written by a successful login, so on a machine that has
        never logged in through SDDM the name is empty and every attempt
        fails. Setting this seeds the file, and SDDM maintains it from then
        on.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = versionAtLeast cfg.hyprlandPackage.version "0.55";
        message = ''
          services.omarchy requires Hyprland 0.55 or newer for its Lua
          configuration, but hyprlandPackage is ${cfg.hyprlandPackage.version}.
        '';
      }
    ];

    warnings = optional (cfg.greeterUser == null) ''
      services.omarchy.greeterUser is unset. Omarchy's SDDM theme has no
      username field and authenticates whoever /var/lib/sddm/state.conf
      names, so a machine that has never logged in through SDDM cannot log
      in at all. Set it unless that file already exists.
    '';

    # Seed the account the greeter authenticates. `C` copies the file in only
    # when the destination is missing, so SDDM's own updates to the last user
    # survive every later rebuild. A copy rather than an `f` rule with inline
    # content, because the tmpfiles generator escapes backslashes and would
    # turn the line separators into literal \n text.
    systemd.tmpfiles.settings = mkIf (cfg.greeterUser != null) {
      "10-omarchy-sddm-state"."/var/lib/sddm/state.conf".C = {
        user = "sddm";
        group = "sddm";
        mode = "0600";
        argument = toString (pkgs.writeText "sddm-state.conf" ''
          [Last]
          User=${cfg.greeterUser}
        '');
      };
    };

    # Omarchy's greeter draws a password box and nothing else, so it cannot
    # say that PAM is waiting on the fingerprint reader instead. Leave the
    # reader to sudo and the lock screen, where the prompt is visible.
    # mkDefault, so a machine that wants it back can just say so.
    security.pam.services.sddm.fprintAuth = mkDefault false;

    # The compositor. uwsm is how Omarchy's session starts (see its
    # wayland-sessions entry), and it is what puts the session's environment
    # into the user systemd manager that the shipped user units depend on.
    programs.hyprland = {
      enable = true;
      package = cfg.hyprlandPackage;
      withUWSM = true;
    };

    # Omarchy's own session entry, so the greeter offers "Omarchy (Hyprland
    # uwsm)" rather than only the stock Hyprland session.
    services.displayManager.sessionPackages = [cfg.package];

    # The greeter, themed to match the desktop.
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "omarchy";
    };

    # The boot splash. pkgs/omarchy rewrites the theme's ImageDir and
    # ScriptFile to its store path so the NixOS initrd fixup can find them.
    boot.plymouth = {
      enable = true;
      theme = "omarchy";
      themePackages = [cfg.package];
    };

    # Omarchy's 50-omarchy.conf fontconfig drop-in, expressed as NixOS
    # options: JetBrains Mono Nerd Font for monospace, Liberation for the
    # proportional families, Noto for emoji and CJK coverage.
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        liberation_ttf
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        font-awesome
        cfg.package # Omarchy's own icon font
      ];
      fontconfig.defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font"];
        sansSerif = ["Liberation Sans"];
        serif = ["Liberation Serif"];
        emoji = ["Noto Color Emoji"];
      };
    };

    # Screen sharing and file pickers under Hyprland. The GTK portal is what
    # Omarchy's own preview share picker sits in front of.
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    services = {
      # Audio. Omarchy's volume, output switching and speaker tuning all
      # drive PipeWire through WirePlumber.
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      # The bar's power widget and `omarchy-powerprofiles-init` read this.
      power-profiles-daemon.enable = true;

      # Automounting for removable media, started from Omarchy's autostart.
      udisks2.enable = true;

      # Nautilus is Omarchy's file manager; gvfs gives it network and MTP
      # mounts, and sushi gives it space-bar previews.
      gvfs.enable = true;
      gnome.sushi.enable = true;

      # Secrets for the browser and anything using libsecret.
      gnome.gnome-keyring.enable = true;

      # `omarchy-locate` and the file search in the menu.
      locate = {
        enable = true;
        package = pkgs.plocate;
      };
    };

    # Bluetooth, with the pairing agent Omarchy's bluetooth panel expects.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Make the vendored user units visible to systemd. Their [Install]
    # sections are not honoured through this option, so each unit that should
    # actually run is enabled explicitly below.
    systemd.packages = [cfg.package];

    # Which of the vendored user units actually run, and what pulls each one
    # in. `overrideStrategy = "asDropin"` keeps the unit body that came from
    # the package and adds only the enablement, so upstream's ExecCondition
    # and ConditionEnvironment guards stay intact. Speaker tuning is left out:
    # it needs a per-machine filter-chain config that only exists once
    # `omarchy-audio-tuning` has been run for that hardware.
    systemd.user.services =
      mapAttrs (_: target: {
        overrideStrategy = "asDropin";
        wantedBy = [target];
      }) {
        bt-agent = "graphical-session.target";
        omarchy-crash-watch = "graphical-session.target";
        omarchy-fcitx5 = "graphical-session.target";
        omarchy-recover-internal-monitor = "graphical-session-pre.target";
        omarchy-sleep-lock = "graphical-session.target";
        omarchy-tailscale-receive = "graphical-session.target";
      };

    environment = {
      # Omarchy's own hook for running from somewhere other than
      # /usr/share/omarchy. `default/bash/env-bootstrap` sources this file,
      # so pointing it at the store path is all it takes for every script,
      # every Lua module and the uwsm session to agree on the tree root.
      etc."omarchy.conf".text = ''
        OMARCHY_PATH=${omarchyPath}
      '';

      # NixOS sources /etc/profile.d/*.sh from /etc/profile, which is the
      # same entry point upstream uses for login shells.
      etc."profile.d/omarchy.sh".text = ''
        [ -r ${omarchyPath}/default/bash/env-bootstrap ] && . ${omarchyPath}/default/bash/env-bootstrap
      '';

      # fcitx5 turns the CapsLock compose sequences in ~/.XCompose into text.
      # Upstream ships these as an environment.d drop-in.
      sessionVariables = {
        INPUT_METHOD = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
      };

      systemPackages = with pkgs; [
        # Omarchy itself: 314 commands, the Quickshell desktop, the Lua
        # config tree, the themes and the session entry.
        cfg.package

        # The desktop shell and the compositor's own utilities.
        cfg.quickshellPackage
        unstable.hyprland-qtutils
        hyprpicker
        hyprsunset
        xdg-terminal-exec
        xdg-utils
        wl-clipboard
        wtype
        grim
        slurp
        brightnessctl
        pamixer
        playerctl
        udiskie
        libnotify

        # Terminal and shell tooling, the bulk of omarchy-base.packages.
        foot
        bat
        btop
        dua
        eza
        fd
        fzf
        ripgrep
        fastfetch
        gum
        jq
        lazygit
        lazydocker
        plocate
        starship
        tldr
        tmux
        zoxide
        socat
        inotify-tools
        unzip
        whois
        yt-dlp
        qrencode
        zbar
        tesseract
        imagemagick
        vips
        ffmpegthumbnailer
        mise
        gpu-screen-recorder

        # Omarchy's own applications, all bound to keys in its default
        # config: omacalc on SUPER+CTRL+Q, omawrite on SUPER+SHIFT+W, herdr
        # on the agent bindings. pkgs/omarchy/oma-app.nix builds the first
        # three; herdr packages itself and arrives through the overlay.
        omacut
        omacalc
        omawrite
        herdr
        # ttfx backs the screensaver (omarchy-system-lock pkills it by name),
        # tensaku is the screenshot annotator the capture and clipboard paths
        # open, and try is preinstalled as tobi-try.
        ttfx
        tensaku
        try

        # Graphical applications Omarchy ships with and binds keys to.
        chromium
        nautilus
        imv
        mpv
        mpvScripts.mpris
        obsidian
        pinta
        localsend
        moonlight-qt
        xournalpp
        libreoffice-fresh
        kdePackages.kdenlive
        gnome-disk-utility
        system-config-printer

        # Input method and theming assets the shell and GTK apps look up.
        fcitx5
        fcitx5-gtk
        yaru-theme
        gnome-themes-extra
        libsecret

        # System utilities the omarchy-* scripts shell out to.
        alsa-utils
        bluez-tools
        ddcutil
        power-profiles-daemon
        pciutils
        usbutils
        wirelesstools
      ];
    };

    # Chromium is Omarchy's default browser and the host for its web apps.
    programs.chromium.enable = true;
  };
}

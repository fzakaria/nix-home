# Local voice dictation: hold a hotkey, speak, and the transcription is typed
# at the cursor. Whisper runs entirely offline, accelerated on the GPU through
# Vulkan. Adapted from https://github.com/adeci/root.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.voxtype;

  # The daemon reads this once at start and does not hot-reload, so a config
  # change needs `systemctl --user restart voxtype`.
  configFile = (pkgs.formats.toml {}).generate "voxtype-config.toml" {
    engine = "whisper";
    # Lets the daemon remember whether it is currently recording.
    state_file = "auto";

    audio = {
      device = "default";
      # Whisper expects 16 kHz; anything else is resampled.
      sample_rate = 16000;
      max_duration_secs = cfg.maxDurationSecs;
    };

    hotkey = {
      enabled = true;
      key = cfg.hotkey.key;
      mode = "push_to_talk";
    };

    whisper = {
      backend = "local";
      model = cfg.model;
      language = "en";
      translate = false;
    };

    # The on-screen display needs a compositor widget we do not run.
    osd.enabled = false;

    output = {
      mode = "type";
      # GNOME's Mutter does not implement the virtual-keyboard protocol that
      # wtype (the default first driver) needs, so name the drivers that do
      # work rather than pay a failed wtype attempt on every transcription.
      # dotool types through /dev/uinput, which works on any compositor.
      driver_order = ["dotool" "clipboard"];
      pre_type_delay_ms = 100;
      # Dictation is its own feedback; desktop notifications only get in the way.
      notification = {
        on_recording_start = false;
        on_recording_stop = false;
        on_transcription = false;
      };
    };

    text = {
      spoken_punctuation = true;
      replacements = cfg.replacements;
    };
  };
in {
  options.services.voxtype = {
    enable = mkEnableOption "voxtype local voice dictation";

    package = mkOption {
      type = types.package;
      # Not in nixpkgs 25.11 yet; the Vulkan build is what makes the larger
      # Whisper models usable at dictation speed.
      default = pkgs.unstable.voxtype-vulkan;
      defaultText = literalExpression "pkgs.unstable.voxtype-vulkan";
      description = "The voxtype package to run.";
    };

    model = mkOption {
      type = types.str;
      default = "large-v3-turbo";
      description = ''
        Whisper model to transcribe with. Downloaded on first start into
        $XDG_DATA_HOME/voxtype. See `voxtype setup model` for the full list.
      '';
    };

    maxDurationSecs = mkOption {
      type = types.int;
      default = 60;
      description = ''
        Recording stops on its own after this many seconds. What was captured
        up to that point is still transcribed.
      '';
    };

    hotkey = {
      key = mkOption {
        type = types.str;
        default = "F13";
        description = ''
          The evdev key to hold while speaking. F13 has no physical key on a
          normal keyboard, which is the point -- see `remapSuperSpace`.
        '';
      };

      remapSuperSpace = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use keyd to fold Super+Space into `hotkey.key` at the evdev layer.
          The daemon's hotkey listener reads raw key events and so cannot match
          a chord itself; keyd collapses the chord into one unambiguous key
          before anything else on the system sees it.
        '';
      };
    };

    replacements = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = literalExpression ''{"nix os" = "NixOS";}'';
      description = ''
        Word replacements applied to the transcription, for terms Whisper
        reliably mishears. Matching is case-insensitive.
      '';
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      example = literalExpression ''["fmzakari"]'';
      description = ''
        Users allowed to dictate. They are put in `input` (the hotkey listener
        reads keyboards directly) and `uinput` (dotool types through a virtual
        keyboard device).
      '';
    };
  };

  config = mkIf cfg.enable {
    environment = {
      # Also drop the config where an interactive `voxtype` picks it up, so a
      # manual run and the daemon agree on the configuration.
      etc."xdg/voxtype/config.toml".source = configFile;
      systemPackages = [cfg.package];
    };

    # Creates /dev/uinput with a group dotool can be given access to.
    hardware.uinput.enable = true;

    users.users = genAttrs cfg.users (_: {
      extraGroups = ["input" "uinput"];
    });

    # Collapse the compositor-facing chord into one unambiguous evdev event.
    services.keyd = mkIf cfg.hotkey.remapSuperSpace {
      enable = true;
      keyboards.default.settings.meta.space = toLower cfg.hotkey.key;
    };

    systemd.user.services.voxtype = {
      description = "Local voice-to-text dictation";
      documentation = ["https://voxtype.io"];
      partOf = ["graphical-session.target"];
      after = [
        "graphical-session.target"
        "network-online.target"
        "pipewire.service"
        "pipewire-pulse.service"
      ];
      wants = ["network-online.target"];
      path = [
        cfg.package
        pkgs.curl
        pkgs.wl-clipboard
      ];
      serviceConfig = {
        # Type=simple lets system activation finish while a missing model downloads.
        Type = "simple";
        ExecStart = pkgs.writeShellScript "voxtype-start" ''
          set -euo pipefail

          # `setup` writes a config of its own on first run; point it at a
          # throwaway XDG_CONFIG_HOME so only the model download survives.
          config_home=$(${pkgs.coreutils}/bin/mktemp -d)
          trap '${pkgs.coreutils}/bin/rm -rf "$config_home"' EXIT

          # Best-effort: once the model is on disk this is a no-op, and a login
          # without network should not put the unit into a restart loop.
          XDG_CONFIG_HOME="$config_home" \
            ${cfg.package}/bin/voxtype setup \
              --download \
              --model ${cfg.model} \
              --no-post-install \
            || echo "voxtype: model download failed, continuing" >&2

          exec ${cfg.package}/bin/voxtype --config ${configFile} daemon
        '';
        Environment = [
          "RUST_LOG=warn"
          "XDG_RUNTIME_DIR=%t"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      wantedBy = ["graphical-session.target"];
    };
  };
}

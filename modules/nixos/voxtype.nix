# Local voice dictation: hold a hotkey, speak, and the transcription is typed
# at the cursor. Transcription runs entirely offline through Parakeet, NVIDIA's
# FastConformer transducer, on ONNX Runtime.
#
# Parakeet rather than Whisper because Whisper pads every clip to a fixed 30
# second window, so a three word utterance costs the same encoder pass as a
# paragraph -- measured at ~1.95s for 2s of speech on this laptop's iGPU, which
# is most of the felt latency. Parakeet consumes the audio's real length
# instead, so short dictations get short waits.
# Adapted from https://github.com/adeci/root.
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
    engine = "parakeet";
    # Lets the daemon remember whether it is currently recording.
    state_file = "auto";

    audio = {
      device = "default";
      # The acoustic frontend expects 16 kHz; anything else is resampled.
      sample_rate = 16000;
      max_duration_secs = cfg.maxDurationSecs;
    };

    hotkey = {
      enabled = true;
      key = cfg.hotkey.key;
      mode = "push_to_talk";
    };

    parakeet = {
      # A bare name here; the daemon resolves it under its models directory.
      model = cfg.model;
      # Auto-detection sniffs the model directory's layout and cannot tell
      # what the int8 files are, so it warns and guesses. The TDT guess is
      # right for this model; saying so explicitly silences the warning and
      # stops a future model layout from silently picking the CTC path.
      model_type = "tdt";
      # Keep the model resident so the first dictation after login does not
      # pay the load.
      on_demand_loading = false;
    };

    # Both OSD frontends anchor their window with wlr-layer-shell, a wlroots
    # protocol Mutter does not implement, and the nixpkgs build does not turn
    # on the osd-gtk4/osd-native cargo features anyway. Desktop notifications
    # below stand in for it on GNOME.
    osd.enabled = false;

    output = {
      mode = "type";
      # GNOME's Mutter does not implement the virtual-keyboard protocol that
      # wtype (the default first driver) needs, so name the drivers that do
      # work rather than pay a failed wtype attempt on every transcription.
      # dotool types through /dev/uinput, which works on any compositor.
      driver_order = ["dotool" "clipboard"];
      pre_type_delay_ms = 100;
      # Standing in for the OSD: without them there is no sign the daemon
      # heard the hotkey until the text lands. The transcription itself is
      # typed at the cursor, so repeating it in a notification is just noise.
      notification = {
        on_recording_start = true;
        on_recording_stop = true;
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
      # Not in nixpkgs 25.11 yet. The ONNX build is the one that carries the
      # Parakeet engine, and unlike a `voxtype-vulkan.override { onnxSupport
      # = true; }` it comes straight from the binary cache rather than
      # recompiling Rust and whisper.cpp on every nixpkgs bump.
      default = pkgs.unstable.voxtype-onnx;
      defaultText = literalExpression "pkgs.unstable.voxtype-onnx";
      description = "The voxtype package to run.";
    };

    model = mkOption {
      type = types.str;
      default = "parakeet-tdt-0.6b-v3-int8";
      description = ''
        Parakeet model to transcribe with. Downloaded on first start into
        $XDG_DATA_HOME/voxtype. See `voxtype setup model` for the full list.

        The int8 build is the quantized one: 670 MB against 2.6 GB for the
        fp32 `parakeet-tdt-0.6b-v3`, and int8 is precisely what this CPU's
        AVX-512 VNNI instructions accelerate.
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
        default = "F24";
        description = ''
          The evdev key to hold while speaking. F24 has no physical key on a
          normal keyboard, which is the point -- see `remapSuperSpace`.

          It also has no keysym in the default XKB keymap, so the compositor
          drops it instead of acting on it. Do not "fix" this back to F13:
          xkeyboard-config's inet(evdev) symbols map F13-F18 onto XF86Tools
          and XF86Launch5-9, and gnome-settings-daemon binds XF86Tools to
          launching Settings -- so every dictation also popped open the
          Settings window. F20-F23 are taken as well (mic mute, touchpad).
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

    # `nixos-rebuild switch` re-execs the user systemd and reruns this
    # activation, but switch-to-configuration never restarts a *user* service
    # whose definition changed. Without this the daemon keeps serving the
    # previous generation's config -- an old hotkey, an old model -- until the
    # next login, while keyd has already moved on.
    system.userActivationScripts.voxtype.text = ''
      # switch-to-configuration fires `systemctl --user daemon-reexec` without
      # waiting on it -- the user session sends no Reloaded signal, so it has
      # nothing to wait for -- and then runs this activation. Restarting here
      # would race that reexec and hand systemd the *previous* generation's
      # unit. daemon-reload is synchronous over D-Bus, so it settles the new
      # unit definitions before anything below reads or restarts them.
      systemctl --user daemon-reload

      pid=$(systemctl --user show voxtype.service --property=MainPID --value 2>/dev/null || true)
      if [ -n "$pid" ] && [ "$pid" != 0 ]; then
        # The daemon names its config file on its command line. Restarting
        # unconditionally would drop an in-flight dictation and pay the model
        # reload on every switch, so only act when that path actually moved.
        if ! tr '\0' '\n' < /proc/"$pid"/cmdline | grep -qxF ${configFile}; then
          systemctl --user restart voxtype.service
        fi
      fi
    '';

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

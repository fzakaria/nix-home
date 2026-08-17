# The user half of Omarchy: the Hyprland config tree, the active theme, and
# the runtime state Omarchy writes into $HOME while a session runs.
#
# The system half -- compositor, greeter, boot splash, fonts, packages -- is
# modules/nixos/omarchy.nix. The two are separate because they are owned by
# different configurations: only the machine can enable a display manager, and
# only a user can say which theme their desktop wears.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.omarchy;

  # The tree root Omarchy resolves its own data against. Every script and Lua
  # module derives its paths from this one value.
  omarchyPath = "${cfg.package}/${cfg.package.omarchyPath}";

  # The active theme, rendered from its colors.toml at build time rather than
  # by `omarchy-theme-set` at login. See pkgs/omarchy/theme.nix for why.
  themePackage = pkgs.callPackage ../../pkgs/omarchy/theme.nix {} cfg.package cfg.theme;

  # Directories under Omarchy's config/ that are safe to install by default.
  # Deliberately absent: git, tmux, starship, the terminal emulators and
  # chromium. Anyone already configuring those through home-manager would get
  # two owners for one file, which is an activation error.
  defaultConfigDirs = [
    "hypr"
    "omarchy"
    "autostart"
    "hyprland-preview-share-picker"
    "fcitx5"
    "foot"
    "btop"
    "imv"
    "lazygit"
    "herdr"
    "obsidian"
    "xournalpp"
  ];

  configDirs = cfg.configDirs ++ cfg.extraConfigDirs;
in {
  options.programs.omarchy = {
    enable = mkEnableOption "the Omarchy user configuration";

    package = mkOption {
      type = types.package;
      default = pkgs.omarchy;
      defaultText = literalExpression "pkgs.omarchy";
      description = "The vendored Omarchy tree, as built by pkgs/omarchy.";
    };

    theme = mkOption {
      type = types.str;
      default = "tokyo-night";
      example = "everforest";
      description = ''
        Name of a theme directory under Omarchy's `themes/`, rendered into
        the active theme at build time. As of Omarchy 4 that is catppuccin,
        catppuccin-latte, ethereal, everforest, flexoki-light, gruvbox,
        hackerman, kanagawa, last-horizon, lumon, lupine, matte-black,
        miasma, nord, osaka-jade, retro-82, ristretto, rose-pine, solitude,
        tokyo-night, vantablack or white.

        Switching themes means changing this and rebuilding; `omarchy theme
        set` does not work against the read-only rendered theme.
      '';
    };

    configManagement = mkOption {
      type = types.enum ["declarative" "seed"];
      default = "declarative";
      description = ''
        How ~/.config/<dir> is populated.

        `declarative` links each file from the store, so the config is a
        property of the generation and editing it means editing this flake.
        `seed` copies the defaults in on first activation and then leaves
        them writable, which is how upstream's /etc/skel behaves and what
        Omarchy's own docs assume when they say to put personal overrides in
        ~/.config/hypr/bindings.lua.
      '';
    };

    configDirs = mkOption {
      type = types.listOf types.str;
      default = defaultConfigDirs;
      description = "Directories under Omarchy's `config/` to install.";
    };

    extraConfigDirs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["ghostty" "starship"];
      description = "Additional `config/` directories to install, appended to `configDirs`.";
    };
  };

  config = mkIf cfg.enable {
    # Omarchy reads ~/.config/hypr/*.lua as the user's own layer on top of
    # $OMARCHY_PATH/default/hypr, and ~/.config/omarchy for shell layout,
    # hooks and template overrides.
    xdg.configFile = mkIf (cfg.configManagement == "declarative") (
      genAttrs configDirs (dir: {
        source = "${omarchyPath}/config/${dir}";
        # File-by-file rather than one directory symlink, so a stray file
        # written into the directory at runtime does not collide with it.
        recursive = true;
      })
    );

    home.file = {
      # Hyprland loads the theme through `require("omarchy.current.theme.*")`
      # with ~/.local/state on its package.path, and the Quickshell bar reads
      # shell.toml out of the same directory.
      ".local/state/omarchy/current/theme".source = themePackage;
      ".local/state/omarchy/current/theme.name".text = cfg.theme;
    };

    home.activation = {
      # `seed` mode reproduces what Arch's /etc/skel gives a new user: copy
      # the defaults in once, then never touch them again.
      omarchySeedConfig = mkIf (cfg.configManagement == "seed") (
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          for dir in ${escapeShellArgs configDirs}; do
            target="$HOME/.config/$dir"
            [ -e "$target" ] && continue
            run mkdir -p "$target"
            run cp -rL --no-preserve=mode,ownership \
              ${escapeShellArg omarchyPath}/config/"$dir"/. "$target/"
          done
        ''
      );

      # Hyprland toggles (no-gaps, aspect ratio, per-device input disables)
      # are written by `omarchy-toggle-*` while the session runs, so they have
      # to stay mutable. Seed them once and leave them alone after that.
      omarchySeedToggles = lib.hm.dag.entryAfter ["writeBoundary"] ''
        toggles="$HOME/.local/state/omarchy/toggles/hypr"
        if [ ! -d "$toggles" ]; then
          run mkdir -p "$toggles"
          run cp -rL --no-preserve=mode,ownership \
            ${escapeShellArg omarchyPath}/default/hypr/toggles/. "$toggles/"
        fi
      '';

      # The wallpaper is a symlink Omarchy repoints as the user cycles
      # backgrounds, so it cannot be a store symlink. Point it at the theme's
      # first background only when nothing has claimed it yet.
      omarchyBackground = lib.hm.dag.entryAfter ["writeBoundary"] ''
        background="$HOME/.local/state/omarchy/current/background"
        if [ ! -e "$background" ]; then
          first=$(find ${escapeShellArg themePackage}/backgrounds \
            -type f -o -type l 2>/dev/null | sort | head -n1)
          if [ -n "$first" ]; then
            run mkdir -p "$(dirname "$background")"
            run ln -sfn "$first" "$background"
          fi
        fi
      '';
    };
  };
}

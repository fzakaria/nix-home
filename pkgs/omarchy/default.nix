# Omarchy, DHH's opinionated Hyprland desktop, repackaged for NixOS.
#
# Omarchy is ~93% portable already: of the 440 scripts in `bin/`, only 32
# reach for pacman or yay, and everything else resolves its own data through
# `$OMARCHY_PATH` (see `default/hypr/paths.lua`). So this derivation vendors
# the upstream tree into the store and points `OMARCHY_PATH` at it rather
# than reimplementing the shell, the Lua config tree or the themes in Nix.
# Reimplementing those would drift from upstream within a release.
#
# Omarchy already has a supported mechanism for running from a path other
# than /usr/share/omarchy -- `omarchy-dev-link` writes /etc/omarchy.conf,
# which `default/bash/env-bootstrap` sources. The NixOS module writes that
# same file, so the store path is picked up through Omarchy's own hook.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  src,
  version,
  # Interpreters and text tools every script in bin/ assumes are present.
  bash,
  coreutils,
  gnused,
  gawk,
  gnugrep,
  findutils,
  procps,
  util-linux,
  systemd,
}: let
  # Scripts that manage Arch packages, run migrations against a mutable
  # /usr/share/omarchy, or provision a fresh Arch install. On NixOS the
  # rebuild replaces all of it, and leaving the scripts on PATH would let a
  # user run something that half-works and leaves the system inconsistent.
  droppedScriptGlobs = [
    "omarchy-pkg-*"
    "omarchy-update*"
    "omarchy-migrate*"
    "omarchy-channel-*"
    "omarchy-version*"
    "omarchy-dev-*"
    "omarchy-install-*"
    "omarchy-remove-*"
    "omarchy-reinstall-*"
    "omarchy-provision-*"
    "omarchy-apply-*"
    "omarchy-setup-*"
    "omarchy-refresh-pacman"
    "omarchy-refresh-limine"
    "omarchy-upgrade-to-quattro"
    "omarchy-sudo-passwordless"
    "omarchy-snapshot*"
  ];

  # Trees that only make sense on an Arch install: the installer, the
  # per-user migration history, the bootloader and snapshot integration, and
  # the pacman hook directory.
  droppedTrees = [
    "install"
    "migrations"
    "test"
    "plans"
    "agents"
    ".github"
    "default/libalpm"
    "default/pacman"
    "default/limine"
    "default/snapper"
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "omarchy";
    inherit version src;

    nativeBuildInputs = [makeWrapper];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
            runHook preInstall

            # $OMARCHY_PATH is the root Omarchy resolves everything else against,
            # so the vendored tree keeps upstream's own layout underneath it.
            omarchyPath="$out/share/omarchy"
            mkdir -p "$omarchyPath"
            cp -r . "$omarchyPath/"
            chmod -R u+w "$omarchyPath"

            # Drop the Arch-only trees before anything else runs over the tree.
            ${lib.concatMapStringsSep "\n" (t: ''rm -rf "$omarchyPath/${t}"'') droppedTrees}

            # Drop the scripts that would drive pacman or rewrite the store.
            ${lib.concatMapStringsSep "\n" (g: ''rm -f "$omarchyPath"/bin/${g}'') droppedScriptGlobs}

            # Every script and Lua module falls back to the Arch install prefix when
            # /etc/omarchy.conf is absent. Rewrite that literal to the store path so
            # the tree is self-consistent even for the code paths that never read
            # the env bootstrap.
            grep -rlF /usr/share/omarchy "$omarchyPath" \
              | while read -r f; do
                substituteInPlace "$f" --replace-quiet /usr/share/omarchy "$omarchyPath"
              done

            # `omarchy-provision-first-run` and the migration notifier belong to the
            # Arch packaging's first-boot flow, which the NixOS module replaces with
            # declarative config. Autostart execs them on every login, so drop the
            # lines rather than leaving two failing execs in the session.
            substituteInPlace "$omarchyPath/default/hypr/autostart.lua" \
              --replace-quiet '  hl.exec_cmd("omarchy-provision-first-run")
      ' ""

            patchShebangs "$omarchyPath/bin"

            runHook postInstall
    '';

    # The scripts call each other by bare name and expect a full desktop
    # session on PATH. Suffixing (not prefixing) keeps the session's own PATH
    # authoritative, so the module's systemPackages supply the GUI tools while
    # these core utilities make a script usable outside a session too.
    postFixup = ''
      omarchyPath="$out/share/omarchy"
      mkdir -p "$out/bin"

      for script in "$omarchyPath"/bin/*; do
        [ -f "$script" ] || continue
        makeWrapper "$script" "$out/bin/$(basename "$script")" \
          --set-default OMARCHY_PATH "$omarchyPath" \
          --suffix PATH : "${lib.makeBinPath [
        bash
        coreutils
        gnused
        gawk
        gnugrep
        findutils
        procps
        util-linux
        systemd
      ]}:$omarchyPath/bin"
      done

      # `services.displayManager.sessionPackages` reads this location. Upstream
      # installs the same file to /usr/local/share/wayland-sessions.
      install -Dm644 "$omarchyPath/default/wayland-sessions/omarchy.desktop" \
        "$out/share/wayland-sessions/omarchy.desktop"

      # SDDM finds a theme by name under /run/current-system/sw/share/sddm
      # (the sddm module adds that to environment.pathsToLink), and the NixOS
      # plymouth module collects themes out of share/plymouth/themes. Both are
      # copied rather than symlinked: plymouth's initrd builder copies the tree
      # and rewrites paths inside it, and a symlink farm confuses that pass.
      mkdir -p "$out/share/sddm/themes" "$out/share/plymouth/themes"
      cp -r "$omarchyPath/default/sddm/omarchy" "$out/share/sddm/themes/omarchy"
      cp -r "$omarchyPath/default/plymouth" "$out/share/plymouth/themes/omarchy"
      chmod -R u+w "$out/share/sddm" "$out/share/plymouth"

      # omarchy.plymouth points ImageDir and ScriptFile at the Arch install
      # prefix. Rewrite them to this store path so the NixOS plymouth module's
      # own store-path-to-initrd-path fixup has something to match on.
      substituteInPlace "$out/share/plymouth/themes/omarchy/omarchy.plymouth" \
        --replace-quiet /usr/share/plymouth/themes "$out/share/plymouth/themes"

      # Upstream ships these as /usr/lib/systemd/user units. `systemd.packages`
      # in the module picks them up from lib/systemd/user; enabling them stays
      # the module's decision. The migration notifier goes with the migration
      # machinery the install phase already dropped.
      mkdir -p "$out/lib/systemd/user"
      for unit in "$omarchyPath"/default/systemd/user/*.service; do
        name=$(basename "$unit")
        [ "$name" = omarchy-migrate-notify.service ] && continue
        install -Dm644 "$unit" "$out/lib/systemd/user/$name"
      done

      # The units hardcode Arch's binary prefix. Omarchy's own commands live in
      # this derivation; everything else (systemctl, fcitx5, bt-agent,
      # pipewire, tailscale) comes from the system profile, which is also what
      # makes the tailscale unit's ConditionPathExists correctly inert when
      # tailscale is not installed.
      substituteInPlace "$out"/lib/systemd/user/*.service \
        --replace-quiet /usr/bin/omarchy- "$out/bin/omarchy-" \
        --replace-quiet /usr/bin/ /run/current-system/sw/bin/

      # Terminal preference list for xdg-terminal-exec, the web-app and
      # utility launchers, and their icons. All three are found through
      # XDG_DATA_DIRS once this package is in environment.systemPackages.
      mkdir -p "$out/share/xdg-terminal-exec"
      cp "$omarchyPath"/default/xdg-terminal-exec/*.list "$out/share/xdg-terminal-exec/"

      mkdir -p "$out/share/applications"
      cp "$omarchyPath"/applications/*.desktop "$out/share/applications/"

      mkdir -p "$out/share/icons/hicolor/256x256/apps"
      cp "$omarchyPath"/applications/icons/*.png \
        "$out/share/icons/hicolor/256x256/apps/"

      # Omarchy ships one icon font of its own for the shell and the bar.
      install -Dm644 "$omarchyPath/default/fonts/omarchy/omarchy.ttf" \
        "$out/share/fonts/truetype/omarchy.ttf"
    '';

    passthru = {
      # Consumers need the tree root, not the derivation root, and computing
      # it by hand at every call site invites a wrong path.
      omarchyPath = "share/omarchy";

      # `services.displayManager.sessionPackages` refuses a package that does
      # not declare which sessions it ships. The name is the basename of the
      # desktop entry installed under share/wayland-sessions.
      providedSessions = ["omarchy"];
    };

    meta = {
      description = "DHH's opinionated Hyprland desktop, vendored for NixOS";
      homepage = "https://omarchy.org";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  }

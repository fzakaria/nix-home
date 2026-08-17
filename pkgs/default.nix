# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
#
# `inputs` is threaded through from overlays/default.nix so a package can be
# built out of a flake input that is a plain source tree rather than a flake.
{
  pkgs,
  inputs,
}: {
  # DHH's Omarchy desktop, vendored from its upstream tree. The version file
  # is the same one upstream ships at $OMARCHY_PATH/version.
  omarchy = pkgs.callPackage ./omarchy {
    src = inputs.omarchy;
    version = pkgs.lib.removeSuffix "\n" (builtins.readFile "${inputs.omarchy}/version");
  };

  # Omarchy's own Qt Quick applications. These live in the omacom org rather
  # than in nixpkgs, and the Omarchy keybindings reference them by bare name
  # (SUPER+CTRL+Q for omacalc, SUPER+SHIFT+W for omawrite), so they have to be
  # on PATH for the desktop to be complete.
  omacut = pkgs.callPackage ./omarchy/oma-app.nix {} {
    pname = "omacut";
    version = "0.4.0";
    hash = "sha256-g6xtaj6XSkP4B49H6McLQXV2pK9y0i2MwSF8R341mxw=";
    description = "Dead-simple video length trimmer built with Qt Quick and ffmpeg";
    qtModules = [pkgs.qt6.qtmultimedia];
    runtimeInputs = [pkgs.ffmpeg];
    hasDesktopItem = true;
  };

  omacalc = pkgs.callPackage ./omarchy/oma-app.nix {} {
    pname = "omacalc";
    version = "0.2.2";
    hash = "sha256-I+WxkMz/2hCf4OpJKu99+30c0CxyxFD0M6eSLFDLs1I=";
    description = "Omarchy's simple calculator";
  };

  # ttfx backs Omarchy's screensaver; tensaku is the screenshot annotator its
  # capture and clipboard paths open. Both are plain Rust crates upstream, so
  # they are built here rather than pulled from a flake.
  ttfx = pkgs.callPackage ./omarchy/ttfx.nix {};

  # Tensaku is edition 2024 and pins rustc 1.95 in rust-toolchain.toml; the
  # 1.91 in nixpkgs 25.11 refuses the crate outright.
  tensaku = pkgs.callPackage ./omarchy/tensaku.nix {
    rustPlatform = pkgs.unstable.rustPlatform;
  };

  omawrite = pkgs.callPackage ./omarchy/oma-app.nix {} {
    pname = "omawrite";
    version = "0.5.0";
    hash = "sha256-yS3GOL/kc03qx4naWzUdSZwAYxMuCjvrgmhexpwjsfA=";
    description = "The essence of writing";
    hasDesktopItem = true;
  };
}

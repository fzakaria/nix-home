# Tensaku: the screenshot annotator Omarchy opens from its capture and
# clipboard paths (omarchy-capture-screenshot defaults OMARCHY_SCREENSHOT_EDITOR
# to tensaku-edit, and omarchy-clipboard-open execs it directly).
#
# A GTK4/libadwaita app via relm4, so it needs the usual GTK wrapping. The
# dependency list is upstream's own: the buildInputs come from the devShell in
# their flake.nix, the runtime depends from packaging/aur/PKGBUILD.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook4,
  installShellFiles,
  gtk4,
  gtk4-layer-shell,
  libadwaita,
  libepoxy,
  libGL,
  libxkbcommon,
  fontconfig,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "tensaku";
  version = "0.28.0";

  src = fetchFromGitHub {
    owner = "jondkinney";
    repo = "tensaku";
    rev = "v${finalAttrs.version}";
    hash = "sha256-rkLDfzGFonNghDspDDH6sLikOC/5TZtUCvIPHWtdLXI=";
  };

  cargoHash = "sha256-eFG6MhSnoPzwSX8FkK+qFOSCFsCJay8jiFAMeXgNrds=";

  # The feature that makes build.rs emit the man page and the shell
  # completions installed below. Upstream's PKGBUILD builds with it too.
  buildFeatures = ["ci-release"];

  nativeBuildInputs = [pkg-config wrapGAppsHook4 installShellFiles];

  buildInputs = [
    gtk4
    gtk4-layer-shell
    libadwaita
    libepoxy
    libGL
    libxkbcommon
    fontconfig
  ];

  # The `epoxy` and `fontconfig` crates resolve their libraries through dlopen
  # at runtime, where the linker's rpath does not reach.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libepoxy libGL fontconfig]}"
    )
  '';

  postInstall = ''
    # tensaku-edit is the wrapper Omarchy actually calls: Tensaku takes no
    # positional filename, so this supplies the flags. Upstream execs `tensaku`
    # by bare name, which assumes a session PATH; point it at this derivation
    # so it works from anywhere.
    install -Dm755 assets/tensaku-edit "$out/bin/tensaku-edit"
    substituteInPlace "$out/bin/tensaku-edit" \
      --replace-fail "exec tensaku \\" "exec $out/bin/tensaku \\"

    install -Dm644 dev.tensaku.Tensaku.desktop \
      "$out/share/applications/dev.tensaku.Tensaku.desktop"
    install -Dm644 assets/tensaku.svg \
      "$out/share/icons/hicolor/scalable/apps/dev.tensaku.Tensaku.svg"

    # build.rs writes the man page and completions only under the ci-release
    # feature, so tolerate their absence rather than failing on a rename.
    if [ -f man/tensaku.1 ]; then
      install -Dm644 man/tensaku.1 "$out/share/man/man1/tensaku.1"
    fi
    installShellCompletion --cmd tensaku \
      --bash completions/tensaku.bash \
      --fish completions/tensaku.fish \
      --zsh completions/_tensaku
  '';

  meta = {
    description = "Modern screenshot annotation tool for Wayland";
    homepage = "https://tensaku.dev";
    license = lib.licenses.mpl20;
    mainProgram = "tensaku";
    platforms = lib.platforms.linux;
  };
})

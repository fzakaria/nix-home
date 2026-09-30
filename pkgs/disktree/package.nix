# Adapted from the flake proposed upstream in
# https://github.com/tobi/disktree/pull/26, rewritten in nixpkgs style so it
# can be upstreamed (or dropped) once disktree lands in nixpkgs.
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  writableTmpDirAsHomeHook,
  addDriverRunpath,
  makeWrapper,
  fontconfig,
  freetype,
  libxkbcommon,
  wayland,
  vulkan-loader,
  libGL,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrandr,
  mesa,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "disktree";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "tobi";
    repo = "disktree";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HoJjSLQeLEK20SpEd40DakAwV6WTdtcWM779YCjI3Jk=";
  };

  cargoHash = "sha256-+IG75eHRo1+4Sg5dq+b77UWYLKQlqPH30WtAnND/Cbk=";

  # Only the application; building the whole workspace would also ship the
  # `xtask` development helper as a package binary.
  cargoBuildFlags = ["-p" "disktree-app"];

  nativeBuildInputs =
    [
      pkg-config
      rustPlatform.bindgenHook
      writableTmpDirAsHomeHook
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # Both used by postFixup: addDriverRunpath defines the
      # `addDriverRunpath` shell function, makeWrapper the `wrapProgram` one.
      addDriverRunpath
      makeWrapper
    ];

  # GPUI's Linux backends link and run against these; macOS needs no extras
  # because the Metal/AppKit crates come through objc2.
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    fontconfig
    freetype
    libxkbcommon
    wayland
    vulkan-loader
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
  ];

  # GPUI dlopens libvulkan, libEGL and libwayland-client at runtime and dlopen
  # ignores buildInputs, so add those libraries to RUNPATH. The Mesa driver
  # paths only matter on non-NixOS hosts; on NixOS the drivers under
  # /run/opengl-driver are found first and the suffixed paths are unused.
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${
      lib.makeLibraryPath [
        vulkan-loader
        libGL
        wayland
      ]
    } $out/bin/disktree
    addDriverRunpath $out/bin/disktree
    wrapProgram $out/bin/disktree \
      --suffix VK_ADD_DRIVER_FILES : ${mesa}/share/vulkan/icd.d \
      --suffix __EGL_VENDOR_LIBRARY_DIRS : ${mesa}/share/glvnd/egl_vendor.d \
      --suffix LIBGL_DRIVERS_PATH : ${mesa}/lib/dri
  '';

  # Matches upstream's `make install` on Linux: icon and desktop entry.
  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 assets/disktree.svg \
      $out/share/icons/hicolor/scalable/apps/disktree.svg
    mkdir -p $out/share/applications
    substitute packaging/disktree.desktop.in \
      $out/share/applications/disktree.desktop \
      --subst-var-by BINDIR $out/bin --subst-var-by VERSION "$version"
  '';

  # The `disktree-app` tests drive a real window harness and cannot run in the
  # build sandbox. The two skipped core tests read the host's macOS mount table.
  cargoTestFlags = ["-p" "disktree-core"];
  checkFlags = [
    "--skip=the_home_disk_on_macos_is_the_root_and_has_a_device"
    "--skip=this_macs_mount_table_is_read_without_proc"
  ];

  meta = {
    description = "GPUI treemap explorer for disk usage";
    homepage = "https://github.com/tobi/disktree";
    license = lib.licenses.mit;
    mainProgram = "disktree";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})

# Builder for Omarchy's own desktop applications: omacut, omacalc and
# omawrite, from the omacom organisation.
#
# The three are the same shape -- a Qt Quick app with a hand-written qmake
# .pro at the repo root, no INSTALLS rules, and a binary dropped next to the
# build directory -- so they share one builder rather than three files that
# would drift apart. Upstream's bin/build only picks a qmake and runs make,
# which is exactly what the qmake setup hook already does, so it is not used.
#
# Note the organisation is `omacom`, not `basecamp`: the Omarchy repo is under
# basecamp, but the applications it ships are not, and the URL in upstream's
# own PKGBUILD (omacom-io) is wrong.
{
  lib,
  stdenv,
  fetchFromGitHub,
  qt6,
  makeWrapper,
}: {
  pname,
  version,
  hash,
  description,
  # Qt modules beyond qtbase. quickcontrols2, quickdialogs2, printsupport and
  # widgets all live inside qtbase or qtdeclarative on Qt 6, so in practice
  # this only ever names qtmultimedia.
  qtModules ? [],
  # Programs the app shells out to at runtime, put on its PATH by the Qt
  # wrapper rather than left to whatever the session happens to provide.
  runtimeInputs ? [],
  # Upstream keeps the launcher and its icon in pkgbuild/ for the Arch
  # package. Not every app has them.
  hasDesktopItem ? false,
}:
stdenv.mkDerivation (finalAttrs: {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "omacom";
    repo = pname;
    rev = "v${version}";
    inherit hash;
  };

  nativeBuildInputs = [qt6.qmake qt6.wrapQtAppsHook makeWrapper];
  buildInputs = [qt6.qtbase qt6.qtdeclarative] ++ qtModules;

  # The .pro files declare no INSTALLS, so `make install` is a no-op and the
  # binary has to be placed by hand.
  installPhase = ''
    runHook preInstall

    install -Dm755 ${pname} "$out/bin/${pname}"
    install -Dm644 LICENSE "$out/share/licenses/${pname}/LICENSE"

    ${lib.optionalString hasDesktopItem ''
      install -Dm644 "pkgbuild/${pname}.desktop" \
        "$out/share/applications/${pname}.desktop"
      install -Dm644 "pkgbuild/${pname}.svg" \
        "$out/share/icons/hicolor/scalable/apps/${pname}.svg"
    ''}

    runHook postInstall
  '';

  qtWrapperArgs = lib.optionals (runtimeInputs != []) [
    "--prefix PATH : ${lib.makeBinPath runtimeInputs}"
  ];

  meta = {
    inherit description;
    homepage = "https://github.com/omacom/${pname}";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = lib.platforms.linux;
  };
})

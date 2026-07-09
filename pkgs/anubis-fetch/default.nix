# anubis-fetch — the single entry point for fetching a URL from behind Anubis
# (which fronts lore.kernel.org, GNOME, kernel.org, ...).
#
# It tries the fast browserless solver (anubis-solve) first, and only drives a
# real headless Chromium (Playwright) when the solver escalates (exit 3): the
# preact/metarefresh challenge methods, an unknown/future method, a too-high
# difficulty, a rejected solution, or a Cloudflare active-JS wall. So you get the
# solver's speed on the common case and the browser's generality on the tail.
# See anubis_fetch.py.
#
# All CLI/arg handling lives in argparse; Nix only wraps the Python entrypoint to
# point it at anubis-solve, the system Chromium, and w3m (for --text).
{
  lib,
  stdenvNoCC,
  python3,
  chromium,
  w3m,
  anubis-solve,
  makeBinaryWrapper,
}: let
  pyEnv = python3.withPackages (ps: [ps.playwright]);
in
  stdenvNoCC.mkDerivation {
    pname = "anubis-fetch";
    version = "1.0";
    src = ./.;
    nativeBuildInputs = [makeBinaryWrapper];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 anubis_fetch.py $out/share/anubis-fetch/anubis_fetch.py
      makeWrapper ${pyEnv}/bin/python3 $out/bin/anubis-fetch \
        --add-flags $out/share/anubis-fetch/anubis_fetch.py \
        --set ANUBIS_SOLVE_BIN ${anubis-solve}/bin/anubis-solve \
        --set CHROMIUM_BIN ${chromium}/bin/chromium \
        --prefix PATH : ${lib.makeBinPath [w3m]}
      runHook postInstall
    '';
    meta = {
      description = "Fetch a URL from behind Anubis: browserless solver first, headless Chromium fallback";
      license = lib.licenses.mit;
      mainProgram = "anubis-fetch";
    };
  }

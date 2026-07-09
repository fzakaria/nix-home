# anubis-solve — the fast, browserless way past Anubis' proof-of-work wall.
#
# It fetches over curl_cffi (curl-impersonate: forges a Chrome TLS/JA3 + HTTP2
# fingerprint, so it also clears Cloudflare-style *passive* bot detection),
# parses the Anubis challenge, and solves the SHA-256 proof-of-work in-process.
# At Anubis' default difficulty this is ~4x faster than a headless browser and
# needs no Chromium closure.
#
# Standalone utility: it has no browser and no dependency on anubis-fetch. When
# the fast path can't apply (preact/metarefresh, unknown method, too-high
# difficulty, a rejected solution) it exits 3 and prints nothing to stdout — the
# caller (anubis-fetch) decides whether to escalate to a real browser.
{
  lib,
  stdenvNoCC,
  python3,
  w3m,
  makeBinaryWrapper,
}: let
  pyEnv = python3.withPackages (ps: [ps.curl-cffi]);
in
  stdenvNoCC.mkDerivation {
    pname = "anubis-solve";
    version = "1.0";
    src = ./.;
    nativeBuildInputs = [makeBinaryWrapper];
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 anubis_solve.py $out/share/anubis-solve/anubis_solve.py
      makeWrapper ${pyEnv}/bin/python3 $out/bin/anubis-solve \
        --add-flags $out/share/anubis-solve/anubis_solve.py \
        --prefix PATH : ${lib.makeBinPath [w3m]}
      runHook postInstall
    '';
    meta = {
      description = "Fetch a URL from behind Anubis by solving its proof-of-work in-process (browserless)";
      license = lib.licenses.mit;
      mainProgram = "anubis-solve";
    };
  }

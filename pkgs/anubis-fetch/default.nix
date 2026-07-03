# anubis-fetch — fetch a URL from behind a JavaScript proof-of-work bot-wall
# (notably Anubis, which fronts lore.kernel.org, GNOME, kernel.org, ...) so the
# challenge resolves on its own and you get the real page.
#
# Plain `curl`/WebFetch just receive Anubis' 403 "Access Denied" page. Even a
# one-shot `chromium --dump-dom` is unreliable: Anubis solves its proof-of-work
# asynchronously in a web worker and then reloads to the real content, so the
# dump races the solve. Instead we drive Chromium with Playwright and *wait*
# for the interstitial's marker scripts to disappear. The system Chromium is
# reused via executable_path, so no separate Playwright browser is downloaded.
{
  lib,
  writeShellApplication,
  python3,
  chromium,
  w3m,
  coreutils,
  gnugrep,
}: let
  pyEnv = python3.withPackages (ps: [ps.playwright]);
in
  writeShellApplication {
    name = "anubis-fetch";
    runtimeInputs = [pyEnv chromium w3m coreutils gnugrep];
    text = ''
      # System Chromium for Playwright to drive (no bundled browser download).
      export CHROMIUM_BIN="${chromium}/bin/chromium"

      timeout=30000
      ua=""
      as_text=0

      usage() {
        cat >&2 <<'EOF'
      Usage: anubis-fetch [--text] [--timeout MS] [--ua STRING] URL

      Fetch URL through a headless browser, waiting for Anubis (and similar
      proof-of-work interstitials) to resolve. Prints the settled page HTML to
      stdout, or readable plain text with --text.
      EOF
      }

      pyargs=()
      while [ $# -gt 0 ]; do
        case "$1" in
          --text) as_text=1; shift ;;
          --timeout) timeout="$2"; shift 2 ;;
          --ua) ua="$2"; shift 2 ;;
          -h|--help) usage; exit 0 ;;
          --) shift; break ;;
          -*) echo "anubis-fetch: unknown option: $1" >&2; usage; exit 2 ;;
          *) break ;;
        esac
      done

      url="''${1:-}"
      if [ -z "$url" ]; then
        usage
        exit 2
      fi

      pyargs=(--timeout "$timeout")
      if [ -n "$ua" ]; then
        pyargs+=(--ua "$ua")
      fi

      html="$(python3 ${./anubis_fetch.py} "''${pyargs[@]}" -- "$url")"

      # Heuristic: warn (but still emit) if we clearly never got past Anubis.
      if printf '%s' "$html" | grep -q 'Protected by .*Anubis' \
         && printf '%s' "$html" | grep -qiE 'Access Denied|not a bot'; then
        echo "anubis-fetch: warning: still on an Anubis interstitial; try a larger --timeout or a different --ua." >&2
      fi

      if [ "$as_text" -eq 1 ]; then
        printf '%s' "$html" | w3m -dump -T text/html
      else
        printf '%s\n' "$html"
      fi
    '';
    meta = {
      description = "Fetch a URL from behind Anubis' proof-of-work wall via headless Chromium";
      license = lib.licenses.mit;
      mainProgram = "anubis-fetch";
    };
  }

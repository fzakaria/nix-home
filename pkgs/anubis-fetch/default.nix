# anubis-fetch — fetch a URL through a *real* headless browser so that
# JavaScript proof-of-work interstitials (notably Anubis, the bot-blocker in
# front of lore.kernel.org, GNOME, kernel.org, etc.) resolve on their own.
#
# Plain `curl`/WebFetch get a 403 "Access Denied" page from Anubis. A headless
# Chromium that (a) advertises a normal browser User-Agent — Anubis outright
# DENYs UAs containing "HeadlessChrome" — and (b) is given a virtual-time budget
# long enough to run the PoW web worker and follow the resulting reload will
# instead land on the real page. `--dump-dom` then prints the settled DOM.
{
  lib,
  writeShellApplication,
  chromium,
  w3m,
  coreutils,
  gnugrep,
}:
writeShellApplication {
  name = "anubis-fetch";
  runtimeInputs = [chromium w3m coreutils gnugrep];
  text = ''
    # A believable desktop-Chrome UA. The exact version matters little; what
    # matters is that it does NOT say "HeadlessChrome" (which Anubis blocks).
    ua="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
    # Virtual-time budget (ms). The PoW solve + reload happens within this
    # window; --dump-dom fires when it elapses. Bump it for harder challenges.
    timeout=30000
    as_text=0

    usage() {
      cat >&2 <<'EOF'
    Usage: anubis-fetch [--text] [--timeout MS] [--ua STRING] URL

    Fetch URL through headless Chromium, running its JavaScript so that Anubis
    (and similar proof-of-work interstitials) resolve automatically. Prints the
    settled page HTML to stdout, or readable plain text with --text.
    EOF
    }

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

    # Ephemeral profile so runs don't share cookies/cache and clean up after.
    profile="$(mktemp -d)"
    trap 'rm -rf "$profile"' EXIT

    html="$(chromium \
      --headless=new \
      --disable-gpu \
      --no-sandbox \
      --disable-dev-shm-usage \
      --no-first-run \
      --disable-extensions \
      --user-data-dir="$profile" \
      --user-agent="$ua" \
      --virtual-time-budget="$timeout" \
      --dump-dom "$url" 2>/dev/null)"

    # Heuristic: warn (but still emit) if we're clearly staring at Anubis.
    if printf '%s' "$html" | grep -q 'Protected by .*Anubis' \
       && printf '%s' "$html" | grep -qiE 'Access Denied|not a bot'; then
      echo "anubis-fetch: warning: still on an Anubis interstitial; the challenge may not have resolved (try a larger --timeout, or a different --ua)." >&2
    fi

    if [ "$as_text" -eq 1 ]; then
      printf '%s' "$html" | w3m -dump -T text/html
    else
      printf '%s\n' "$html"
    fi
  '';
  meta = {
    description = "Fetch a URL through headless Chromium, solving Anubis proof-of-work challenges";
    license = lib.licenses.mit;
    mainProgram = "anubis-fetch";
  };
}

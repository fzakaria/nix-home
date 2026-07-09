"""anubis-solve: fetch a URL from behind Anubis *without* a browser by solving
its SHA-256 proof-of-work in-process, over an impersonating HTTP client
(curl_cffi — which also clears Cloudflare-style passive TLS/JA3 fingerprinting).

At Anubis' default difficulty this is ~4x faster than driving a headless browser
(~0.6s vs ~2.2s) and needs no Chromium in the closure. This is a standalone,
browserless utility: when the fast path can't apply — challenge methods we don't
implement (preact, metarefresh), unrecognized/future methods, a difficulty high
enough that a single-threaded solve loses to a browser, or a rejected solution —
it exits with code `ESCALATE` (3) and writes nothing to stdout, leaving it to
the caller (anubis-fetch) to decide whether to escalate to a real browser.

Protocol (verified against Anubis 1.25.0 source + a live request capture):
  1. GET url. If it isn't an Anubis interstitial we already have the content.
  2. Parse <script id="anubis_challenge"> JSON -> {id, randomData, method,
     difficulty}.
  3. fast/slow: find nonce so hex(sha256(randomData + str(nonce))) starts with
     `difficulty` '0' characters. (Server verifies the identical construction.)
  4. GET /.within.website/x/cmd/anubis/api/pass-challenge with
     id/response/nonce/redir/elapsedTime -> sets the auth cookie, 302s to redir.
  5. The session follows the redirect carrying the cookie -> real content.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
from urllib.parse import urlencode, urlsplit, urlunsplit

from curl_cffi import requests

PASS_CHALLENGE_PATH = "/.within.website/x/cmd/anubis/api/pass-challenge"
SOLVABLE_METHODS = {"fast", "slow"}
# Above this, Anubis' in-browser solver (parallel workers, native crypto) beats
# a single-threaded Python loop; signal the caller to use a browser instead.
MAX_DIFFICULTY = 5
# Exit code meaning "I can't solve this in-process; escalate to a browser".
ESCALATE = 3

_CHALLENGE_RE = re.compile(
    r'<script id="anubis_challenge" type="application/json">(.*?)</script>',
    re.DOTALL,
)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        prog="anubis-solve",
        description="Fetch URL from behind Anubis by solving its proof-of-work "
        "in-process (no browser); falls back to anubis-fetch when needed.",
    )
    ap.add_argument("url")
    ap.add_argument("--timeout", type=int, default=30000, metavar="MS",
                    help="network timeout in milliseconds (default: 30000)")
    ap.add_argument("--ua", default=None, metavar="STRING",
                    help="override User-Agent (default: curl_cffi's Chrome UA)")
    ap.add_argument("--text", action="store_true",
                    help="render readable plain text (via w3m) instead of HTML")
    return ap.parse_args()


def is_anubis(html: str) -> bool:
    return 'id="anubis_challenge"' in html or 'id="anubis_version"' in html


def parse_challenge(html: str) -> dict | None:
    m = _CHALLENGE_RE.search(html)
    if not m:
        return None
    raw = m.group(1).strip()
    if not raw or raw == "null":
        return None
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return None
    challenge = data.get("challenge") or {}
    rules = data.get("rules") or {}
    method = challenge.get("method") or rules.get("algorithm")
    difficulty = challenge.get("difficulty") or rules.get("difficulty")
    random_data = challenge.get("randomData")
    cid = challenge.get("id")
    if not (method and difficulty and random_data and cid):
        return None
    return {
        "method": method,
        "difficulty": int(difficulty),
        "randomData": random_data,
        "id": cid,
    }


def solve_pow(random_data: str, difficulty: int) -> tuple[int, str]:
    """Mirror Anubis' verifier: sha256(randomData bytes || decimal-nonce bytes),
    hex-encoded, with `difficulty` leading '0' hex characters."""
    prefix = "0" * difficulty
    rd = random_data.encode()
    nonce = 0
    while True:
        digest = hashlib.sha256(rd + str(nonce).encode()).hexdigest()
        if digest.startswith(prefix):
            return nonce, digest
        nonce += 1


def render(html: str, as_text: bool) -> None:
    if as_text:
        proc = subprocess.run(
            ["w3m", "-dump", "-T", "text/html"],
            input=html, capture_output=True, text=True, check=False,
        )
        sys.stdout.write(proc.stdout)
    else:
        sys.stdout.write(html)


def main() -> int:
    args = parse_args()
    http_timeout = max(5, args.timeout // 1000)
    headers = {"User-Agent": args.ua} if args.ua else {}
    session = requests.Session()

    def get(url: str) -> str:
        return session.get(url, headers=headers, impersonate="chrome",
                           timeout=http_timeout, allow_redirects=True).text

    try:
        html = get(args.url)
    except Exception as exc:  # noqa: BLE001
        print(f"anubis-solve: HTTP error ({exc}); escalate to browser.",
              file=sys.stderr)
        return ESCALATE

    if not is_anubis(html):
        render(html, args.text)  # not walled, or already let through
        return 0

    challenge = parse_challenge(html)
    if challenge is None:
        reason = "could not parse the Anubis challenge (deny page or new format)"
    elif challenge["method"] not in SOLVABLE_METHODS:
        reason = f"challenge method {challenge['method']!r} not solvable in-process"
    elif challenge["difficulty"] > MAX_DIFFICULTY:
        reason = f"difficulty {challenge['difficulty']} too high for in-process solve"
    else:
        reason = None

    if reason is not None:
        print(f"anubis-solve: {reason}; escalate to browser.", file=sys.stderr)
        return ESCALATE
    assert challenge is not None  # reason is None only for a valid challenge

    t0 = time.perf_counter()
    nonce, response = solve_pow(challenge["randomData"], challenge["difficulty"])
    elapsed_ms = max(1, int((time.perf_counter() - t0) * 1000))

    params = urlencode({
        "id": challenge["id"],
        "response": response,
        "nonce": str(nonce),
        "redir": args.url,
        "elapsedTime": str(elapsed_ms),
    })
    parts = urlsplit(args.url)
    pass_url = urlunsplit((parts.scheme, parts.netloc, PASS_CHALLENGE_PATH,
                           params, ""))

    try:
        solved = get(pass_url)
    except Exception as exc:  # noqa: BLE001
        print(f"anubis-solve: pass-challenge error ({exc}); escalate to browser.",
              file=sys.stderr)
        return ESCALATE

    if is_anubis(solved):
        print("anubis-solve: solution rejected; escalate to browser.",
              file=sys.stderr)
        return ESCALATE

    render(solved, args.text)
    return 0


if __name__ == "__main__":
    sys.exit(main())

"""anubis-fetch: the single entry point for fetching a URL from behind Anubis.

Cheap path first: it runs the standalone browserless solver (anubis-solve),
which solves Anubis' SHA-256 proof-of-work in-process. Only if that can't apply
— the solver exits with code ESCALATE (preact/metarefresh challenge methods, an
unknown/future method, a too-high difficulty, a rejected solution, or a
Cloudflare active-JS wall) — does it fall back to driving headless Chromium
here, which runs whatever JS the site serves.

anubis-solve stays usable on its own as the small, fast, browserless utility;
this tool just adds the browser safety net on top. Pass --browser to skip the
solver and go straight to the browser.
"""

import argparse
import os
import subprocess
import sys

# Exit code anubis-solve uses for "can't solve in-process; escalate to browser".
ESCALATE = 3

DEFAULT_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
)


def parse_args() -> argparse.Namespace:
    ap = argparse.ArgumentParser(
        prog="anubis-fetch",
        description="Fetch URL from behind Anubis: try the browserless solver "
        "first, fall back to a headless browser for challenges it can't solve.",
    )
    ap.add_argument("url")
    ap.add_argument("--timeout", type=int, default=30000, metavar="MS",
                    help="per-step timeout in milliseconds (default: 30000)")
    ap.add_argument("--ua", default=None, metavar="STRING",
                    help="override User-Agent")
    ap.add_argument("--text", action="store_true",
                    help="render readable plain text (via w3m) instead of HTML")
    ap.add_argument("--browser", action="store_true",
                    help="skip the in-process solver; go straight to the browser")
    return ap.parse_args()


def try_solver(args: argparse.Namespace) -> int:
    """Run anubis-solve, inheriting stdout/stderr. It prints the page on success
    and nothing (only a stderr reason) when it escalates, so relaying its streams
    never double-renders."""
    cmd = [os.environ["ANUBIS_SOLVE_BIN"], args.url, "--timeout", str(args.timeout)]
    if args.ua:
        cmd += ["--ua", args.ua]
    if args.text:
        cmd.append("--text")
    return subprocess.run(cmd, check=False).returncode


def browser_fetch(url: str, timeout: int, ua: str) -> str:
    # Imported lazily so the common (solver) path never pays Playwright startup.
    from playwright.sync_api import sync_playwright

    chromium_path = os.environ["CHROMIUM_BIN"]
    with sync_playwright() as p:
        browser = p.chromium.launch(
            executable_path=chromium_path,
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"],
        )
        page = browser.new_context(user_agent=ua).new_page()
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=timeout)
            # The Anubis interstitial embeds these <script> tags; once the PoW
            # is solved the page reloads to the real content and they vanish.
            page.wait_for_function(
                "() => !document.getElementById('anubis_version') "
                "&& !document.getElementById('anubis_challenge')",
                timeout=timeout,
            )
            page.wait_for_load_state("networkidle", timeout=timeout)
        except Exception as exc:  # noqa: BLE001 - report and still dump the DOM
            print(f"anubis-fetch: challenge did not resolve: {exc}",
                  file=sys.stderr)
        html = page.content()
        browser.close()
    return html


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

    if not args.browser:
        rc = try_solver(args)
        if rc == 0:
            return 0  # solver handled it and already rendered to stdout
        if rc != ESCALATE:
            print(f"anubis-fetch: solver exited {rc}; trying the browser.",
                  file=sys.stderr)
        # else: expected escalation — the solver already explained on stderr.

    html = browser_fetch(args.url, args.timeout, args.ua or DEFAULT_UA)
    if 'id="anubis_version"' in html or "Making sure you" in html:
        print("anubis-fetch: warning: still on an Anubis interstitial; "
              "try a larger --timeout or a different --ua.", file=sys.stderr)
    render(html, args.text)
    return 0


if __name__ == "__main__":
    sys.exit(main())

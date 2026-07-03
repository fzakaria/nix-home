"""Fetch a URL with Playwright, waiting out an Anubis proof-of-work wall.

Anubis serves a challenge page whose scripts (``#anubis_version`` /
``#anubis_challenge``) run a proof-of-work in a web worker and then reload to
the real content. A one-shot ``chromium --dump-dom`` races that async solve; a
scripted browser that *waits* for the challenge markers to disappear is
reliable. We reuse the system Chromium via ``executable_path`` (no separate
Playwright browser download needed).
"""

import argparse
import os
import sys

from playwright.sync_api import sync_playwright

DEFAULT_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"
)


def main() -> int:
    ap = argparse.ArgumentParser(prog="anubis-fetch")
    ap.add_argument("url")
    ap.add_argument("--timeout", type=int, default=30000,
                    help="per-step timeout in milliseconds (default 30000)")
    ap.add_argument("--ua", default=DEFAULT_UA, help="User-Agent to present")
    args = ap.parse_args()

    chromium_path = os.environ["CHROMIUM_BIN"]

    with sync_playwright() as p:
        browser = p.chromium.launch(
            executable_path=chromium_path,
            headless=True,
            args=["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"],
        )
        page = browser.new_context(user_agent=args.ua).new_page()
        try:
            page.goto(args.url, wait_until="domcontentloaded",
                      timeout=args.timeout)
            # The Anubis interstitial embeds these <script> tags; once the PoW
            # is solved the page reloads to the real content and they vanish.
            # If the URL was never behind Anubis they're absent from the start,
            # so this resolves immediately.
            page.wait_for_function(
                "() => !document.getElementById('anubis_version') "
                "&& !document.getElementById('anubis_challenge')",
                timeout=args.timeout,
            )
            page.wait_for_load_state("networkidle", timeout=args.timeout)
        except Exception as exc:  # noqa: BLE001 - report and still dump the DOM
            print(f"anubis-fetch: challenge did not resolve: {exc}",
                  file=sys.stderr)
        sys.stdout.write(page.content())
        browser.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())

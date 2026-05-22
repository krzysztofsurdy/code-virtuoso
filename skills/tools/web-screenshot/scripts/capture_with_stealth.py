#!/usr/bin/env python3
"""Capture a webpage as a real user using Playwright headed + stealth patches.

Tier 1 of the anti-bot fallback ladder. Runs Playwright in headed (visible)
mode, applies the most common anti-automation patches, and saves a screenshot.
Cross-platform: macOS, Linux, Windows.

Why headed instead of headless:
    Many bot walls fire only when they detect headless Chrome (UA string,
    rendering quirks, missing window chrome). Headed Chromium driven by
    Playwright passes most fingerprint checks once the stealth patches are
    applied, and using the user's home IP defeats the datacenter-IP check
    that drives the rest of refusals.

Install (one-time):
    pipx install playwright           # or: pip install --user playwright
    playwright install chromium
    pipx inject playwright tf-playwright-stealth   # optional but recommended

Usage:
    python capture_with_stealth.py <url> <output.png> [options]

Options:
    --width N            viewport width (default 1280)
    --height N           viewport height (default 800)
    --full-page          capture the entire scrollable page
    --selector CSS       capture a single element matching the CSS selector
    --wait-for JS        JS expression that must return truthy before capture
    --wait MS            additional fixed wait in milliseconds (default 500)
    --no-stealth         skip stealth patches (faster, but more detectable)
    --user-agent STR     override the user agent
    --keep-browser-open  do not close the browser after capture (debug aid)
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path


REALISTIC_UA_BY_PLATFORM = {
    "darwin": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "linux": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "win32": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
}


def default_user_agent() -> str:
    return REALISTIC_UA_BY_PLATFORM.get(sys.platform, REALISTIC_UA_BY_PLATFORM["linux"])


def apply_stealth_patches(page) -> None:
    """Patch the most common detection signals.

    Order of preference:
      1. tf-playwright-stealth (community, multi-signal coverage)
      2. inline init script with the high-value patches

    Either works; the inline patch covers ~80% of consumer bot walls.
    """
    try:
        from tf_playwright_stealth import stealth_sync  # type: ignore[import-not-found]
        stealth_sync(page)
        return
    except ImportError:
        pass

    page.add_init_script(
        """
        // Hide automation flag.
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });

        // Realistic plugin list.
        Object.defineProperty(navigator, 'plugins', {
            get: () => [1, 2, 3, 4, 5]
        });

        // Realistic language list.
        Object.defineProperty(navigator, 'languages', {
            get: () => ['en-US', 'en']
        });

        // Patch chrome.runtime presence (real Chrome has this).
        window.chrome = window.chrome || { runtime: {} };

        // Permissions query consistency.
        const originalQuery = window.navigator.permissions && window.navigator.permissions.query;
        if (originalQuery) {
            window.navigator.permissions.query = (parameters) =>
                parameters.name === 'notifications'
                    ? Promise.resolve({ state: Notification.permission })
                    : originalQuery(parameters);
        }
        """
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="URL to capture")
    parser.add_argument("output", type=Path, help="Output path for the PNG")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=800)
    parser.add_argument("--full-page", action="store_true")
    parser.add_argument("--selector", help="CSS selector to capture instead of the page")
    parser.add_argument("--wait-for", help="JS expression that must return truthy before capture")
    parser.add_argument("--wait", type=int, default=500, help="Extra fixed wait in ms")
    parser.add_argument("--no-stealth", action="store_true")
    parser.add_argument("--user-agent", default=default_user_agent())
    parser.add_argument("--keep-browser-open", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        sys.stderr.write(
            "Playwright is not installed. Install with:\n"
            "    pipx install playwright && playwright install chromium\n"
        )
        return 2

    args.output.parent.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, args=["--start-maximized"])
        context = browser.new_context(
            viewport={"width": args.width, "height": args.height},
            user_agent=args.user_agent,
            locale="en-US",
            timezone_id="Europe/Berlin",
        )
        page = context.new_page()
        if not args.no_stealth:
            apply_stealth_patches(page)

        sys.stderr.write(f"Navigating to {args.url}...\n")
        page.goto(args.url, wait_until="load", timeout=45_000)

        if args.wait_for:
            sys.stderr.write(f"Waiting for: {args.wait_for}\n")
            page.wait_for_function(args.wait_for, timeout=30_000)

        if args.wait > 0:
            time.sleep(args.wait / 1000.0)

        if args.selector:
            sys.stderr.write(f"Capturing element: {args.selector}\n")
            page.locator(args.selector).screenshot(path=str(args.output), animations="disabled")
        else:
            sys.stderr.write(
                f"Capturing {'full page' if args.full_page else 'viewport'}...\n"
            )
            page.screenshot(
                path=str(args.output),
                full_page=args.full_page,
                animations="disabled",
            )

        sys.stderr.write(f"Saved: {args.output.resolve()}\n")

        if not args.keep_browser_open:
            context.close()
            browser.close()

    print(str(args.output.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main())

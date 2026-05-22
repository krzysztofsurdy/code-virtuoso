#!/usr/bin/env python3
"""Capture a webpage by attaching to the user's already-running Chrome.

Tier 2 of the anti-bot fallback ladder. The user's Chrome is a real browser
with the user's real cookies, real session, real IP, and real fingerprint -
no bot wall can distinguish it from manual browsing.

How it works:
    The user starts Chrome once with --remote-debugging-port=9222.
    This script connects via the Chrome DevTools Protocol (CDP), opens a
    new tab to the target URL in the user's existing window, captures, and
    closes the tab.

User must run Chrome with the debugging flag first:

    macOS:
        /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome \\
            --remote-debugging-port=9222

    Linux:
        google-chrome --remote-debugging-port=9222

    Windows:
        "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe" \\
            --remote-debugging-port=9222

Install (one-time):
    pipx install playwright

(Note: no `playwright install chromium` needed - we use the user's Chrome.)

Usage:
    python connect_to_running_chrome.py <url> <output.png> [options]

Options:
    --port N             CDP port (default 9222)
    --full-page          capture the full scrollable page
    --selector CSS       capture a single element
    --wait-for JS        JS expression that must return truthy before capture
    --wait MS            extra fixed wait in ms (default 500)
    --keep-tab           do not close the tab after capture
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="URL to capture")
    parser.add_argument("output", type=Path, help="Output path for the PNG")
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--full-page", action="store_true")
    parser.add_argument("--selector", help="CSS selector to capture")
    parser.add_argument("--wait-for", help="JS expression that must return truthy before capture")
    parser.add_argument("--wait", type=int, default=500, help="Extra fixed wait in ms")
    parser.add_argument("--keep-tab", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        sys.stderr.write(
            "Playwright is not installed. Install with: pipx install playwright\n"
        )
        return 2

    endpoint = f"http://127.0.0.1:{args.port}"
    args.output.parent.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        try:
            browser = p.chromium.connect_over_cdp(endpoint)
        except Exception as exc:
            sys.stderr.write(
                f"Could not connect to Chrome at {endpoint}: {exc}\n"
                "Make sure Chrome was started with --remote-debugging-port="
                f"{args.port}.\n"
            )
            return 3

        # Use the first existing context (the user's profile).
        context = browser.contexts[0] if browser.contexts else browser.new_context()
        page = context.new_page()

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

        if not args.keep_tab:
            page.close()
        # Do not close the browser - it belongs to the user.

    print(str(args.output.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main())

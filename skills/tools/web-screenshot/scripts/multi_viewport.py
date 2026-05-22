#!/usr/bin/env python3
"""Capture one URL at three standard viewport sizes (desktop, tablet, mobile).

Usage:
    python multi_viewport.py <url> --out <directory> [--reduced-motion]

Produces desktop.png, tablet.png, mobile.png in the output directory.
Requires: shot-scraper installed and `shot-scraper install` already run.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

VIEWPORTS = {
    "desktop": (1280, 800),
    "tablet": (768, 1024),
    "mobile": (393, 852),
}


def ensure_shot_scraper() -> None:
    if shutil.which("shot-scraper") is None:
        sys.stderr.write(
            "shot-scraper is not installed. Run: pip install shot-scraper && shot-scraper install\n"
        )
        sys.exit(2)


def capture(url: str, out_dir: Path, reduced_motion: bool) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for label, (width, height) in VIEWPORTS.items():
        output_path = out_dir / f"{label}.png"
        cmd = [
            "shot-scraper",
            url,
            "-o",
            str(output_path),
            "--width",
            str(width),
            "--height",
            str(height),
            "--wait-for",
            "document.fonts.ready",
        ]
        if reduced_motion:
            cmd.append("--reduced-motion")
        sys.stderr.write(f"Capturing {label} ({width}x{height}) -> {output_path}\n")
        subprocess.run(cmd, check=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="URL to capture")
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("screenshots"),
        help="Output directory (default: ./screenshots)",
    )
    parser.add_argument(
        "--reduced-motion",
        action="store_true",
        default=True,
        help="Disable CSS animations (default: enabled)",
    )
    return parser.parse_args()


def main() -> int:
    ensure_shot_scraper()
    args = parse_args()
    capture(args.url, args.out, args.reduced_motion)
    return 0


if __name__ == "__main__":
    sys.exit(main())

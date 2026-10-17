#!/usr/bin/env python3
"""Validate markdown hygiene and internal links.

Checks:
- Markdown lint (frontmatter, blank lines, trailing newline)
- Internal link checking (reference links in SKILL.md, README.md links)

Requires Python 3.9+ stdlib only.
Run from the repository root: python3 scripts/validate-markdown.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from validate_common import (
    AGENTS_DIR,
    REPO_ROOT,
    find_skill_files,
    error,
    ok,
    print_summary,
    rel,
    warn,
)


# ---------------------------------------------------------------------------
# 6. Markdown lint (basic)
# ---------------------------------------------------------------------------

def check_markdown_lint(skill_files: list[Path], agent_files: list[Path]) -> None:
    print("\n=== Markdown Lint ===")

    all_files = list(skill_files) + list(agent_files)

    for path in all_files:
        rp = rel(path)
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue

        # Must start with frontmatter
        if not text.startswith("---"):
            error(f"{rp}: file must start with frontmatter (---)")

        # No consecutive blank lines (more than 2 newlines in a row)
        if "\n\n\n" in text:
            error(f"{rp}: consecutive blank lines detected (more than 2 newlines in a row)")

        # Must end with a single newline
        if text and not text.endswith("\n"):
            error(f"{rp}: file must end with a newline")
        elif text.endswith("\n\n"):
            error(f"{rp}: file must end with a single newline, not multiple")

        if (
            text.startswith("---")
            and "\n\n\n" not in text
            and text.endswith("\n")
            and not text.endswith("\n\n")
        ):
            ok(f"{rp}: markdown lint OK")


# ---------------------------------------------------------------------------
# 7. Internal link checking
# ---------------------------------------------------------------------------

def check_internal_links(skill_files: list[Path]) -> None:
    print("\n=== Internal Link Checking ===")

    # Check reference links in SKILL.md files
    link_re = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")

    for path in skill_files:
        rp = rel(path)
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue

        links_checked = 0
        for match in link_re.finditer(text):
            target = match.group(2)
            # Skip external links, anchors, and platform-specific references
            if target.startswith(("http://", "https://", "#", "mailto:")):
                continue
            resolved = (path.parent / target.split("#", 1)[0]).resolve()
            if not resolved.exists():
                error(f"{rp}: broken link '{target}' (file not found)")
            else:
                links_checked += 1

        if links_checked > 0:
            ok(f"{rp}: {links_checked} internal link(s) verified")

    # Check README.md internal links
    readme = REPO_ROOT / "README.md"
    if readme.is_file():
        try:
            text = readme.read_text(encoding="utf-8")
        except Exception:
            text = ""

        links_checked = 0
        for match in link_re.finditer(text):
            target = match.group(2)
            if target.startswith(("http://", "https://", "#", "mailto:")):
                continue
            resolved = (readme.parent / target.split("#", 1)[0]).resolve()
            if not resolved.exists():
                error(f"README.md: broken link '{target}' (file not found)")
            else:
                links_checked += 1

        if links_checked > 0:
            ok(f"README.md: {links_checked} internal link(s) verified")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    skill_files = find_skill_files()
    agent_files = sorted(AGENTS_DIR.glob("*.md")) if AGENTS_DIR.is_dir() else []

    check_markdown_lint(skill_files, agent_files)
    check_internal_links(skill_files)

    return print_summary()


if __name__ == "__main__":
    sys.exit(main())

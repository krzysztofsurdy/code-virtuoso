#!/usr/bin/env python3
"""Validate skill frontmatter, name consistency, size limits, and reference files.

Checks:
- Skill frontmatter validation (required fields, description length, no model, user-invocable)
- Skill name consistency (name matches directory)
- SKILL.md size check (warn > 500, error > 1000)
- Reference file size check (warn > 700 lines per spec)

Requires Python 3.9+ stdlib only.
Run from the repository root: python3 scripts/validate-skills.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from validate_common import (
    SKILLS_DIR,
    error,
    ok,
    parse_frontmatter,
    print_summary,
    rel,
    warn,
)


# ---------------------------------------------------------------------------
# Skill frontmatter validation
# ---------------------------------------------------------------------------

def check_skill_frontmatter() -> list[Path]:
    print("\n=== Skill Frontmatter ===")
    skill_files = sorted(SKILLS_DIR.rglob("SKILL.md"))

    if not skill_files:
        warn("No SKILL.md files found in skills/")
        return []

    for path in skill_files:
        fm = parse_frontmatter(path)
        rp = rel(path)

        if fm is None:
            error(f"{rp}: missing or invalid YAML frontmatter")
            continue

        # Required fields
        for field in ("name", "description", "user-invocable"):
            if field not in fm:
                error(f"{rp}: missing required field '{field}'")

        # name must be non-empty string
        name = fm.get("name")
        if isinstance(name, str) and not name.strip():
            error(f"{rp}: 'name' must be a non-empty string")

        # description must be non-empty string, at least 50 chars
        desc = fm.get("description")
        if isinstance(desc, str):
            if not desc.strip():
                error(f"{rp}: 'description' must be a non-empty string")
            elif len(desc) < 50:
                error(f"{rp}: 'description' is {len(desc)} chars, minimum is 50")
        elif desc is not None:
            error(f"{rp}: 'description' must be a string")

        # user-invocable must be boolean
        ui = fm.get("user-invocable")
        if ui is not None and not isinstance(ui, bool):
            error(f"{rp}: 'user-invocable' must be boolean (true or false)")

        # Must NOT have model field
        if "model" in fm:
            error(f"{rp}: must not have a 'model' field (no provider-specific models)")

        if all(f in fm for f in ("name", "description", "user-invocable")):
            if isinstance(fm.get("user-invocable"), bool):
                ok(rp)

    return skill_files


# ---------------------------------------------------------------------------
# Skill name consistency
# ---------------------------------------------------------------------------

def check_skill_name_consistency(skill_files: list[Path]) -> None:
    print("\n=== Name Consistency ===")

    for path in skill_files:
        fm = parse_frontmatter(path)
        if fm is None or "name" not in fm:
            continue
        expected = path.parent.name
        actual = fm["name"]
        if actual != expected:
            error(f"{rel(path)}: name '{actual}' does not match directory name '{expected}'")
        else:
            ok(f"{rel(path)}: name matches directory")


# ---------------------------------------------------------------------------
# SKILL.md size check
# ---------------------------------------------------------------------------

def check_skill_size(skill_files: list[Path]) -> None:
    print("\n=== SKILL.md Size Check ===")

    for path in skill_files:
        rp = rel(path)
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue

        count = len(lines)
        if count > 1000:
            error(f"{rp}: {count} lines exceeds 1000 line limit")
        elif count > 500:
            warn(f"{rp}: {count} lines exceeds 500 line recommendation")
        else:
            ok(f"{rp}: {count} lines")


# ---------------------------------------------------------------------------
# Reference file size check
# ---------------------------------------------------------------------------

def check_reference_file_sizes() -> None:
    print("\n=== Reference File Size Check ===")

    ref_files = sorted(SKILLS_DIR.rglob("references/*.md"))

    if not ref_files:
        return

    over_limit = 0
    total = len(ref_files)

    for path in ref_files:
        rp = rel(path)
        try:
            count = len(path.read_text(encoding="utf-8").splitlines())
        except Exception:
            continue

        if count > 1400:
            warn(f"{rp}: {count} lines (2x over 700-line spec limit)")
            over_limit += 1
        elif count > 700:
            # Only warn for the worst offenders to avoid noise
            over_limit += 1

    if over_limit > 0:
        warn(f"{over_limit} of {total} reference files exceed 700-line spec limit")
    else:
        ok(f"All {total} reference files within 700-line spec limit")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    skill_files = check_skill_frontmatter()
    check_skill_name_consistency(skill_files)
    check_skill_size(skill_files)
    check_reference_file_sizes()

    return print_summary()


if __name__ == "__main__":
    sys.exit(main())

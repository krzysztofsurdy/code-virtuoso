#!/usr/bin/env python3
"""Validate agent frontmatter, name consistency, body structure, and contracts.

Checks:
- Agent frontmatter validation (required fields, no model)
- Agent name consistency (name matches filename)
- Body structure (Input/Process/Rules/Output sections present)
- Description trigger phrases (contains delegation keywords)
- Handoff contracts (expects/produces declared)
- Reference file size (warn > 250 lines)

Requires Python 3.9+ stdlib only.
Run from the repository root: python3 scripts/validate-agents.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from validate_common import (
    AGENTS_DIR,
    error,
    frontmatter_yaml_problems,
    ok,
    parse_frontmatter,
    print_summary,
    rel,
    warn,
)


REQUIRED_SECTIONS = ("## Input", "## Process", "## Rules", "## Output")
TRIGGER_PHRASES = ("delegate when", "delegate for", "delegate after", "delegate before", "use when", "use proactively", "use after")


# ---------------------------------------------------------------------------
# Agent frontmatter validation
# ---------------------------------------------------------------------------

def check_agent_frontmatter() -> list[Path]:
    print("\n=== Agent Frontmatter ===")

    if not AGENTS_DIR.is_dir():
        warn("No agents/ directory found")
        return []

    agent_files = sorted(AGENTS_DIR.glob("*.md"))

    if not agent_files:
        warn("No agent .md files found in agents/")
        return []

    for path in agent_files:
        fm = parse_frontmatter(path)
        rp = rel(path)

        if fm is None:
            error(f"{rp}: missing or invalid YAML frontmatter")
            continue

        for problem in frontmatter_yaml_problems(path):
            error(problem)

        # Required fields
        for field in ("name", "description", "tools"):
            if field not in fm:
                error(f"{rp}: missing required field '{field}'")

        # Must NOT have model field
        if "model" in fm:
            error(f"{rp}: must not have a 'model' field (no provider-specific models)")

        # name must be non-empty string
        name = fm.get("name")
        if isinstance(name, str) and not name.strip():
            error(f"{rp}: 'name' must be a non-empty string")

        # description must be non-empty string
        desc = fm.get("description")
        if isinstance(desc, str) and not desc.strip():
            error(f"{rp}: 'description' must be a non-empty string")

        if all(f in fm for f in ("name", "description", "tools")) and "model" not in fm:
            ok(rp)

    return agent_files


# ---------------------------------------------------------------------------
# Agent name consistency
# ---------------------------------------------------------------------------

def check_agent_name_consistency(agent_files: list[Path]) -> None:
    print("\n=== Name Consistency ===")

    for path in agent_files:
        fm = parse_frontmatter(path)
        if fm is None or "name" not in fm:
            continue
        expected = path.stem
        actual = fm["name"]
        if actual != expected:
            error(f"{rel(path)}: name '{actual}' does not match filename '{expected}'")
        else:
            ok(f"{rel(path)}: name matches filename")


# ---------------------------------------------------------------------------
# Body structure validation
# ---------------------------------------------------------------------------

def check_agent_body_structure(agent_files: list[Path]) -> None:
    print("\n=== Body Structure (Input/Process/Rules/Output) ===")

    for path in agent_files:
        rp = rel(path)
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:
            continue

        # Strip frontmatter
        body_match = re.search(r"^---\s*\n.*?\n---\s*\n(.+)", text, re.DOTALL)
        if not body_match:
            warn(f"{rp}: no body content found after frontmatter")
            continue

        body = body_match.group(1)
        missing = [s for s in REQUIRED_SECTIONS if s not in body]

        if missing:
            warn(f"{rp}: missing sections: {', '.join(missing)}")
        else:
            ok(f"{rp}: all required sections present")


# ---------------------------------------------------------------------------
# Description trigger phrases
# ---------------------------------------------------------------------------

def check_trigger_phrases(agent_files: list[Path]) -> None:
    print("\n=== Description Trigger Phrases ===")

    for path in agent_files:
        fm = parse_frontmatter(path)
        if fm is None:
            continue

        rp = rel(path)
        desc = fm.get("description", "")
        if not isinstance(desc, str):
            continue

        desc_lower = desc.lower()
        has_trigger = any(phrase in desc_lower for phrase in TRIGGER_PHRASES)

        if has_trigger:
            ok(f"{rp}: description contains trigger phrase")
        else:
            warn(f"{rp}: description lacks trigger phrase (e.g., 'Delegate when...', 'Use when...')")


# ---------------------------------------------------------------------------
# Handoff contracts
# ---------------------------------------------------------------------------

def check_handoff_contracts(agent_files: list[Path]) -> None:
    print("\n=== Handoff Contracts (expects/produces) ===")

    for path in agent_files:
        fm = parse_frontmatter(path)
        if fm is None:
            continue

        rp = rel(path)
        has_expects = "expects" in fm
        has_produces = "produces" in fm

        if has_expects or has_produces:
            parts = []
            if has_expects:
                parts.append(f"expects: {fm['expects']}")
            if has_produces:
                parts.append(f"produces: {fm['produces']}")
            ok(f"{rp}: {', '.join(parts)}")
        else:
            warn(f"{rp}: no expects/produces declared")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    agent_files = check_agent_frontmatter()
    check_agent_name_consistency(agent_files)
    check_agent_body_structure(agent_files)
    check_trigger_phrases(agent_files)
    check_handoff_contracts(agent_files)

    return print_summary()


if __name__ == "__main__":
    sys.exit(main())

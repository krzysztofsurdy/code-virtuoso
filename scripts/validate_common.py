"""Shared helpers for validation scripts.

Provides output formatting, frontmatter parsing, path helpers, and summary
printing used by all validate-*.py scripts.

Requires Python 3.9+ stdlib only.
"""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKETPLACE_PATH = REPO_ROOT / ".claude-plugin" / "marketplace.json"
SKILLS_DIR = REPO_ROOT / "skills"
AGENTS_DIR = REPO_ROOT / "agents"
PLUGINS_DIR = REPO_ROOT / "plugins"

errors: list[str] = []
warnings: list[str] = []


def ok(msg: str) -> None:
    print(f"  OK    {msg}")


def error(msg: str) -> None:
    print(f"  ERROR {msg}")
    errors.append(msg)


def warn(msg: str) -> None:
    print(f"  WARN  {msg}")
    warnings.append(msg)


def parse_frontmatter(path: Path) -> dict[str, object] | None:
    """Parse simple YAML frontmatter between --- markers.

    Handles scalar key-value pairs and simple list fields (like skills:).
    Returns None if no valid frontmatter found.
    """
    try:
        text = path.read_text(encoding="utf-8")
    except Exception as exc:
        error(f"{rel(path)}: cannot read file ({exc})")
        return None

    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return None

    raw = match.group(1)
    result: dict[str, object] = {}
    current_list_key: str | None = None

    for line in raw.splitlines():
        # Continuation of a list field
        if current_list_key is not None:
            list_match = re.match(r"^\s+-\s+(.+)$", line)
            if list_match:
                result[current_list_key].append(list_match.group(1).strip())  # type: ignore[union-attr]
                continue
            else:
                current_list_key = None

        # Key-value pair
        kv = re.match(r"^([A-Za-z_-]+)\s*:\s*(.*)$", line)
        if not kv:
            continue

        key = kv.group(1)
        value = kv.group(2).strip()

        # Boolean
        if value.lower() == "true":
            result[key] = True
        elif value.lower() == "false":
            result[key] = False
        # Empty value followed by list items
        elif value == "":
            result[key] = []
            current_list_key = key
        else:
            result[key] = value

    return result


def find_skill_files() -> list[Path]:
    """Return every SKILL.md in skills/ and in plugins/*/skills/."""
    found = list(SKILLS_DIR.rglob("SKILL.md"))
    found += PLUGINS_DIR.glob("*/skills/**/SKILL.md")
    return sorted(found)


def find_reference_files() -> list[Path]:
    """Return every skill reference file in skills/ and in plugins/*/skills/."""
    found = list(SKILLS_DIR.rglob("references/*.md"))
    found += PLUGINS_DIR.glob("*/skills/**/references/*.md")
    return sorted(found)


def rel(path: Path) -> str:
    """Return path relative to REPO_ROOT for display."""
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def print_summary() -> int:
    """Print summary and return exit code (0 = success, 1 = errors)."""
    print(f"\n=== Summary ===")
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")

    if errors:
        print("\nErrors:")
        for e in errors:
            print(f"  - {e}")
        return 1

    return 0

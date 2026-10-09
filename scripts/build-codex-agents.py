#!/usr/bin/env python3
"""Generate Codex custom agent files (codex/agents/*.toml) from agents/*.md.

Codex plugins cannot ship agents, so each agent is rendered as a TOML file that
users install into ~/.codex/agents/ or .codex/agents/ (see
scripts/install-codex-agents.sh). The agent body becomes developer_instructions.

Usage:
    python3 scripts/build-codex-agents.py          # write codex/agents/
    python3 scripts/build-codex-agents.py --check  # exit 1 if codex/agents/ is out of date

Requires Python 3.9+ stdlib only.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from validate_common import AGENTS_DIR, REPO_ROOT, parse_frontmatter

OUT_DIR = REPO_ROOT / "codex" / "agents"

WRITE_TOOLS = {"Edit", "Write"}
READ_ONLY_NOTE = "Do not modify files."
HOME_NOTE = (
    "CODE_VIRTUOSO_HOME is the directory where the installer copied the Code Virtuoso "
    "library (default ~/.codex/code-virtuoso). Paths written as ${CODE_VIRTUOSO_HOME}/... "
    "resolve against it."
)
FRONTMATTER = re.compile(r"^---\s*\n.*?\n---[ \t]*\n?", re.DOTALL)
UNSAFE_LITERAL = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


def basic_string(value: str) -> str:
    out = []
    for ch in value:
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\n")
        elif ch == "\t":
            out.append("\t")
        elif ord(ch) < 0x20 or ord(ch) == 0x7F:
            out.append(f"\\u{ord(ch):04x}")
        else:
            out.append(ch)
    return "".join(out)


def single_line(value: str) -> str:
    return '"' + basic_string(value).replace("\n", " ") + '"'


def multi_line(value: str) -> str:
    if "'''" not in value and not UNSAFE_LITERAL.search(value):
        return "'''\n" + value + "'''"
    return '"""\n' + basic_string(value) + '"""'


def is_read_only(tools: object) -> bool:
    names = {t.strip() for t in str(tools).split(",")}
    return not (names & WRITE_TOOLS)


def render_agent(path: Path) -> str:
    fm = parse_frontmatter(path)
    if fm is None or not fm.get("name") or not fm.get("description"):
        raise ValueError(f"{path}: missing frontmatter or name/description")

    text = path.read_text(encoding="utf-8")
    body = FRONTMATTER.sub("", text, count=1).strip("\n")
    uses_home = "${CLAUDE_PLUGIN_ROOT}" in body
    body = body.replace("${CLAUDE_PLUGIN_ROOT}", "${CODE_VIRTUOSO_HOME}")

    preamble = []
    if is_read_only(fm.get("tools", "")):
        preamble.append(READ_ONLY_NOTE)
    if uses_home:
        preamble.append(HOME_NOTE)
    instructions = "\n\n".join([*preamble, body]) + "\n"

    return (
        f"# generated from agents/{path.name}, do not edit\n"
        f"# regenerate with: python3 scripts/build-codex-agents.py\n"
        f"name = {single_line(str(fm['name']))}\n"
        f"description = {single_line(str(fm['description']))}\n"
        f"developer_instructions = {multi_line(instructions)}\n"
    )


def expected_outputs(agents_dir: Path) -> dict[str, str]:
    return {f"{p.stem}.toml": render_agent(p) for p in sorted(agents_dir.glob("*.md"))}


def build(agents_dir: Path, out_dir: Path) -> list[str]:
    expected = expected_outputs(agents_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, content in expected.items():
        (out_dir / name).write_text(content, encoding="utf-8")
    for stale in sorted(out_dir.glob("*.toml")):
        if stale.name not in expected:
            stale.unlink()
    return sorted(expected)


def check(agents_dir: Path, out_dir: Path) -> list[str]:
    expected = expected_outputs(agents_dir)
    problems = []
    for name, content in expected.items():
        target = out_dir / name
        if not target.is_file():
            problems.append(f"{name}: missing")
        elif target.read_text(encoding="utf-8") != content:
            problems.append(f"{name}: out of date")
    if out_dir.is_dir():
        problems += [f"{p.name}: no matching agent" for p in sorted(out_dir.glob("*.toml")) if p.name not in expected]
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--check", action="store_true", help="fail if the output is out of date")
    parser.add_argument("--agents-dir", type=Path, default=AGENTS_DIR)
    parser.add_argument("--out-dir", type=Path, default=OUT_DIR)
    args = parser.parse_args()

    if args.check:
        problems = check(args.agents_dir, args.out_dir)
        for problem in problems:
            print(f"  ERROR codex/agents/{problem}")
        if problems:
            print("Run: python3 scripts/build-codex-agents.py")
            return 1
        print("codex/agents is up to date")
        return 0

    for name in build(args.agents_dir, args.out_dir):
        print(f"  wrote {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

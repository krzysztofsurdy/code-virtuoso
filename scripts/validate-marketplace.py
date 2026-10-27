#!/usr/bin/env python3
"""Validate marketplace.json integrity, plugin naming, and orphan detection.

Checks:
- Marketplace JSON validity (valid JSON, required fields, paths exist)
- Self-contained plugins (source under plugins/ with its own plugin.json)
- Plugin naming convention
- Orphan detection (skills/agents not registered)

Requires Python 3.9+ stdlib only.
Run from the repository root: python3 scripts/validate-marketplace.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from validate_common import (
    AGENTS_DIR,
    MARKETPLACE_PATH,
    PLUGINS_DIR,
    REPO_ROOT,
    SKILLS_DIR,
    error,
    ok,
    parse_frontmatter,
    print_summary,
    rel,
    warn,
)

CONFLICTING_ENTRY_FIELDS = ("strict", "skills", "agents", "hooks", "version")

DEFAULT_COMPONENT_PATHS = ("agents", "commands", "workflows", "hooks/hooks.json")

PLUGIN_NAME_RE = re.compile(
    r"^([\w-]+-virtuoso|role-[\w-]+|agent-[\w-]+|tool-[\w-]+|code-virtuoso)$"
)


def plugin_base(plugin: dict) -> Path:
    """Return the directory that the entry's relative skill and agent paths resolve from."""
    source = plugin.get("source")
    if isinstance(source, str):
        return (REPO_ROOT / source).resolve()
    return REPO_ROOT


def self_contained_source(plugin: dict) -> Path | None:
    """Return the plugin directory when the entry points at its own plugin, else None.

    An entry whose source is a directory under plugins/ is a self-contained
    plugin that ships its own .claude-plugin/plugin.json. Entries that point at
    the repo root or at skills/ are bundles: the entry is the manifest.
    """
    if is_external_source(plugin):
        return None
    base = plugin_base(plugin)
    if base == PLUGINS_DIR or PLUGINS_DIR in base.parents:
        return base
    return None


def is_external_source(plugin: dict) -> bool:
    """True when the entry points at a plugin in another repo or registry.

    External sources are objects: {"source": "github"|"url"|"git-subdir"|"npm", ...}.
    The plugin's own files live in that other repo, so this validator cannot scan
    them and must not treat the entry as a repo-root bundle.
    """
    return isinstance(plugin.get("source"), dict)


def check_external_plugin(plugin: dict) -> None:
    pname = plugin.get("name", "<unnamed>")
    source = plugin["source"]
    kind = source.get("source")
    known = {"github", "url", "git-subdir", "npm"}
    if kind not in known:
        error(f"{pname}: unknown external source type '{kind}' (expected one of {', '.join(sorted(known))})")
        return
    conflicts = [f for f in CONFLICTING_ENTRY_FIELDS if f in plugin]
    if conflicts:
        error(
            f"{pname}: marketplace entry sets {', '.join(conflicts)} but points at an external "
            "plugin with its own manifest; remove them from the entry"
        )
        return
    ok(f"{pname}: external plugin ({kind})")


def check_self_contained_plugin(plugin: dict, plugin_dir: Path) -> None:
    pname = plugin.get("name", "<unnamed>")
    source = plugin["source"]

    if not plugin_dir.is_dir():
        error(f"{source} does not exist (source of {pname})")
        return

    manifest = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest.is_file():
        error(f"{source}/.claude-plugin/plugin.json does not exist (source of {pname})")
        return

    try:
        manifest_data = json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        error(f"{rel(manifest)} is not valid JSON: {exc}")
        return

    if manifest_data.get("name") != pname:
        error(f"{rel(manifest)}: name '{manifest_data.get('name')}' does not match marketplace entry '{pname}'")

    conflicts = [f for f in CONFLICTING_ENTRY_FIELDS if f in plugin]
    if conflicts:
        error(
            f"{pname}: marketplace entry sets {', '.join(conflicts)} but the plugin has its own "
            "plugin.json (conflicting manifests); remove them from the entry"
        )
    else:
        ok(f"{pname}: self-contained plugin at {source}")


# ---------------------------------------------------------------------------
# 1. Marketplace JSON validity
# ---------------------------------------------------------------------------

def load_marketplace() -> dict | None:
    """Load and return marketplace.json, or None on failure."""
    print("\n=== Marketplace JSON Validity ===")
    if not MARKETPLACE_PATH.exists():
        error("marketplace.json does not exist")
        return None
    try:
        data = json.loads(MARKETPLACE_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        error(f"marketplace.json is not valid JSON: {exc}")
        return None
    ok("marketplace.json is valid JSON")
    return data


def check_marketplace(data: dict) -> None:
    # Top-level fields
    for field in ("name", "metadata", "plugins"):
        if field not in data:
            error(f"marketplace.json: missing required top-level field '{field}'")
        else:
            ok(f"marketplace.json has '{field}'")

    metadata = data.get("metadata", {})
    if "version" not in metadata:
        error("marketplace.json: metadata missing 'version'")
    else:
        ok("marketplace.json metadata has 'version'")

    plugins = data.get("plugins", [])
    skill_count = 0
    agent_count = 0

    for plugin in plugins:
        pname = plugin.get("name", "<unnamed>")

        if is_external_source(plugin):
            check_external_plugin(plugin)
            continue

        plugin_dir = self_contained_source(plugin)
        if plugin_dir is not None:
            check_self_contained_plugin(plugin, plugin_dir)
            continue

        base = plugin_base(plugin)

        for spath in plugin.get("skills", []):
            resolved = base / spath
            skill_md = resolved / "SKILL.md"
            if not skill_md.is_file():
                error(f"{spath}/SKILL.md does not exist (referenced by {pname})")
            else:
                skill_count += 1

        for apath in plugin.get("agents", []):
            resolved = base / apath
            if not resolved.is_file():
                error(f"{apath} does not exist (referenced by {pname})")
            else:
                agent_count += 1

    ok(f"Checked {skill_count} skill path(s) and {agent_count} agent path(s)")
    check_default_component_scan(plugins)


def check_default_component_scan(plugins: list[dict]) -> None:
    """Each entry scans its source for agents/, commands/, workflows/, hooks/hooks.json.

    An entry's own `agents` list adds to that scan instead of replacing it, so
    two entries that share a source directory both register what it holds.
    """
    by_source: dict[Path, list[str]] = {}
    for plugin in plugins:
        if is_external_source(plugin):
            continue
        if self_contained_source(plugin) is None:
            by_source.setdefault(plugin_base(plugin), []).append(plugin.get("name", "<unnamed>"))

    for base, names in by_source.items():
        if len(names) < 2:
            continue
        for component in DEFAULT_COMPONENT_PATHS:
            if (base / component).exists():
                error(
                    f"{rel(base / component)} is scanned by {len(names)} entries sharing source "
                    f"{rel(base)} ({', '.join(names)}); give the entries different sources"
                )


# ---------------------------------------------------------------------------
# 5. Plugin naming convention
# ---------------------------------------------------------------------------

def check_plugin_naming(data: dict) -> None:
    print("\n=== Plugin Naming Convention ===")

    for plugin in data.get("plugins", []):
        pname = plugin.get("name", "")
        if PLUGIN_NAME_RE.match(pname):
            ok(f"plugin '{pname}' matches naming convention")
        else:
            error(
                f"plugin '{pname}' does not match naming convention "
                "(expected: {{word}}-virtuoso, role-{{word}}, agent-{{word}}, or tool-{{word}})"
            )


# ---------------------------------------------------------------------------
# 9. Orphan detection
# ---------------------------------------------------------------------------

def check_orphans(data: dict) -> None:
    print("\n=== Orphan Detection ===")

    # Collect all skill and agent paths referenced in any plugin
    referenced_skill_dirs: set[Path] = set()
    referenced_agent_paths: set[Path] = set()
    repo_auto_discovery = False

    for plugin in data.get("plugins", []):
        # External plugins live in another repo; nothing here references them.
        if is_external_source(plugin):
            continue
        # Self-contained plugins (own plugin.json) auto-discover inside their
        # own source directory only, so they never cover skills/ or agents/.
        if self_contained_source(plugin) is not None:
            continue

        skills_list = plugin.get("skills", [])
        agents_list = plugin.get("agents", [])
        base = plugin_base(plugin)

        # A repo-root entry with no explicit lists auto-discovers the whole repo
        if plugin.get("source") and not skills_list and not agents_list:
            repo_auto_discovery = True

        for spath in skills_list:
            resolved = (base / spath).resolve()
            referenced_skill_dirs.add(resolved)

        for apath in agents_list:
            resolved = (base / apath).resolve()
            referenced_agent_paths.add(resolved)

    skill_files = sorted(SKILLS_DIR.rglob("SKILL.md"))
    agent_files = sorted(AGENTS_DIR.glob("*.md")) if AGENTS_DIR.is_dir() else []

    if repo_auto_discovery:
        ok(f"Auto-discovery mode: found {len(skill_files)} skill(s) and {len(agent_files)} agent(s)")
        return

    # Check skill orphans
    for path in skill_files:
        skill_dir = path.parent.resolve()
        if skill_dir not in referenced_skill_dirs:
            error(f"{rel(path)}: skill directory not referenced in any plugin in marketplace.json")
        else:
            ok(f"{rel(path)}: registered in marketplace.json")

    # Check agent orphans
    for path in agent_files:
        resolved = path.resolve()
        if resolved not in referenced_agent_paths:
            error(f"{rel(path)}: agent not referenced in any plugin in marketplace.json")
        else:
            ok(f"{rel(path)}: registered in agents-virtuoso")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    data = load_marketplace()
    if data is not None:
        check_marketplace(data)
        check_plugin_naming(data)
        check_orphans(data)

    return print_summary()


if __name__ == "__main__":
    sys.exit(main())

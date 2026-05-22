---
name: plugin-creator
description: Interactive tool to scaffold a complete Claude Code plugin - plugin.json manifest, skills, agents, hooks, MCP servers, LSP servers, and an optional marketplace.json catalog entry. Use when the user asks to create a plugin, build a Claude Code plugin, scaffold a plugin marketplace, convert an existing .claude/ configuration into a plugin, or package skills and agents for distribution. Runs a guided questionnaire, writes all required files to disk, and prints test instructions.
user-invocable: true
argument-hint: "[optional: plugin-name]"
---

# Plugin Creator

Scaffold a well-formed Claude Code plugin with exactly the components the user wants - no more, no less. A plugin is a self-contained directory with a manifest (`.claude-plugin/plugin.json`) plus any of: skills, agents, hooks, MCP servers, LSP servers, bin executables, output styles, default settings. This tool generates the correct structure, writes a valid manifest, adds a marketplace entry when requested, and explains how to test locally with `--plugin-dir`.

## Core Principles

| Principle | Meaning |
|---|---|
| **Manifest is optional, but recommended** | If omitted, the directory name becomes the plugin name and components auto-discover at default locations. Provide one whenever metadata, versioning, or custom paths matter. |
| **Default locations first** | Prefer `skills/`, `agents/`, `hooks/hooks.json`, `.mcp.json`, `.lsp.json` at plugin root. Only override paths in `plugin.json` when there is a real reason. |
| **Components live at the root, not in `.claude-plugin/`** | Only `plugin.json` belongs inside `.claude-plugin/`. Everything else (`skills/`, `agents/`, etc.) is at the plugin root. This is the single most common mistake. |
| **Use `${CLAUDE_PLUGIN_ROOT}` for every plugin-internal path** | Absolute paths break when the plugin is cached. `${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin directory at runtime. Use `${CLAUDE_PLUGIN_DATA}` for state that must survive updates. |
| **Namespacing is automatic** | Plugin skills are always invoked as `/plugin-name:skill-name`. Names are derived from the `name` field in `plugin.json` (or directory name if no manifest). |
| **Semantic versioning in one place** | Set `version` in `plugin.json` OR in the marketplace entry - not both. When present in both, `plugin.json` wins. |

---

## Workflow

This skill uses **guided phases** - each phase is a separate file loaded one at a time. Every phase ends with a gate where you must wait for user confirmation before proceeding. Do not skip phases or merge them.

If the user aborts at any phase, discard progress and exit without writing a partial plugin.

| Phase | File | What it covers |
|---|---|---|
| 1 | [Plugin Identity](phases/01-plugin-identity.md) | Name, description, version, author, optional metadata |
| 2 | [Component Selection](phases/02-component-selection.md) | Which component types to include (skills, agents, hooks, etc.) |
| 3 | [Component Details](phases/03-component-details.md) | Per-component sub-questionnaires (skills, agents, hooks, MCP, LSP, bin, styles, settings) |
| 4 | [Distribution](phases/04-distribution.md) | Standalone, new marketplace, or add to existing marketplace |
| 5 | [Write Files](phases/05-write-files.md) | Validate, confirm, write all files to disk |
| 6 | [Test Instructions](phases/06-test-instructions.md) | Test commands, reload, validation, next steps |

**Start by loading Phase 1.** After the user confirms each phase, load the next. Never load multiple phases at once. Never skip a phase.

---

## Rules & Guardrails

- **Never put components inside `.claude-plugin/`**. Only `plugin.json` lives there.
- **Never use absolute paths** in `plugin.json`, hooks, or MCP configs. All plugin-internal paths must start with `./` or use `${CLAUDE_PLUGIN_ROOT}`.
- **Never reference files outside the plugin directory** via `../` - the plugin cache will not copy them. Symlinks are preserved, so use those if cross-plugin sharing is truly needed.
- **Never set `hooks`, `mcpServers`, or `permissionMode` on a plugin-shipped agent** - these are blocked for security.
- **Never set both `version` in `plugin.json` and in the marketplace entry.** Pick one authoritative location.
- **Always bump the version when the plugin content changes.** The Claude Code cache uses the version to decide whether to update. Forgetting this is why users do not see plugin updates.
- **Reject reserved marketplace names** (`claude-code-marketplace`, `anthropic-marketplace`, etc. - full list in [references/marketplace-manifest.md](references/marketplace-manifest.md)).
- **Validate JSON before writing**. A corrupt `plugin.json` breaks the plugin silently in some cases and loudly in others - both waste the user's time.

---

## Quick Reference: Minimal Plugin

The smallest valid plugin is a directory with one SKILL.md:

```
my-plugin/
└── skills/
    └── hello/
        └── SKILL.md
```

No `plugin.json` is required - the directory name becomes the plugin name. Add a manifest only when you need metadata, versioning, or custom paths.

---

## Reference Files

| Reference | Contents |
|---|---|
| [plugin-manifest.md](references/plugin-manifest.md) | Complete `plugin.json` schema: required + metadata + component path fields, `userConfig`, `channels`, path behavior rules, `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` usage. |
| [marketplace-manifest.md](references/marketplace-manifest.md) | Complete `marketplace.json` schema: owner, plugins array, all source types (relative, github, url, git-subdir, npm), strict mode, reserved names. |
| [component-templates.md](references/component-templates.md) | Ready-to-use templates for `plugin.json`, `SKILL.md`, agent files, `hooks/hooks.json`, `.mcp.json`, `.lsp.json`, `settings.json`, `bin/` scripts, and output styles. |
| [distribution.md](references/distribution.md) | Hosting options (git hosts, local, URL, npm), semantic versioning, release workflow, auto-update behavior, team marketplace configuration via `extraKnownMarketplaces`. |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Creating the actual skill content inside a plugin | `skill-creator` |
| Writing the agent body for a plugin-shipped agent | Check existing agent definitions in `agents/` for patterns |
| Generating rules files to pair with a plugin | `agentic-rules-writer` |
| Writing tickets for plugin-related backlog items | `ticket-writer` |

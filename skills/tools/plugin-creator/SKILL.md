---
name: plugin-creator
description: Interactive tool to scaffold a Claude Code plugin with plugin.json, skills, agents, workflows, hooks, MCP servers, and an optional marketplace entry. Use when asked to create a plugin, convert .claude/ configuration into a plugin, or package skills and agents for distribution.
user-invocable: true
argument-hint: "[optional: plugin-name]"
---

# Plugin Creator

Scaffold a well-formed Claude Code plugin with exactly the components the user wants, no more and no fewer. A plugin is a self-contained directory with a manifest (`.claude-plugin/plugin.json`) plus any of: skills, agents, commands, workflows, hooks, MCP servers, LSP servers, bin executables, output styles, default settings. This tool generates the correct structure, writes a valid manifest, adds a marketplace entry when requested, and explains how to test locally with `--plugin-dir`.

## Core Principles

| Principle | Meaning |
|---|---|
| **Manifest is optional but recommended** | If omitted, the directory name becomes the plugin name and components auto-discover at default locations. A marketplace entry without a `plugin.json` is itself the manifest and accepts every `plugin.json` field. Provide a manifest whenever metadata, versioning, or custom paths matter. |
| **Default locations first** | Prefer `skills/`, `agents/`, `hooks/hooks.json`, `.mcp.json`, `.lsp.json` at plugin root. Override paths in `plugin.json` only when there is a real reason. |
| **Components live at the root, not in `.claude-plugin/`** | Only `plugin.json` belongs inside `.claude-plugin/`. Everything else (`skills/`, `agents/`, etc.) is at the plugin root. This is the most common mistake. |
| **Use `${CLAUDE_PLUGIN_ROOT}` for every plugin-internal path** | Absolute paths break when the plugin is cached. `${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin directory at runtime. Use `${CLAUDE_PLUGIN_DATA}` only for disposable caches: it survives updates but is deleted on uninstall. |
| **Namespacing is automatic** | Plugin skills are always invoked as `/plugin-name:skill-name`. The plugin name comes from the `name` field in `plugin.json` (or the directory name if there is no manifest). |
| **Semantic versioning in one place** | Set `version` in `plugin.json` or in the marketplace entry, not both. When it is in both, `plugin.json` wins. With no version anywhere, the commit SHA is the version, so every commit is an update. |

---

## Workflow

This skill runs in guided phases. Each phase is a separate file, loaded one at a time. Every phase ends with a gate: wait for user confirmation before you proceed. Do not skip phases or merge them.

If the user aborts at any phase, discard progress and exit without writing a partial plugin.

| Phase | File | What it covers |
|---|---|---|
| 1 | [Plugin identity](phases/01-plugin-identity.md) | Name, description, version, author, optional metadata |
| 2 | [Component selection](phases/02-component-selection.md) | Which component types to include (skills, agents, hooks, etc.) |
| 3 | [Component details](phases/03-component-details.md) | Per-component sub-questionnaires (skills, agents, hooks, MCP, LSP, bin, styles, settings) |
| 4 | [Distribution](phases/04-distribution.md) | Standalone, new marketplace, or add to existing marketplace |
| 5 | [Write files](phases/05-write-files.md) | Validate, confirm, write all files to disk |
| 6 | [Test instructions](phases/06-test-instructions.md) | Test commands, reload, validation, next steps |

Start by loading Phase 1. After the user confirms each phase, load the next. Never load more than one phase at a time, and never skip one.

---

## Rules and guardrails

- **Never put components inside `.claude-plugin/`**. Only `plugin.json` lives there.
- **Never use absolute paths** in `plugin.json`, hooks, or MCP configs. All plugin-internal paths must start with `./` or use `${CLAUDE_PLUGIN_ROOT}`.
- **Never reference files outside the plugin directory** via `../`, because the plugin cache does not copy them. Symlinks are preserved, so use those if you need to share files across plugins.
- **Never set `hooks`, `mcpServers`, or `permissionMode` on a plugin-shipped agent**. These are ignored for security. Put hooks in `hooks/hooks.json` and MCP servers in `.mcp.json`.
- **Never keep user or project choices in `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_DATA}`**. The root is replaced on every update, the data directory is deleted on uninstall (unless `claude plugin uninstall --keep-data`), and neither is set in the Bash tool environment. Use the layered config described in [plugin-manifest.md](references/plugin-manifest.md#persistent-user-and-project-choices).
- **Do not point several marketplace entries at the repository root by accident.** Each `"./"` entry registers the root `agents/`, `commands/`, `workflows/`, and `hooks/hooks.json`, so a second one duplicates them. Use a narrower source such as `"./skills"` for a skill-only bundle. `"agents": []` does not stop the scan.
- **Never set both `version` in `plugin.json` and in the marketplace entry.** Pick one authoritative location.
- **Always bump the version when the plugin content changes.** The Claude Code cache uses the version to decide whether to update. If the version is not bumped, users do not see the update.
- **Reject reserved marketplace names** (`claude-code-marketplace`, `anthropic-marketplace`, etc.; full list in [references/marketplace-manifest.md](references/marketplace-manifest.md)).
- **Validate JSON before writing**. A corrupt `plugin.json` breaks the plugin, sometimes silently and sometimes with an error, and either way wastes the user's time.

---

## Quick reference: minimal plugin

The smallest valid plugin is a directory with one SKILL.md:

```
my-plugin/
└── skills/
    └── hello/
        └── SKILL.md
```

No `plugin.json` is required, and the directory name becomes the plugin name. Add a manifest only when you need metadata, versioning, or custom paths.

---

## Facts to apply when scaffolding

Checked against the Claude Code plugin docs. Details are in the reference files.

| Topic | Fact |
|---|---|
| Entry without `plugin.json` | The marketplace entry accepts every `plugin.json` field: `skills`, `commands`, `agents`, `workflows`, an inline `hooks` object (a path or array there never runs), `mcpServers`, `lspServers`, `userConfig` |
| Default scans | Claude Code scans the entry's `source` for `agents/`, `commands/`, `workflows/`, `hooks/hooks.json`, `output-styles/`, and `.mcp.json`. An `agents` list adds to the scan |
| Workflows | Plugin workflows (`workflows/*.js`) run as `/plugin:name`, on paid plans. In `plugin.json`, `workflows` replaces the default `workflows/` directory |
| Versions | No `version` anywhere means the commit SHA is the version. `${CLAUDE_PLUGIN_ROOT}` is a per-version directory and changes on every update |
| `bin/` | Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled. They must be executable and start with a shebang |
| Codex | Codex reads `.claude-plugin/marketplace.json`, so skills install there too. Plugins cannot ship agents to Codex: those install from generated TOML files |

---

## Reference files

| Reference | Contents |
|---|---|
| [plugin-manifest.md](references/plugin-manifest.md) | Full `plugin.json` schema: required, metadata, and component path fields, `userConfig`, `channels`, path behavior rules, `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` lifetimes, and where persistent choices go. |
| [marketplace-manifest.md](references/marketplace-manifest.md) | Full `marketplace.json` schema: owner, plugins array, all source types (relative, github, url, git-subdir, npm), entries without `plugin.json`, default component scans, strict mode, reserved names. |
| [component-templates.md](references/component-templates.md) | Templates for `plugin.json`, `SKILL.md`, agent files, workflow scripts, `hooks/hooks.json`, `.mcp.json`, `.lsp.json`, `settings.json`, `bin/` scripts, and output styles. |
| [distribution.md](references/distribution.md) | Hosting options (git hosts, local, URL, npm), semantic versioning and the commit-SHA default, several entries in one repository, release workflow, auto-update behavior, uninstall and data, Codex, team marketplace configuration via `extraKnownMarketplaces`. |

---

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Creating the actual skill content inside a plugin | `skill-creator` |
| Writing the agent body for a plugin-shipped agent | Check existing agent definitions in `agents/` for patterns |
| Generating rules files to pair with a plugin | `agentic-rules-writer` |
| Writing tickets for plugin-related backlog items | `ticket-writer` |

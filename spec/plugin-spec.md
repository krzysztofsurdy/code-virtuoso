# Plugin Specification

This document defines the conventions for Claude Code plugins produced by the `plugin-creator` skill and other tools in this project. It extends the official [Plugins reference](https://code.claude.com/docs/en/plugins-reference) with project-specific rules.

## Contents

- [Directory structure](#directory-structure)
- [plugin.json format](#pluginjson-format)
- [Component requirements](#component-requirements)
- [Environment variables](#environment-variables)
- [Versioning rules](#versioning-rules)
- [Naming conventions](#naming-conventions)
- [Distribution](#distribution)
- [Marketplace registration](#marketplace-registration)

## Directory structure

```
plugin-name/
  .claude-plugin/
    plugin.json          # Optional manifest
  skills/                # Optional - skills at <name>/SKILL.md
  agents/                # Optional - agent files
  hooks/
    hooks.json           # Optional - hook configuration
  .mcp.json              # Optional - MCP server configuration
  .lsp.json              # Optional - LSP server configuration
  bin/                   # Optional - executables added to PATH
  output-styles/         # Optional - output style definitions
  scripts/               # Optional - scripts referenced by hooks
  settings.json          # Optional - default plugin settings
  LICENSE                # Optional
  CHANGELOG.md           # Optional
```

**Only `plugin.json` belongs inside `.claude-plugin/`.** Every other directory (`skills/`, `agents/`, `hooks/`, etc.) lives at the plugin root. This is the most common structural mistake.

## plugin.json format

### Frontmatter-less JSON

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "What this plugin provides.",
  "author": { "name": "Author", "email": "author@example.com" }
}
```

### Required fields (when a manifest is present)

| Field  | Required | Description |
|--------|----------|-------------|
| `name` | Yes      | Kebab-case identifier. Becomes the skill namespace (`/plugin-name:skill-name`). |

### Optional fields

| Field         | Description |
|---------------|-------------|
| `version`     | Semantic version. Must be bumped when content changes or users will not see updates due to caching. |
| `description` | Shown in the plugin manager. |
| `author`      | `{ "name": "...", "email": "...", "url": "..." }`. |
| `homepage`    | Documentation URL. |
| `repository`  | Source repository URL. |
| `license`     | SPDX identifier. |
| `keywords`    | Array of tags for discovery. |
| `skills`      | Custom skill paths. Replaces default `skills/` directory. |
| `commands`    | Custom flat `.md` skill file paths. Replaces default `commands/`. |
| `agents`      | Custom agent paths. Replaces default `agents/`. |
| `hooks`       | Hooks config path(s) or inline object. Merged with `hooks/hooks.json`. |
| `mcpServers`  | MCP config path(s) or inline object. Merged with `.mcp.json`. |
| `lspServers`  | LSP config path(s) or inline object. Merged with `.lsp.json`. |
| `outputStyles`| Custom output style paths. Replaces default `output-styles/`. |
| `userConfig`  | Values prompted at enable time. Substitutable as `${user_config.KEY}`. |
| `channels`    | Message channels bound to an MCP server. |

### Path rules

- All paths must be relative and start with `./`.
- Paths outside the plugin root (`../shared-utils`) will not work after installation - the cache does not copy external files.
- Symlinks **are** preserved by the cache.
- Setting a component path (e.g. `"skills": "./custom"`) **replaces** the default directory. To keep the default and add more, use an array: `["./skills/", "./custom/"]`.

## Component requirements

### Skills

Follow [skill-spec.md](skill-spec.md). Plugin skills are always namespaced as `/plugin-name:skill-name`.

### Agents

Follow [agent-spec.md](agent-spec.md). Plugin-shipped agents additionally **cannot** use:

- `hooks`
- `mcpServers`
- `permissionMode`

These are blocked for security. Plugin-level configuration should be used instead.

Valid `isolation` values: `"worktree"` only.

### Hooks

`hooks/hooks.json` format:

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<optional-regex>",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh" }
        ]
      }
    ]
  }
}
```

Hook types: `command`, `http`, `prompt`, `agent`.

Scripts must be executable (`chmod +x`) and reference `${CLAUDE_PLUGIN_ROOT}` for bundled paths.

### MCP servers

`.mcp.json` format matches the standard MCP server config. Use `${CLAUDE_PLUGIN_ROOT}` for bundled binaries and `${CLAUDE_PLUGIN_DATA}` for persistent state.

### LSP servers

`.lsp.json` format maps language names to server configs. Required fields: `command`, `extensionToLanguage`. Users must install the language server binary separately - LSP plugins only configure the connection.

### Bin

Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled. They must be executable and have a valid shebang.

### Default settings

`settings.json` at plugin root may set:

| Key     | Purpose |
|---------|---------|
| `agent` | Activates a plugin-shipped agent as the main thread when the plugin is enabled. Unknown keys are silently ignored. |

## Environment variables

Two variables are substituted inline in skill content, agent content, hook commands, and MCP/LSP configs. Both are also exported to hook processes and server subprocesses.

| Variable                 | Resolves to                                    | Lifetime                          |
|--------------------------|------------------------------------------------|-----------------------------------|
| `${CLAUDE_PLUGIN_ROOT}`  | Absolute path to the installed plugin directory | Changes on each plugin update.    |
| `${CLAUDE_PLUGIN_DATA}`  | Persistent data directory                      | Survives plugin updates.          |

The data directory resolves to `~/.claude/plugins/data/{id}/` where `{id}` is the plugin identifier with non-`[a-zA-Z0-9_-]` characters replaced by `-`.

## Versioning rules

- Follow semantic versioning: `MAJOR.MINOR.PATCH`.
- Start at `1.0.0` for the first stable release.
- Bump the version in **one** authoritative location: either `plugin.json` or the marketplace entry, not both.
- When both are set, `plugin.json` wins.
- **Always bump the version when content changes.** The cache uses the version to decide whether to update.

## Naming conventions

- Lowercase letters, numbers, and hyphens only.
- Must not start or end with a hyphen.
- Must not contain consecutive hyphens.
- Must not match a reserved marketplace name (see [marketplace-manifest.md](../skills/tools/plugin-creator/references/marketplace-manifest.md#reserved-marketplace-names)).

## Distribution

Plugins are distributed through a marketplace - a `marketplace.json` catalog that lists one or more plugins. A marketplace entry requires at minimum:

```json
{
  "name": "marketplace-name",
  "owner": { "name": "Owner" },
  "plugins": [
    { "name": "plugin-name", "source": "./path-or-source-object" }
  ]
}
```

Supported `source` types: relative path, `github`, `url`, `git-subdir`, `npm`. Full schema in the `plugin-creator` skill's [marketplace-manifest.md](../skills/tools/plugin-creator/references/marketplace-manifest.md).

## Marketplace registration

Plugins produced by this project register in the project's `.claude-plugin/marketplace.json` under the appropriate plugin bundle:

```json
{
  "name": "plugin-bundle-name",
  "description": "Bundle description",
  "source": "./",
  "strict": false,
  "skills": ["./skills/tools/plugin-name"]
}
```

See [CONTRIBUTING.md](../CONTRIBUTING.md#marketplace-configuration) for the full registration and versioning rules.

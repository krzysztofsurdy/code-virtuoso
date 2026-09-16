# plugin.json reference

The plugin manifest lives at `.claude-plugin/plugin.json` inside the plugin directory. It is optional. If omitted, Claude Code discovers components in the default locations and takes the plugin name from the directory name. Provide a manifest when you need metadata, custom component paths, `userConfig`, or `channels`.

## Contents

- [Full schema](#full-schema)
- [Required fields](#required-fields)
- [Metadata fields](#metadata-fields)
- [Component path fields](#component-path-fields)
- [Hooks field semantics](#hooks-field-semantics)
- [User configuration](#user-configuration)
- [Channels](#channels)
- [Environment variables for plugin authors](#environment-variables-for-plugin-authors)
- [Version management rules](#version-management-rules)
- [Common mistakes](#common-mistakes)

## Full schema

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "skills": "./custom/skills/",
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json",
  "userConfig": { },
  "channels": [ ]
}
```

## Required fields

If a manifest is present, only `name` is required.

| Field  | Type   | Description                                               | Example              |
|--------|--------|-----------------------------------------------------------|----------------------|
| `name` | string | Unique identifier (kebab-case, no spaces). Used as the skill namespace (`/plugin-name:skill-name`). | `"deployment-tools"` |

## Metadata fields

All optional. Fill in whatever helps discovery and attribution.

| Field         | Type   | Description                                                                                                            |
|---------------|--------|------------------------------------------------------------------------------------------------------------------------|
| `version`     | string | Semantic version. If set in both `plugin.json` and the marketplace entry, `plugin.json` wins. Only set in one place.   |
| `description` | string | Brief explanation shown in plugin manager.                                                                             |
| `author`      | object | `{ "name": "...", "email": "...", "url": "..." }`. Only `name` is typical; `email` and `url` are optional.             |
| `homepage`    | string | Documentation URL.                                                                                                     |
| `repository`  | string | Source code URL.                                                                                                       |
| `license`     | string | SPDX identifier (`MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, etc.).                                                |
| `keywords`    | array  | Tags for discovery. Keep them short and topical.                                                                       |

## Component path fields

All optional. **Custom paths replace the default directory.** If you set `skills`, the default `skills/` directory is no longer scanned. To keep the default and add more paths, include the default in an array: `"skills": ["./skills/", "./extras/"]`.

| Field          | Type                    | Replaces default         | Purpose                                                      |
|----------------|-------------------------|--------------------------|--------------------------------------------------------------|
| `skills`       | string \| array         | `skills/`                | Directories containing `<name>/SKILL.md` subdirectories.     |
| `commands`     | string \| array         | `commands/`              | Flat `.md` skill files or directories (legacy format).       |
| `agents`       | string \| array         | `agents/`                | Agent files (`<name>.md`).                                   |
| `hooks`        | string \| array \| obj  | `hooks/hooks.json`       | Path(s) to hooks config or inline hooks object.              |
| `mcpServers`   | string \| array \| obj  | `.mcp.json`              | Path(s) to MCP config or inline `mcpServers` object.         |
| `outputStyles` | string \| array         | `output-styles/`         | Custom output style files or directories.                    |
| `lspServers`   | string \| array \| obj  | `.lsp.json`              | Path(s) to LSP config or inline `lspServers` object.         |

### Path rules

- All paths must be relative to the plugin root and start with `./`.
- Paths that go outside the plugin root (`../shared-utils`) do not work after installation, because the cache does not copy external files.
- The cache preserves symlinks. Use them to share files across plugins.
- When a skill path points to a directory containing `SKILL.md` directly (e.g. `"skills": ["./"]`), the `name` field in the SKILL.md frontmatter determines the invocation name. Otherwise the directory basename is used.

## Hooks field semantics

Plugin hooks can come from multiple sources and are merged, not replaced. Valid shapes:

**String** (path to hooks file):
```json
{ "hooks": "./config/hooks.json" }
```

**Array** (multiple hook files merged):
```json
{ "hooks": ["./hooks/security.json", "./hooks/formatting.json"] }
```

**Object** (inline hooks):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh" }
        ]
      }
    ]
  }
}
```

The default `hooks/hooks.json` is loaded in addition to any declared `hooks`. Same for `mcpServers` (default `.mcp.json`) and `lspServers` (default `.lsp.json`).

## User configuration

The `userConfig` field declares values that Claude Code prompts the user for when the plugin is enabled. This replaces editing `settings.json` by hand.

```json
{
  "userConfig": {
    "api_endpoint": {
      "description": "Your team's API endpoint",
      "sensitive": false
    },
    "api_token": {
      "description": "API authentication token",
      "sensitive": true
    }
  }
}
```

- Keys must be valid identifiers.
- Values are substitutable as `${user_config.KEY}` in MCP/LSP configs, hook commands, and (for non-sensitive values only) skill and agent content.
- Values are exposed to plugin subprocesses as `CLAUDE_PLUGIN_OPTION_<KEY>` environment variables.
- Non-sensitive values land in `settings.json` under `pluginConfigs[<plugin-id>].options`.
- Sensitive values go to the system keychain (or `~/.claude/.credentials.json` fallback). Keychain storage has a total limit of about 2 KB, shared with OAuth tokens, so keep sensitive values small.

## Channels

The `channels` field lets a plugin declare message channels that inject content into the conversation. Each channel binds to an MCP server the plugin provides.

```json
{
  "channels": [
    {
      "server": "telegram",
      "userConfig": {
        "bot_token": { "description": "Telegram bot token", "sensitive": true },
        "owner_id": { "description": "Your Telegram user ID", "sensitive": false }
      }
    }
  ]
}
```

- `server` is required and must match a key in the plugin's `mcpServers`.
- Per-channel `userConfig` uses the same schema as top-level `userConfig` and is prompted at enable time.

## Environment variables for plugin authors

Two variables are substituted inline anywhere they appear in skill content, agent content, hook commands, and MCP/LSP server configs. Both are also exported to hook processes and server subprocesses.

| Variable                 | Resolves to                                    | Use for                                                             |
|--------------------------|------------------------------------------------|---------------------------------------------------------------------|
| `${CLAUDE_PLUGIN_ROOT}`  | Absolute path to the installed plugin directory | Bundled scripts, binaries, config files. **Changes on each update.** |
| `${CLAUDE_PLUGIN_DATA}`  | Persistent data directory surviving updates    | `node_modules`, venvs, generated code, caches, any stateful files.  |

The data directory resolves to `~/.claude/plugins/data/{id}/` where `{id}` is the plugin identifier with non-`[a-zA-Z0-9_-]` characters replaced by `-`. For `formatter@my-marketplace`, the directory is `~/.claude/plugins/data/formatter-my-marketplace/`.

### Dependency-install pattern

The data directory outlives any single plugin version, so detecting whether the manifest differs from what is installed means comparing files, not checking that the directory exists:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "diff -q \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package.json\" >/dev/null 2>&1 || (cd \"${CLAUDE_PLUGIN_DATA}\" && cp \"${CLAUDE_PLUGIN_ROOT}/package.json\" . && npm install) || rm -f \"${CLAUDE_PLUGIN_DATA}/package.json\""
          }
        ]
      }
    ]
  }
}
```

The `diff` exits nonzero when the stored copy is missing or differs, which covers the first run and updates that change dependencies. The trailing `rm` clears the copied manifest on `npm install` failure so the next session retries.

## Version management rules

- Follow semantic versioning: `MAJOR.MINOR.PATCH`.
  - MAJOR: breaking changes
  - MINOR: backward-compatible additions
  - PATCH: backward-compatible fixes
- Start new plugins at `1.0.0`. Use `0.x.y` only if breaking changes are actively expected.
- **Claude Code uses the version to decide whether to update plugins.** If the plugin content changes but the version does not, users do not see updates because of caching.
- If the plugin lives inside a marketplace directory, versioning can be managed in `marketplace.json` instead. In that case, omit `version` from `plugin.json`.

## Common mistakes

| Mistake                                                   | Fix                                                                          |
|-----------------------------------------------------------|------------------------------------------------------------------------------|
| Putting `skills/` inside `.claude-plugin/`                | Move to plugin root. Only `plugin.json` belongs in `.claude-plugin/`.        |
| Absolute paths in `plugin.json`                           | All paths must be relative and start with `./`.                              |
| Hard-coded paths like `/Users/me/plugin/scripts/x.sh`     | Use `${CLAUDE_PLUGIN_ROOT}/scripts/x.sh`.                                    |
| `version` set in both `plugin.json` and marketplace entry | Pick one authoritative location. `plugin.json` wins when both exist.         |
| Setting `hooks`, `mcpServers`, or `permissionMode` on a plugin agent | Not supported for plugin-shipped agents. Use plugin-level config instead. |
| Reference files outside plugin root (`../shared-utils`)   | Use symlinks instead - they are preserved by the cache.                     |

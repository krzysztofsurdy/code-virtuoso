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
- [Persistent user and project choices](#persistent-user-and-project-choices)
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
  "agents": ["./custom/agents/reviewer.md"],
  "workflows": ["./workflows/"],
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

All optional. **For `commands`, `agents`, `workflows`, and `outputStyles`, custom paths replace the default directory.** If you set `commands`, the default `commands/` directory is no longer scanned. To keep the default and add more paths, include the default in an array: `"commands": ["./commands/", "./extras/"]`. `skills` is the exception: it adds to the default `skills/` scan, and `hooks`, `mcpServers`, and `lspServers` merge with their default files.

| Field          | Type                    | Replaces default         | Purpose                                                      |
|----------------|-------------------------|--------------------------|--------------------------------------------------------------|
| `skills`       | string \| array         | adds to `skills/`        | Directories containing `<name>/SKILL.md` subdirectories.     |
| `commands`     | string \| array \| obj  | `commands/`              | Flat `.md` files, directories, or a map of command name to `source` or `content`. |
| `agents`       | string \| array         | `agents/`                | Agent `.md` files. Directories are not accepted.             |
| `workflows`    | string \| array         | `workflows/`             | Workflow `.js` files or directories. Run as `/plugin:name` (paid plans). |
| `hooks`        | string \| array \| obj  | `hooks/hooks.json`       | Path(s) to hooks config or inline hooks object.              |
| `mcpServers`   | string \| array \| obj  | `.mcp.json`              | Path(s) to MCP config or inline `mcpServers` object.         |
| `outputStyles` | string \| array         | `output-styles/`         | Custom output style files or directories.                    |
| `lspServers`   | string \| array \| obj  | `.lsp.json`              | Path(s) to LSP config or inline `lspServers` object.         |

### Path rules

- All paths must be relative to the plugin root and start with `./`.
- Paths that go outside the plugin root (`../shared-utils`) do not work after installation, because the cache does not copy external files.
- The cache preserves symlinks. Use them to share files across plugins.
- A plugin with no `plugin.json` still loads the default locations. Unrecognized top-level manifest keys are stripped, with a warning from `claude plugin validate`.
- `bin/` needs no manifest key. Files there are on the Bash tool's `PATH` while the plugin is enabled, after the user's own `PATH` entries, so a plugin cannot shadow a system command. They must be executable and start with a shebang.
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

A hooks file wraps the event map in a top-level `"hooks"` key. An inline object is the event map itself, with no wrapper. In a marketplace entry that has no `plugin.json`, `hooks` must be an inline object: a file path or array there never runs.

## User configuration

The `userConfig` field declares values that Claude Code prompts the user for when the plugin is enabled. This replaces editing `settings.json` by hand. It fits plugin-level settings such as an endpoint or a token. It does not fit team or project decisions: see [Persistent user and project choices](#persistent-user-and-project-choices).

```json
{
  "userConfig": {
    "api_endpoint": {
      "type": "string",
      "title": "API endpoint",
      "description": "Your team's API endpoint"
    },
    "api_token": {
      "type": "string",
      "title": "API token",
      "description": "API authentication token",
      "sensitive": true
    }
  }
}
```

- Each option needs `type` (`string`, `number`, `boolean`, `directory`, or `file`), `title`, and `description`. An unknown key inside an option stops the plugin from loading.
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
        "bot_token": { "type": "string", "title": "Bot token", "description": "Telegram bot token", "sensitive": true },
        "owner_id": { "type": "string", "title": "Owner ID", "description": "Your Telegram user ID" }
      }
    }
  ]
}
```

- `server` is required and must match a key in the plugin's `mcpServers`.
- Per-channel `userConfig` uses the same schema as top-level `userConfig` and is prompted at enable time.

## Environment variables for plugin authors

Two variables are substituted inline in skill content, agent content, hook commands, and MCP/LSP server configs. Hook processes and MCP and LSP server subprocesses also receive them as environment variables.

| Variable                 | Resolves to                                    | Lifetime                                                            |
|--------------------------|------------------------------------------------|---------------------------------------------------------------------|
| `${CLAUDE_PLUGIN_ROOT}`  | Absolute path of the installed plugin version  | **Changes on every update.** Never write state there.               |
| `${CLAUDE_PLUGIN_DATA}`  | `~/.claude/plugins/data/{id}/`                 | Survives updates. **Deleted on uninstall** from the last scope, unless the user runs `claude plugin uninstall --keep-data`. |

The data directory is created on first reference. `{id}` is the plugin identifier with non-`[a-zA-Z0-9_-]` characters replaced by `-`. For `formatter@my-marketplace`, the directory is `~/.claude/plugins/data/formatter-my-marketplace/`. Use it for disposable data: `node_modules`, venvs, generated code, caches.

`${CLAUDE_PLUGIN_ROOT}` is a version directory in the plugin cache (`cache/<marketplace>/<plugin>/<version>/`). When no version is set, the commit SHA is the version, so every commit gives a new root. A plugin loaded from a marketplace added by local path loads in place, and its root is the source directory.

**Neither variable is set in the environment of commands Claude runs through the Bash tool**, in the main session or in a subagent. Write the `${...}` reference in the Markdown body of a skill or agent, and Claude Code substitutes the path when it loads the content. A script that Claude runs from the Bash tool must receive the path as an argument or find its files relative to itself. Executables in `bin/` are on `PATH` but still do not get these variables.

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

## Persistent user and project choices

Do not store user or project choices (tool names, branch patterns, test commands, agent tuning) in `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_DATA}`. The root is replaced on update, the data directory is deleted on uninstall, and neither is visible to the Bash tool or to other agent platforms such as Codex. Use the layered Code Virtuoso config instead. The full rules are in the [config spec](https://github.com/krzysztofsurdy/code-virtuoso/blob/main/spec/config-spec.md). A skill under a `./skills` marketplace source cannot link to files outside `skills/`, so the summary is inline here:

| Layer | Path | In git | Holds |
|---|---|---|---|
| Defaults | Inside the skill or agent | n/a | Fallback values |
| User | `$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json` | Never | Personal preferences |
| Project shared | `<project root>/.code-virtuoso/config.json` | Committed | Team decisions: commands, patterns, shared tuning |
| Project local | `<project root>/.code-virtuoso/config.local.json` | Ignored | Personal per-project overrides |

- Precedence, highest first: explicit argument, project local, project shared, user, defaults. Objects deep-merge. Arrays and scalars replace. A missing file is normal.
- Format: JSON with `"version": 1` and one namespace per consumer, named after the plugin or skill (`agents.<agent-name>` for agent tuning). Keys are camelCase.
- Writers read the file, change only their own keys, and write it back with indented JSON. They never overwrite the file blindly.
- Setup runs in the main session and writes to the layer the question is tagged with. Subagents never prompt: they use defaults and end the report with `Defaults used for: <keys>. Run <skill> setup to save them.`
- Never store secrets. Reject keys named like `token`, `secret`, `password`, or `apikey`. Use `userConfig` with `sensitive: true` for a credential Claude Code should hold in secure storage.
- Whoever first creates `.code-virtuoso/` also writes `.code-virtuoso/.gitignore` containing `*.local.json`, `loop/state/`, and `handoff/`.

## Version management rules

- Follow semantic versioning: `MAJOR.MINOR.PATCH`.
  - MAJOR: breaking changes
  - MINOR: backward-compatible additions
  - PATCH: backward-compatible fixes
- Start new plugins at `1.0.0`. Use `0.x.y` only if breaking changes are actively expected.
- **Claude Code uses the version to decide whether to update plugins.** If the plugin content changes but the version does not, users do not see updates because of caching.
- With no `version` in `plugin.json` or the marketplace entry, the version is the commit SHA of the installed directory (for a relative-path plugin in a git-hosted marketplace), so every commit is a new version. It is `unknown` for a local directory outside a git repository. Set an explicit version when you want updates only on deliberate releases.
- If the plugin lives inside a marketplace directory, versioning can be managed in `marketplace.json` instead. In that case, omit `version` from `plugin.json`.

## Common mistakes

| Mistake                                                   | Fix                                                                          |
|-----------------------------------------------------------|------------------------------------------------------------------------------|
| Putting `skills/` inside `.claude-plugin/`                | Move to plugin root. Only `plugin.json` belongs in `.claude-plugin/`.        |
| Absolute paths in `plugin.json`                           | All paths must be relative and start with `./`.                              |
| Hard-coded paths like `/Users/me/plugin/scripts/x.sh`     | Use `${CLAUDE_PLUGIN_ROOT}/scripts/x.sh`.                                    |
| `version` set in both `plugin.json` and marketplace entry | Pick one authoritative location. `plugin.json` wins when both exist.         |
| Setting `hooks`, `mcpServers`, or `permissionMode` on a plugin agent | Ignored for plugin-shipped agents. Use plugin-level `hooks/hooks.json` and `.mcp.json` instead. |
| Saving user or project choices under `${CLAUDE_PLUGIN_DATA}` | Deleted on uninstall and invisible to the Bash tool. Use the layered config. |
| Expecting `${CLAUDE_PLUGIN_ROOT}` in a Bash tool command | Not set there. Reference it in skill or agent Markdown, or pass the path as an argument. |
| Omitting `type` or `title` in a `userConfig` option | The plugin fails to load. Every option needs `type`, `title`, and `description`. |
| Reference files outside plugin root (`../shared-utils`)   | Use symlinks instead - they are preserved by the cache.                     |

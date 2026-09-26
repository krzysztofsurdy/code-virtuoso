# Plugin Specification

This document defines the conventions for Claude Code plugins produced by the `plugin-creator` skill and other tools in this project. It extends the official [Plugins reference](https://code.claude.com/docs/en/plugins-reference) with project-specific rules.

Sources for the platform facts below:

- [Plugin manifest reference](https://code.claude.com/docs/en/plugins-reference)
- [Marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference)
- [Plugin loading, cache, and versions](https://code.claude.com/docs/en/plugins/loading)
- [Plugin components](https://code.claude.com/docs/en/plugins/components)
- [Plugin CLI reference](https://code.claude.com/docs/en/plugins/cli-reference)

## Contents

- [Directory structure](#directory-structure)
- [plugin.json format](#pluginjson-format)
- [Component requirements](#component-requirements)
- [Environment variables](#environment-variables)
- [Persistent user and project choices](#persistent-user-and-project-choices)
- [Versioning rules](#versioning-rules)
- [Naming conventions](#naming-conventions)
- [Distribution](#distribution)
- [Marketplace registration](#marketplace-registration)
- [Default component scans](#default-component-scans)

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
| `skills`      | Custom skill paths. Adds to the default `skills/` directory. |
| `commands`    | Custom flat `.md` skill file paths. Replaces default `commands/`. |
| `agents`      | Agent `.md` file paths (directories are not accepted). Replaces default `agents/`. |
| `workflows`   | Workflow `.js` files or directories. Replaces default `workflows/`. |
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
- Every component path must exist and stay inside the plugin root, or the component does not load.
- `commands`, `agents`, `outputStyles`, and `workflows` **replace** their default directory when set in `plugin.json`. To keep the default and add more, list it too: `"commands": ["./commands/", "./extras/"]`.
- `skills` **adds** to the default `skills/` directory. `hooks`, `mcpServers`, and `lspServers` **merge** with their default file.
- These replace rules apply to `plugin.json`. A marketplace entry without a `plugin.json` behaves differently: see [Default component scans](#default-component-scans).

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

`.mcp.json` format matches the standard MCP server config. Use `${CLAUDE_PLUGIN_ROOT}` for bundled binaries and `${CLAUDE_PLUGIN_DATA}` for caches and installed dependencies. Do not keep user or project choices there, see [Persistent user and project choices](#persistent-user-and-project-choices).

### LSP servers

`.lsp.json` format maps language names to server configs. Required fields: `command`, `extensionToLanguage`. Users must install the language server binary separately - LSP plugins only configure the connection.

### Bin

Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled (Claude Code 2.1.91 or later), so Claude and skill instructions can run them as bare commands. They come after the user's own `PATH` entries, so a plugin cannot shadow a system command. They must be executable and have a valid shebang.

### Default settings

`settings.json` at plugin root may set:

| Key     | Purpose |
|---------|---------|
| `agent` | Activates a plugin-shipped agent as the main thread when the plugin is enabled. Unknown keys are silently ignored. |

## Environment variables

Two variables are substituted inline in the Markdown body of skills, commands, and agents, in hook commands, and in MCP and LSP configs. Hook processes and MCP and LSP server subprocesses also receive them as environment variables.

| Variable                 | Resolves to                                    | Lifetime                          |
|--------------------------|------------------------------------------------|-----------------------------------|
| `${CLAUDE_PLUGIN_ROOT}`  | Absolute path of the installed plugin version  | Changes on every update.          |
| `${CLAUDE_PLUGIN_DATA}`  | `~/.claude/plugins/data/<plugin>-<marketplace>/` | Survives updates. Deleted on uninstall. |

`${CLAUDE_PLUGIN_ROOT}` is a version directory in the plugin cache (`cache/<marketplace>/<plugin>/<version>/`). Never write state there. For an entry with `"source": "./"` the directory is a full copy of the repository, and when no `version` is set the version is the commit SHA, so every new commit gives a new root. A plugin loaded from a marketplace added by local path is the exception: it loads in place, and the root is the source directory.

`${CLAUDE_PLUGIN_DATA}` is created on first reference. `<plugin>-<marketplace>` is the plugin ID with every character other than a letter, digit, `_`, or `-` replaced by `-`. Claude Code deletes it when the plugin is uninstalled from its last scope, unless the user runs `claude plugin uninstall --keep-data`.

Neither variable is set in the environment of commands Claude runs through the Bash tool. Write the `${...}` reference in a skill or agent Markdown body instead, and Claude Code substitutes the path when it loads the content. A script that Claude runs from the Bash tool must receive the path as an argument or find its files relative to itself.

## Persistent user and project choices

Do not store user or project choices (tool names, branch patterns, test commands, tuning) in `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_DATA}`. The root is replaced on update, the data directory is deleted on uninstall, and neither is visible to the Bash tool or to other agent platforms. Use the layered `.code-virtuoso` config described in [config-spec.md](config-spec.md).

## Versioning rules

- Follow semantic versioning: `MAJOR.MINOR.PATCH`.
- Start at `1.0.0` for the first stable release.
- Bump the version in **one** authoritative location: either `plugin.json` or the marketplace entry, not both.
- When both are set, `plugin.json` wins.
- When neither sets a version, the version is the commit SHA of the installed directory for a relative-path plugin in a git-hosted marketplace, and `unknown` for a local directory that is not in a git repository. The version decides whether `claude plugin update` replaces the cached copy.
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

Supported `source` types: relative path, `github`, `url`, `git-subdir`, `npm`, `archive`. Full schema in the `plugin-creator` skill's [marketplace-manifest.md](../skills/tools/plugin-creator/references/marketplace-manifest.md).

## Marketplace registration

Plugins produced by this project register in the project's `.claude-plugin/marketplace.json` under the appropriate plugin bundle:

```json
{
  "name": "plugin-bundle-name",
  "description": "Bundle description",
  "source": "./skills",
  "strict": false,
  "skills": ["./tools/plugin-name"]
}
```

Skill paths resolve from the entry's `source`, not from the repository root.

See [CONTRIBUTING.md](../CONTRIBUTING.md#marketplace-configuration) for the full registration and versioning rules.

## Default component scans

A marketplace entry without a `plugin.json` is the plugin manifest, and it accepts every `plugin.json` field: `skills`, `commands`, `agents`, `workflows`, an inline `hooks` object, `mcpServers`, `lspServers`, and `userConfig`. Entry `hooks` must be an inline object, because a file path or array there never runs.

Claude Code also scans the entry's `source` directory for the default component locations: `agents/`, `commands/`, `workflows/`, `hooks/hooks.json`, `output-styles/`, and `.mcp.json`. A test with Claude Code 2.1.306 confirmed this for `agents/`, `commands/`, `hooks/hooks.json`, and `.mcp.json`: each was registered by the entry whose source held it. For `agents`, an entry's `agents` list **adds** to the `agents/` scan instead of replacing it, and an empty list (`"agents": []`) changes nothing. Directories are not accepted in `agents`, and a path to a missing file makes the plugin fail to load. A `skills` list on an entry whose source is the repository root is the exception: only the listed skill directories load.

The result: several entries with `"source": "./"` each register every agent in the root `agents/` directory, so installing a skills-only bundle would also register `<bundle>:reviewer`, `<bundle>:investigator`, and so on. Rules that prevent this:

- Only the entry that owns the root component directories (`agents-virtuoso`) uses `"source": "./"`.
- Skill-only bundles use `"source": "./skills"` and list skill paths relative to it (`./knowledge/solid`). `skills/` holds no `agents/`, `commands/`, `workflows/`, or `hooks/` directory, so nothing extra registers.
- Adding a root `commands/`, `workflows/`, `hooks/hooks.json`, `output-styles/`, or `.mcp.json` has the same effect as `agents/`. Before adding one, make sure exactly one entry has the repository root as its source, or move the component into a self-contained plugin under `plugins/`.
- Do not use `"agents": []` or a placeholder `.md` file to suppress the scan. Neither works.
- Files outside an entry's `source` are not copied into the cache, so a skill in a bundle that links to `../../../spec/...` has a broken link once installed. Keep links inside `skills/`.

`scripts/validate-marketplace.py` fails when two entries share a source directory that contains `agents/`, `commands/`, `workflows/`, or `hooks/hooks.json`.

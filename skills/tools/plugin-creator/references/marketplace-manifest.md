# marketplace.json reference

The marketplace catalog lives at `.claude-plugin/marketplace.json` in a dedicated marketplace repository (or the same repo as a single plugin). It lists the plugins available through this marketplace and where to fetch each one.

## Contents

- [Required fields](#required-fields)
- [Optional metadata](#optional-metadata)
- [Reserved marketplace names](#reserved-marketplace-names)
- [Plugin entry fields](#plugin-entry-fields)
- [Plugin sources](#plugin-sources)
- [Entries without plugin.json](#entries-without-pluginjson)
- [Default component scans](#default-component-scans)
- [Strict mode](#strict-mode)
- [Codex](#codex)
- [Minimal valid marketplace](#minimal-valid-marketplace)
- [Multi-plugin example](#multi-plugin-example)
- [Common mistakes](#common-mistakes)

## Required fields

| Field     | Type   | Description                                                                                                                                                              |
|-----------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`    | string | Marketplace identifier (kebab-case, no spaces). It is public: users see it when installing: `/plugin install my-tool@your-marketplace`.                               |
| `owner`   | object | `{ "name": "...", "email": "..." }`. `name` required, `email` optional.                                                                                                  |
| `plugins` | array  | List of plugin entries.                                                                                                                                                  |

## Optional metadata

| Field                   | Type   | Description                                                                                                                           |
|-------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------|
| `metadata.description`  | string | Brief marketplace description.                                                                                                        |
| `metadata.version`      | string | Marketplace version.                                                                                                                  |
| `metadata.pluginRoot`   | string | Base directory prepended to relative plugin source paths. E.g. `"./plugins"` lets entries use `"source": "formatter"` instead of `"./plugins/formatter"`. |

## Reserved marketplace names

The following names are reserved for official Anthropic use. Any marketplace that uses them (or impersonates them with variants like `official-claude-plugins`) is blocked:

- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `knowledge-work-plugins`
- `life-sciences`

## Plugin entry fields

Each entry in the `plugins` array can include any field from the [plugin manifest schema](plugin-manifest.md) (description, version, author, commands, hooks, etc.) plus these marketplace-specific fields.

### Required

| Field    | Type             | Description                                                                 |
|----------|------------------|-----------------------------------------------------------------------------|
| `name`   | string           | Plugin identifier (kebab-case, no spaces). Used as `plugin-name@marketplace-name` when installing. |
| `source` | string \| object | Where to fetch the plugin from (see [Plugin sources](#plugin-sources)).     |

### Optional standard metadata

| Field         | Type    | Description                                                                                    |
|---------------|---------|------------------------------------------------------------------------------------------------|
| `description` | string  | Brief plugin description.                                                                      |
| `version`     | string  | Plugin version. If also in `plugin.json`, the manifest wins.                                   |
| `author`      | object  | `{ "name": "...", "email": "..." }`.                                                           |
| `homepage`    | string  | Plugin homepage or docs URL.                                                                   |
| `repository`  | string  | Source code URL.                                                                               |
| `license`     | string  | SPDX identifier.                                                                               |
| `keywords`    | array   | Tags for discovery.                                                                            |
| `category`    | string  | Plugin category for organization.                                                              |
| `tags`        | array   | Tags for searchability.                                                                        |
| `strict`      | boolean | Default `true`. See [Strict mode](#strict-mode).                                               |

### Optional component configuration

An entry accepts every `plugin.json` field. With a `plugin.json` present these supplement it (see [Strict mode](#strict-mode)). Without one, the entry is the manifest.

| Field          | Type            | Description                                                    |
|----------------|-----------------|----------------------------------------------------------------|
| `skills`       | string \| array | Skill directory paths, relative to the entry's `source`.       |
| `commands`     | string \| array \| obj | Flat `.md` command files, directories, or a name-to-`source`/`content` map. |
| `agents`       | string \| array | Agent `.md` file paths. Directories are not accepted.          |
| `workflows`    | string \| array | Workflow `.js` files or directories.                           |
| `hooks`        | obj             | Inline hooks object (the event map, no wrapper). A path or array here never runs. |
| `mcpServers`   | string \| obj   | MCP config path or inline `mcpServers` object.                 |
| `lspServers`   | string \| obj   | LSP config path or inline `lspServers` object.                 |
| `outputStyles` | string \| array | Output style files or directories.                             |
| `userConfig`   | obj             | Values prompted at enable time, substitutable as `${user_config.KEY}`. Each option needs `type`, `title`, and `description`. |

## Plugin sources

`source` tells Claude Code where to fetch each individual plugin. It is separate from the marketplace source, which is where `marketplace.json` itself lives.

| Source type    | Shape                              | Required fields                    | Optional fields | Notes                                                                                  |
|----------------|------------------------------------|------------------------------------|-----------------|----------------------------------------------------------------------------------------|
| Relative path  | `string` starting with `./`        | -                                  | -               | Resolves relative to marketplace root (the directory containing `.claude-plugin/`). Do not use `../`. Only works when marketplace is Git-hosted. |
| `github`       | object                             | `repo` (`owner/repo`)              | `ref`, `sha`    | GitHub repo. `ref` is branch or tag; `sha` is 40-char commit hash.                     |
| `url`          | object                             | `url` (full git URL)               | `ref`, `sha`    | Any git host. `https://` or `git@`. `.git` suffix optional.                            |
| `git-subdir`   | object                             | `url`, `path`                      | `ref`, `sha`    | Plugin lives in a subdirectory of a git repo. Uses sparse clone to minimize bandwidth. |
| `npm`          | object                             | `package`                          | `version`, `registry` | Installed via `npm install`. Supports private registries.                       |

### Relative path

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

Skill paths in an entry resolve from that entry's `source`, not from the repository root. For a skill-only bundle in a repository that also holds `agents/` or `workflows/` at its root, use `"source": "./skills"` and list `"./knowledge/security"` style paths.

**Warning**: relative paths work only when the marketplace is added via Git (GitHub, GitLab, or git URL). If users add your marketplace via a direct URL to `marketplace.json`, relative paths will not resolve. For URL-distributed marketplaces, use `github`, `url`, or `npm` sources instead.

### GitHub

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

### Generic git URL

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main"
  }
}
```

### Git subdirectory

For monorepos, this avoids cloning the full repo:

```json
{
  "name": "my-plugin",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/acme-corp/monorepo.git",
    "path": "tools/claude-plugin",
    "ref": "v2.0.0"
  }
}
```

`url` accepts a full URL, GitHub shorthand (`owner/repo`), or an SSH URL.

### npm

```json
{
  "name": "my-npm-plugin",
  "source": {
    "source": "npm",
    "package": "@acme/claude-plugin",
    "version": "2.1.0",
    "registry": "https://npm.internal.acme.com"
  }
}
```

## Entries without plugin.json

A marketplace entry with no `plugin.json` in its source is the plugin manifest. It accepts every `plugin.json` field: `skills`, `commands`, `agents`, `workflows`, an inline `hooks` object, `mcpServers`, `lspServers`, `outputStyles`, and `userConfig`. This is how one repository can publish several bundles without a manifest file per bundle. Entry `hooks` must be an inline object, because a file path or array there never runs and the `/plugin` Errors tab reports it.

## Default component scans

Besides the fields the entry lists, Claude Code scans the entry's `source` directory for the default locations: `agents/`, `commands/`, `workflows/`, `hooks/hooks.json`, `output-styles/`, and `.mcp.json`. Checked on Claude Code 2.1.306 for `agents/`, `commands/`, `hooks/hooks.json`, and `.mcp.json`: each was registered by the entry whose source held it.

What follows for a repository with several entries:

- Several entries with `"source": "./"` each register every root `agents/`, `commands/`, `workflows/`, and hook, so the same agent appears once per entry under each entry's name. Give the root source to one entry only.
- An entry's `agents` list **adds** to the `agents/` scan. `"agents": []` changes nothing, and a placeholder `.md` file does not suppress the scan either.
- A `skills` list on an entry whose source is the repository root is the exception: only the listed skill directories load, and the default `skills/` is not scanned.
- Skill-only bundles use a narrower source such as `"./skills"` (which holds no `agents/`, `commands/`, `workflows/`, or `hooks/`) and list skill paths relative to it.
- A self-contained plugin in its own directory (`"source": "./plugins/<name>"`) keeps its components to itself.
- Files outside an entry's `source` are not copied into the cache. A skill that links to `../../../spec/...` has a broken link after install. Keep links inside the source directory, or inline the content and give a full URL.

## Strict mode

`strict` (default `true`) controls how an entry combines with a `plugin.json` in the plugin's source.

- **No `plugin.json`**: the entry is the manifest, whatever `strict` says.
- **`plugin.json` present, `strict` unset or `true`**: Claude Code loads the manifest and appends the entry's `commands`, `agents`, `skills`, and `outputStyles` to it. For `hooks`, the entry's matchers for an event replace the manifest's matchers for that same event, and events only the manifest declares keep theirs.
- **`plugin.json` present, `strict: false`**: an entry that declares any of `commands`, `agents`, `skills`, `hooks`, or `outputStyles` is a conflict, and the plugin fails to load with `Plugin <name> has conflicting manifests: both plugin.json and marketplace entry specify components.` Remove the duplicate definitions or leave `strict` at its default.

`version` is the exception to "entry adds to manifest": the manifest's `version` overrides the entry's. With neither set, the commit SHA is the version.

## Codex

Codex reads `.claude-plugin/marketplace.json`, so the same marketplace installs skills there (`codex plugin marketplace add owner/repo`). Codex plugins cannot ship agents: those install from TOML files in `~/.codex/agents/` or `.codex/agents/`. This library generates them from `agents/*.md` with `scripts/build-codex-agents.py`. Claude-only components (hooks, workflows, `userConfig`) have no Codex equivalent, so keep Codex-bound skills free of them. Source: [Package your plugin](https://developers.openai.com/plugins/build/plugins).

## Minimal valid marketplace

```json
{
  "name": "my-plugins",
  "owner": { "name": "Your Name" },
  "plugins": [
    {
      "name": "quality-review-plugin",
      "source": "./plugins/quality-review-plugin",
      "description": "Adds a /quality-review skill for quick code reviews"
    }
  ]
}
```

## Multi-plugin example

```json
{
  "name": "company-tools",
  "owner": { "name": "DevTools Team", "email": "devtools@example.com" },
  "metadata": {
    "description": "Internal plugins for the engineering org",
    "version": "3.2.1",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "formatter",
      "description": "Automatic code formatting on save",
      "version": "2.1.0"
    },
    {
      "name": "deployment-tools",
      "source": {
        "source": "github",
        "repo": "company/deploy-plugin",
        "ref": "v1.0.0"
      }
    },
    {
      "name": "db-tools-from-monorepo",
      "source": {
        "source": "git-subdir",
        "url": "company/platform-monorepo",
        "path": "tools/db-plugin"
      }
    }
  ]
}
```

With `metadata.pluginRoot: "./plugins"`, the `code-formatter` entry's relative `"source": "formatter"` resolves to `./plugins/formatter`.

## Common mistakes

| Mistake                                                    | Fix                                                                             |
|------------------------------------------------------------|---------------------------------------------------------------------------------|
| Using `../` in a relative source path                      | Paths must stay within the marketplace repo. Move the plugin inside the repo.   |
| Using a reserved marketplace name                          | Choose a different name. Anthropic reserves official-sounding names.            |
| Setting `version` in both `plugin.json` and marketplace entry | Pick one. If both exist, `plugin.json` wins.                                 |
| `strict: false` with a `plugin.json` that also declares components | Remove duplicates from one of the two locations.                         |
| Two entries with `"source": "./"`                          | Each registers every root `agents/`, `commands/`, `workflows/`, and hook. Use `"./skills"` for skill-only bundles. |
| `"agents": []` to stop the `agents/` scan                  | It does nothing. Use a narrower source or a plugin in its own directory.        |
| Entry `hooks` given as a path or array                     | Never runs. Use an inline hooks object.                                         |
| Skill links to files above the entry's `source`            | Not copied into the cache. Keep links inside the source.                        |
| Distributing via URL with relative plugin sources          | Relative paths only work over Git. Switch source type or switch distribution.   |

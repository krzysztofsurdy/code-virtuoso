# marketplace.json Reference

The marketplace catalog lives at `.claude-plugin/marketplace.json` in a dedicated marketplace repository (or the same repo as a single plugin). It lists the plugins available through this marketplace and where to fetch each one.

## Required Fields

| Field     | Type   | Description                                                                                                                                                              |
|-----------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`    | string | Marketplace identifier (kebab-case, no spaces). Public-facing - users see it when installing: `/plugin install my-tool@your-marketplace`.                               |
| `owner`   | object | `{ "name": "...", "email": "..." }`. `name` required, `email` optional.                                                                                                  |
| `plugins` | array  | List of plugin entries.                                                                                                                                                  |

## Optional Metadata

| Field                   | Type   | Description                                                                                                                           |
|-------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------|
| `metadata.description`  | string | Brief marketplace description.                                                                                                        |
| `metadata.version`      | string | Marketplace version.                                                                                                                  |
| `metadata.pluginRoot`   | string | Base directory prepended to relative plugin source paths. E.g. `"./plugins"` lets entries use `"source": "formatter"` instead of `"./plugins/formatter"`. |

## Reserved Marketplace Names

The following names are reserved for official Anthropic use. Any marketplace that uses them (or impersonates them with variants like `official-claude-plugins`) is blocked:

- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `knowledge-work-plugins`
- `life-sciences`

## Plugin Entry Fields

Each entry in the `plugins` array can include any field from the [plugin manifest schema](plugin-manifest.md) (description, version, author, commands, hooks, etc.) **plus** these marketplace-specific fields.

### Required

| Field    | Type             | Description                                                                 |
|----------|------------------|-----------------------------------------------------------------------------|
| `name`   | string           | Plugin identifier (kebab-case, no spaces). Used as `plugin-name@marketplace-name` when installing. |
| `source` | string \| object | Where to fetch the plugin from (see [Plugin Sources](#plugin-sources)).     |

### Optional Standard Metadata

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
| `strict`      | boolean | Default `true`. See [Strict Mode](#strict-mode).                                               |

### Optional Component Configuration

These override or supplement the plugin's own `plugin.json`:

| Field        | Type            | Description                                                    |
|--------------|-----------------|----------------------------------------------------------------|
| `skills`     | string \| array | Custom skill directory paths.                                  |
| `commands`   | string \| array | Custom flat `.md` skill file paths.                            |
| `agents`     | string \| array | Custom agent file paths.                                       |
| `hooks`      | string \| obj   | Hooks config path or inline hooks object.                      |
| `mcpServers` | string \| obj   | MCP config path or inline `mcpServers` object.                 |
| `lspServers` | string \| obj   | LSP config path or inline `lspServers` object.                 |

## Plugin Sources

`source` tells Claude Code where to fetch each individual plugin. Not to be confused with the **marketplace source** (where `marketplace.json` itself lives).

| Source type    | Shape                              | Required fields                    | Optional fields | Notes                                                                                  |
|----------------|------------------------------------|------------------------------------|-----------------|----------------------------------------------------------------------------------------|
| Relative path  | `string` starting with `./`        | -                                  | -               | Resolves relative to marketplace root (the directory containing `.claude-plugin/`). Do not use `../`. Only works when marketplace is Git-hosted. |
| `github`       | object                             | `repo` (`owner/repo`)              | `ref`, `sha`    | GitHub repo. `ref` is branch or tag; `sha` is 40-char commit hash.                     |
| `url`          | object                             | `url` (full git URL)               | `ref`, `sha`    | Any git host. `https://` or `git@`. `.git` suffix optional.                            |
| `git-subdir`   | object                             | `url`, `path`                      | `ref`, `sha`    | Plugin lives in a subdirectory of a git repo. Uses sparse clone to minimize bandwidth. |
| `npm`          | object                             | `package`                          | `version`, `registry` | Installed via `npm install`. Supports private registries.                       |

### Relative Path

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

**Warning**: relative paths only work when the marketplace is added via Git (GitHub, GitLab, or git URL). If users add your marketplace via a direct URL to `marketplace.json`, relative paths will not resolve. For URL-distributed marketplaces, use `github`, `url`, or `npm` sources instead.

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

### Generic Git URL

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

### Git Subdirectory

For monorepos, avoids cloning the full repo:

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

`url` accepts full URL, GitHub shorthand (`owner/repo`), or SSH URL.

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

## Strict Mode

`strict` (default `true`) controls whether `plugin.json` is the authoritative source for component definitions.

- **`strict: true`** (default) - `plugin.json` owns component paths. Marketplace entry cannot override `commands`, `agents`, `hooks`, `mcpServers`, `lspServers`. Safer for plugins you do not control.
- **`strict: false`** - Marketplace entry may override/augment component paths. Useful when:
  - The plugin has no `plugin.json` (single-plugin repo with everything at the root)
  - You want to add extra hooks or MCP servers at the marketplace layer
  - You are building a single-plugin marketplace where plugin and marketplace share the same root

If `strict: false` is set but the plugin also has a `plugin.json` defining components, you will see the error: `Plugin <name> has conflicting manifests: both plugin.json and marketplace entry specify components.` - remove the duplicate definitions or flip `strict` back to `true`.

## Minimal Valid Marketplace

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

## Multi-Plugin Example

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

## Common Mistakes

| Mistake                                                    | Fix                                                                             |
|------------------------------------------------------------|---------------------------------------------------------------------------------|
| Using `../` in a relative source path                      | Paths must stay within the marketplace repo. Move the plugin inside the repo.   |
| Using a reserved marketplace name                          | Choose a different name. Anthropic reserves official-sounding names.            |
| Setting `version` in both `plugin.json` and marketplace entry | Pick one. If both exist, `plugin.json` wins.                                 |
| `strict: false` with a `plugin.json` that also declares components | Remove duplicates from one of the two locations.                         |
| Distributing via URL with relative plugin sources          | Relative paths only work over Git. Switch source type or switch distribution.   |

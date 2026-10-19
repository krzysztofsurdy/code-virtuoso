# Plugin distribution

How to get a plugin into users' hands: hosting options, versioning rules, update mechanics, and team marketplace configuration.

## Contents

- [Distribution options](#distribution-options)
- [Hosting a marketplace on GitHub](#hosting-a-marketplace-on-github)
- [Single-plugin repos (flat layout)](#single-plugin-repos-flat-layout)
- [Several entries in one repository](#several-entries-in-one-repository)
- [Semantic versioning](#semantic-versioning)
- [Release workflow](#release-workflow)
- [Auto-updates](#auto-updates)
- [Team marketplace configuration](#team-marketplace-configuration)
- [Plugin caching and file resolution](#plugin-caching-and-file-resolution)
- [Uninstall and plugin data](#uninstall-and-plugin-data)
- [Workflows and bin](#workflows-and-bin)
- [Codex](#codex)
- [Validation before release](#validation-before-release)
- [Common distribution mistakes](#common-distribution-mistakes)

## Distribution options

| Option                          | How users add it                                    | Best for                                                  |
|---------------------------------|-----------------------------------------------------|-----------------------------------------------------------|
| Standalone directory            | `claude --plugin-dir ./my-plugin`                   | Local development and testing only.                       |
| GitHub marketplace              | `/plugin marketplace add owner/repo`                | Open-source distribution. Most common.                    |
| Generic Git marketplace         | `/plugin marketplace add https://gitlab.com/.../x.git` | GitLab, Bitbucket, self-hosted git.                    |
| Local marketplace               | `/plugin marketplace add ./path/to/marketplace`     | Teams with shared network drives or monorepo plugins.     |
| URL-hosted `marketplace.json`   | `/plugin marketplace add https://example.com/x.json` | Custom hosting. Relative plugin sources do not resolve.   |
| Official Anthropic marketplace  | Already installed. `/plugin install <name>@claude-plugins-official` | Submission via [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit). |

## Hosting a marketplace on GitHub

Minimum repo structure:

```
my-marketplace-repo/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── plugin-one/
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   └── plugin-two/
│       ├── .claude-plugin/plugin.json
│       └── agents/
└── README.md
```

Push to GitHub. Users add with:

```
/plugin marketplace add owner/repo
/plugin install plugin-one@<marketplace-name>
```

### Pin to branch or tag

```
/plugin marketplace add https://github.com/owner/repo.git#v1.0.0
```

## Single-plugin repos (flat layout)

If the repo contains only one plugin, put everything at the root. The marketplace entry uses `"source": "./"` and `strict: false`:

```
my-plugin-repo/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
├── agents/
└── README.md
```

```json
{
  "name": "my-plugin-marketplace",
  "owner": { "name": "You" },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./",
      "strict": false,
      "description": "..."
    }
  ]
}
```

With `strict: false`, the marketplace entry is the authority for component paths. If the repository also has a `plugin.json` that declares components, loading fails with a conflicting-manifests error, so keep component declarations in one place. A flat layout suits a repository that holds exactly one plugin: the `"./"` source registers every root `agents/`, `commands/`, `workflows/`, and hook.

## Several entries in one repository

A marketplace entry without a `plugin.json` is the manifest, and it accepts every `plugin.json` field (`skills`, `commands`, `agents`, `workflows`, an inline `hooks` object, `mcpServers`, `lspServers`, `userConfig`). Claude Code also scans the entry's `source` directory for the default locations.

| Layout | Result |
|---|---|
| One entry with `"source": "./"` that owns the root `agents/`, `commands/`, `workflows/`, and hooks | Registers each of them once |
| A second entry with `"source": "./"` | Registers every root agent, command, workflow, and hook again under its own name |
| Skill-only bundles with `"source": "./skills"` and paths like `./knowledge/solid` | Register only the listed skills, since `skills/` holds no agents, commands, workflows, or hooks |
| Self-contained plugins under `plugins/<name>/` with `"source": "./plugins/<name>"` | Each keeps its own components |

`"agents": []` does not stop the default scan, and neither does a placeholder file. Pick the source so that only one entry sees each root component directory. Skills in a bundle cannot link to files outside the source, because those files are not copied into the cache: keep links inside the bundle and give full URLs for anything else, such as a spec on GitHub.

## Semantic versioning

Follow `MAJOR.MINOR.PATCH`:

| Level | When to bump | Example |
|-------|--------------|---------|
| PATCH | Bug fix, internal refactor, docs-only change. No new behavior. | 2.1.0 -> 2.1.1 |
| MINOR | New skill, new agent, new hook, new configuration option. Backward-compatible. | 2.1.0 -> 2.2.0 |
| MAJOR | Removing a skill, renaming a skill, changing frontmatter schema, changing a hook event. Breaking. | 2.1.0 -> 3.0.0 |

**Key rule**: Claude Code decides whether to update based on the version field. If you change plugin content but do not bump the version, users do not see the changes because of caching.

### Where to set the version

- **In `plugin.json`**: the manifest is authoritative. If the plugin lives outside a marketplace, set it here.
- **In the marketplace entry**: if the plugin lives inside a marketplace directory, omit `version` from `plugin.json` and manage it in `marketplace.json` instead.
- **Never both**: when both are set, `plugin.json` wins, but the inconsistency is a maintenance trap.
- **Nowhere**: the version is the commit SHA of the installed directory (relative-path plugin in a git-hosted marketplace), or `unknown` for a local directory outside a git repository. Every new commit then counts as an update, which suits fast-moving internal plugins but gives users no stable release to pin. An explicit version pins users until you change it.

## Release workflow

1. Make changes to plugin content.
2. Bump the version in the authoritative location.
3. Update `CHANGELOG.md` with the new version and date.
4. Commit (message: `Release <plugin-name> <new-version>`).
5. Tag the release (`git tag v<new-version>`).
6. Push with tags (`git push && git push --tags`).
7. Users pick up the update via auto-update or `/plugin marketplace update <marketplace-name>` followed by `/reload-plugins`.

## Auto-updates

Claude Code can auto-update marketplaces and installed plugins at startup.

- Official Anthropic marketplaces have auto-update enabled by default.
- Third-party and local development marketplaces have auto-update disabled by default.
- Toggle per-marketplace via `/plugin` -> Marketplaces tab -> select marketplace -> Enable/Disable auto-update.

### Environment overrides

| Variable                  | Effect                                                                                   |
|---------------------------|------------------------------------------------------------------------------------------|
| `DISABLE_AUTOUPDATER=1`   | Disables all Claude Code and plugin auto-updates.                                        |
| `FORCE_AUTOUPDATE_PLUGINS=1` | With `DISABLE_AUTOUPDATER=1`, keeps plugin auto-updates but disables Claude Code updates. |

## Team marketplace configuration

Teams can preconfigure a marketplace for everyone in a project by adding it to `.claude/settings.json`. When team members trust the folder, Claude Code prompts them to install the listed marketplaces and plugins.

```json
{
  "extraKnownMarketplaces": {
    "my-team-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  }
}
```

To also force-install specific plugins, pair `extraKnownMarketplaces` with an `enabledPlugins` entry (see the [settings docs](https://code.claude.com/docs/en/settings#plugin-settings)).

## Plugin caching and file resolution

- Marketplace plugins are copied to `~/.claude/plugins/cache` on install. Each version is a separate directory.
- Old versions are marked orphaned on update and removed after 7 days, so concurrent sessions can finish cleanly.
- **Paths outside the plugin directory (`../shared-utils`) do not work**, because the cache does not copy them.
- **Symlinks are preserved** by the cache, so use `ln -s /path/to/external ./link-name` if you need to share files across plugins. They are resolved at runtime on the user's machine.
- `${CLAUDE_PLUGIN_ROOT}` is the version directory (`cache/<marketplace>/<plugin>/<version>/`) and changes on each update. For a `"./"` entry it is a full copy of the repository.
- `${CLAUDE_PLUGIN_DATA}` survives updates. See [Uninstall and plugin data](#uninstall-and-plugin-data).
- A marketplace added by local path loads plugins in place, and the root is the source directory.

## Uninstall and plugin data

`${CLAUDE_PLUGIN_DATA}` resolves to `~/.claude/plugins/data/<plugin>-<marketplace>/`. It is created on first reference and survives updates. Claude Code deletes it when the plugin is uninstalled from its last scope, unless the user runs `claude plugin uninstall --keep-data`. Treat it as a cache that can disappear. The variable is substituted in skill and agent Markdown, hook commands, and MCP and LSP configs, and exported to hook and server processes, but it is not set in the environment of commands Claude runs through the Bash tool.

Do not store user or project choices there or in `${CLAUDE_PLUGIN_ROOT}`. Use the layered `.code-virtuoso` config summarized in [plugin-manifest.md](plugin-manifest.md#persistent-user-and-project-choices).

## Workflows and bin

- Plugin workflows (`workflows/*.js`) run as `/plugin:name` on paid plans. A script must start with a pure-literal `export const meta = { name, description }` whose name equals the file name. In `plugin.json`, a `workflows` key replaces the default `workflows/` directory.
- Files in `bin/` are added to the Bash tool's `PATH` while the plugin is enabled (Claude Code 2.1.91 or later), after the user's own entries. They must be executable and have a shebang. claude.ai and Cowork do not install a plugin that has a `bin/` directory.

## Codex

Codex reads `.claude-plugin/marketplace.json`, so skills in the same marketplace install through `codex plugin marketplace add owner/repo`. Codex plugins cannot ship agents. Publish agents as generated TOML files that users copy into `~/.codex/agents/` or `.codex/agents/`. Hooks, workflows, and `userConfig` are Claude Code features and have no Codex equivalent. Source: [Package your plugin](https://developers.openai.com/plugins/build/plugins).

## Validation before release

Run before pushing:

```
claude plugin validate
```

This checks:
- `plugin.json` schema and syntax
- Skill/agent/command frontmatter
- `hooks/hooks.json` syntax and event names
- Relative path safety
- Reserved name violations

Also run `claude --plugin-dir ./my-plugin` with `--debug` to surface runtime errors that static validation misses:

```
claude --plugin-dir ./my-plugin --debug
```

## Common distribution mistakes

| Mistake                                                           | Consequence                                                          |
|-------------------------------------------------------------------|----------------------------------------------------------------------|
| Forgetting to bump the version                                    | Users never see your changes because of caching.                     |
| Relative plugin sources + URL-distributed marketplace             | "Path not found" errors on install. Switch to `github`/`url`/`npm` source. |
| Hard-coded absolute paths in hooks or MCP configs                 | Works locally, breaks for everyone else. Use `${CLAUDE_PLUGIN_ROOT}`.|
| Reserved marketplace name                                         | Installation rejected. Pick a different name.                        |
| Pushing without tagging                                           | Users cannot pin to a specific version. Always tag releases.         |
| Breaking change without MAJOR bump                                | Users on auto-update hit unexpected failures.                        |
| Force-pushing a tag                                               | Cache may retain the old content. Always bump the version instead.   |
| A second marketplace entry with `"source": "./"`                  | Every root agent, command, workflow, and hook registers again. Use `"./skills"` for skill-only bundles. |
| Saving user or project choices under `${CLAUDE_PLUGIN_DATA}`      | Deleted on uninstall unless `--keep-data`. Use the layered config.   |
| Expecting `${CLAUDE_PLUGIN_ROOT}` to be stable                    | It changes with every version. Never write state there.              |
| Leaving `version` unset and expecting stable releases             | The commit SHA is the version, so every commit is an update.         |

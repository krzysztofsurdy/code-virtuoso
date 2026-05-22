# Plugin Distribution

How to get a plugin into users' hands: hosting options, versioning rules, update mechanics, and team marketplace configuration.

## Distribution Options

| Option                          | How users add it                                    | Best for                                                  |
|---------------------------------|-----------------------------------------------------|-----------------------------------------------------------|
| Standalone directory            | `claude --plugin-dir ./my-plugin`                   | Local development and testing only.                       |
| GitHub marketplace              | `/plugin marketplace add owner/repo`                | Open-source distribution. Most common.                    |
| Generic Git marketplace         | `/plugin marketplace add https://gitlab.com/.../x.git` | GitLab, Bitbucket, self-hosted git.                    |
| Local marketplace               | `/plugin marketplace add ./path/to/marketplace`     | Teams with shared network drives or monorepo plugins.     |
| URL-hosted `marketplace.json`   | `/plugin marketplace add https://example.com/x.json` | Custom hosting. Relative plugin sources do NOT resolve.   |
| Official Anthropic marketplace  | Already installed. `/plugin install <name>@claude-plugins-official` | Submission via [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit). |

## Hosting a Marketplace on GitHub

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

## Single-Plugin Repos (Flat Layout)

If the repo contains only one plugin, it is common to put everything at the root. The marketplace entry uses `"source": "./"` and `strict: false`:

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

With `strict: false`, the marketplace entry is the authority for component paths. This is necessary when `plugin.json` and the plugin content share the repo root.

## Semantic Versioning

Follow `MAJOR.MINOR.PATCH`:

| Level | When to bump | Example |
|-------|--------------|---------|
| PATCH | Bug fix, internal refactor, docs-only change. No new behavior. | 2.1.0 -> 2.1.1 |
| MINOR | New skill, new agent, new hook, new configuration option. Backward-compatible. | 2.1.0 -> 2.2.0 |
| MAJOR | Removing a skill, renaming a skill, changing frontmatter schema, changing a hook event. Breaking. | 2.1.0 -> 3.0.0 |

**Key rule**: Claude Code decides whether to update based on the version field. If you change plugin content but do not bump the version, users do not see the changes due to caching.

### Where to set the version

- **In `plugin.json`** - the manifest is authoritative. If the plugin lives outside a marketplace, set it here.
- **In the marketplace entry** - if the plugin lives inside a marketplace directory, omit `version` from `plugin.json` and manage it in `marketplace.json` instead.
- **Never both** - when both are set, `plugin.json` wins, but the inconsistency is a maintenance trap.

## Release Workflow

1. Make changes to plugin content.
2. Bump the version in the authoritative location.
3. Update `CHANGELOG.md` with the new version and date.
4. Commit (message: `Release <plugin-name> <new-version>`).
5. Tag the release (`git tag v<new-version>`).
6. Push with tags (`git push && git push --tags`).
7. Users pick up the update via auto-update or `/plugin marketplace update <marketplace-name>` followed by `/reload-plugins`.

## Auto-Updates

Claude Code can auto-update marketplaces and installed plugins at startup.

- Official Anthropic marketplaces have auto-update **enabled by default**.
- Third-party and local development marketplaces have auto-update **disabled by default**.
- Toggle per-marketplace via `/plugin` -> Marketplaces tab -> select marketplace -> Enable/Disable auto-update.

### Environment overrides

| Variable                  | Effect                                                                                   |
|---------------------------|------------------------------------------------------------------------------------------|
| `DISABLE_AUTOUPDATER=1`   | Disables all Claude Code and plugin auto-updates.                                        |
| `FORCE_AUTOUPDATE_PLUGINS=1` | With `DISABLE_AUTOUPDATER=1`, keeps plugin auto-updates but disables Claude Code updates. |

## Team Marketplace Configuration

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

## Plugin Caching and File Resolution

- Marketplace plugins are copied to `~/.claude/plugins/cache` on install. Each version is a separate directory.
- Old versions are marked orphaned on update and removed after 7 days, letting concurrent sessions finish cleanly.
- **Paths outside the plugin directory (`../shared-utils`) do not work** - the cache does not copy them.
- **Symlinks are preserved** by the cache, so use `ln -s /path/to/external ./link-name` if you truly need cross-plugin sharing. Resolved at runtime on the user's machine.
- `${CLAUDE_PLUGIN_DATA}` survives updates; `${CLAUDE_PLUGIN_ROOT}` changes on each update.

## Validation Before Release

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

Also run `claude --plugin-dir ./my-plugin` with `--debug` to surface runtime errors not caught by static validation:

```
claude --plugin-dir ./my-plugin --debug
```

## Common Distribution Mistakes

| Mistake                                                           | Consequence                                                          |
|-------------------------------------------------------------------|----------------------------------------------------------------------|
| Forgetting to bump the version                                    | Users never see your changes due to caching.                         |
| Relative plugin sources + URL-distributed marketplace             | "Path not found" errors on install. Switch to `github`/`url`/`npm` source. |
| Hard-coded absolute paths in hooks or MCP configs                 | Works locally, breaks for everyone else. Use `${CLAUDE_PLUGIN_ROOT}`.|
| Reserved marketplace name                                         | Installation rejected. Pick a different name.                        |
| Pushing without tagging                                           | Users cannot pin to a specific version. Always tag releases.         |
| Breaking change without MAJOR bump                                | Users on auto-update hit unexpected failures.                        |
| Force-pushing a tag                                               | Cache may retain the old content. Always bump the version instead.   |

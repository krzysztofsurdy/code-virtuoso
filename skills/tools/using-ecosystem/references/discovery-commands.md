# Discovery commands

Commands to list installed skills, agents, and workflows before recommending anything. Pick the block for the harness in use.

## Contents

- [Claude Code](#claude-code)
- [Codex](#codex)
- [Other tools](#other-tools)
- [Building the index](#building-the-index)
- [Verifying availability](#verifying-availability)

## Claude Code

Skills:

```bash
find ~/.claude/skills .claude/skills ~/.claude/plugins/cache -name "SKILL.md" 2>/dev/null
```

Agents:

```bash
ls ~/.claude/agents/*.md .claude/agents/*.md 2>/dev/null
find ~/.claude/plugins/cache -maxdepth 5 -path "*/agents/*.md" 2>/dev/null
```

Workflows:

- Run `/workflows` to list the workflow scripts Claude Code can see. A plugin workflow runs as `/<plugin>:<name>`, for example `/agents-virtuoso:review-squad`.
- In a checkout of the repository, `ls workflows/*.js` lists them. Each file starts with a `meta` block holding `name`, `description`, and `whenToUse`.
- Plugin installs: `find ~/.claude/plugins/cache -maxdepth 6 -path "*/workflows/*.js" 2>/dev/null`.

Plugins: `/plugin` shows what is installed. `loop-virtuoso` is a separate plugin, so check for it before recommending the delivery loop.

For each skill, read the first lines for `name`, `description`, `user-invocable`, and `disable-model-invocation`. For each agent, read `name`, `description`, `tools`, `isolation`, and `skills`.

## Codex

```bash
find ~/.agents/skills .agents/skills -name "SKILL.md" 2>/dev/null
ls ~/.codex/agents/*.toml .codex/agents/*.toml 2>/dev/null
```

Codex scans `.agents/skills` from the working directory up to the repository root, plus `~/.agents/skills`. Custom agents are TOML files in `.codex/agents/` or `~/.codex/agents/`, and each is identified by its `name` field. Skills installed through a Codex plugin show in the Plugins Directory instead. Codex has no workflow scripts, so use the recipes in `agent-orchestration` (`references/teams.md`) for the review squad, development team, and war room.

## Other tools

Look in the tool's skill and agent folders (for example `.cursor/agents/`, `.agents/skills/`, or the folder named in its docs) and read the same frontmatter fields. If the tool has no folder for skills, ask the user what they have installed.

## Building the index

After scanning, keep a short index:

| Name | Type | When to use (from description) |
|---|---|---|

Sort workflows first, then agents, then skills, so the higher-coordination options surface first when matching.

## Verifying availability

Before recommending an item:

1. Confirm it appeared in the scan.
2. If it did not, say it is not installed and name the plugin or skill that provides it.
3. For plugin items, note which plugin they came from.

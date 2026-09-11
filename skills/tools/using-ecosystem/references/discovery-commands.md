# Discovery commands

Shell commands to scan installed skills, agents, and teams at runtime. Run these to build a live index before making recommendations.

## Skills

Scan all locations where skills may be installed:

```bash
# User-level skills
find ~/.claude/skills -name "SKILL.md" 2>/dev/null

# Project-level skills
find .claude/skills -name "SKILL.md" 2>/dev/null

# Plugin-installed skills
find ~/.claude/plugins/cache -name "SKILL.md" 2>/dev/null
```

For each found `SKILL.md`, read the first 10 lines to extract `name`, `description`, and `user-invocable` from the YAML frontmatter.

## Agents

```bash
# User-level agents
ls ~/.claude/agents/*.md 2>/dev/null

# Project-level agents
ls .claude/agents/*.md 2>/dev/null

# Plugin-installed agents
find ~/.claude/plugins/cache -maxdepth 5 -path "*/agents/*.md" 2>/dev/null
```

For each found agent file, read the YAML frontmatter to extract `name`, `description`, `tools`, `isolation`, and `skills`.

## Teams

Teams ship bundled inside the `dispatching-agent-teams` skill, and users can author their own at the project root.

```bash
# User-authored project teams
ls teams/*.md 2>/dev/null
ls .claude/teams/*.md 2>/dev/null

# Bundled teams (inside the dispatching skill)
find ~/.claude/plugins/cache -maxdepth 6 -path "*/agent-teams/teams/*.md" 2>/dev/null

# Any team files anywhere in plugin cache
find ~/.claude/plugins/cache -maxdepth 6 -path "*/teams/*.md" 2>/dev/null
```

For each found team file, read the YAML frontmatter to extract `name`, `description`, `lead`, `agents`, `skills`, and `workflow`.

## Building the index

After scanning, build an index with three columns:

| Name | Type | When to use (from description) |
|---|---|---|

Sort by type (teams first, then agents, then skills) so that higher-coordination options surface first when matching.

## Verifying availability

Before recommending any skill, agent, or team:

1. Confirm it appeared in the scan results
2. If it did not appear, suggest installing it rather than recommending it as available
3. For plugin-installed items, note which plugin they came from

# Agent Specification

This document defines the conventions for agents in the Code Virtuoso marketplace. Agents are sub-agents - standalone markdown files that define a specialized role, its allowed tools, and its system prompt.

For a guided, interactive design flow, use the `agent-creator` skill. This spec is the reference for reviewers and contributors.

## Location

Agents live at the top level of the repository in the `agents/` directory:

```
agents/
  investigator.md
  reviewer.md
  implementer.md
  ...
```

One file per agent. The file name matches the `name` field in the frontmatter.

Role skills that pair with a role agent live in `skills/roles/{name}/`, and the agent file references the role skill via `skills:` in its frontmatter. Agents are not nested inside skill directories.

## File Format

Agent files use YAML frontmatter followed by a Markdown body. The body is the agent's system prompt.

### Frontmatter

```yaml
---
name: agent-name
description: What this agent does. Delegate when {trigger condition}.
tools: Read, Grep, Glob, Bash
isolation: worktree
memory: project
skills:
  - relevant-skill-name
---
```

#### Required fields

| Field | Description |
|-------|-------------|
| `name` | Kebab-case identifier, lowercase letters and hyphens only. Matches the file name without `.md`. |
| `description` | What the agent does and when to delegate to it. Include trigger phrases an orchestrator can match. |
| `tools` | Comma-separated allowlist of tools the agent can use. Set explicitly - never rely on inheritance. |

#### Optional fields

| Field | Description |
|-------|-------------|
| `disallowedTools` | Comma-separated denylist applied before `tools` resolves. |
| `isolation` | Set to `worktree` when the agent creates or modifies source files. Omit for read-only agents. |
| `memory` | Persistent memory scope: `user`, `project`, or `local`. Use for role agents that benefit from cross-session context. |
| `skills` | List of skill names (by `name` field, not path) to preload into the agent's context at startup. |
| `mcpServers` | MCP servers scoped to this agent. Use inline definitions to keep tool descriptions out of the parent conversation. |
| `permissionMode` | Override for how the agent handles permission prompts. Use sparingly. |
| `hooks` | Lifecycle hooks scoped to this agent. |
| `maxTurns` | Cap on the number of agentic turns before the agent stops. |
| `expects` | List of artifact type names this agent requires as input. See [artifacts.md](artifacts.md) for the catalog. |
| `produces` | List of artifact type names this agent outputs. See [artifacts.md](artifacts.md) for the catalog. |

#### Fields intentionally omitted

- **`model`** - Do not hardcode provider-specific model identifiers. Model selection is a user or platform concern. Agents in this repository must be portable.

#### Portability

Only `name`, `description`, `skills`, `expects`, and `produces` are portable across agent platforms. Other fields are platform-specific extensions (see [platforms reference](../skills/tools/agent-creator/references/platforms.md)). When authoring an agent for cross-platform use, keep the body portable and adapt frontmatter when porting.

### Body Content

The body is the agent's system prompt. It follows a five-section contract:

```markdown
You are a [role]. You [one-sentence responsibility].

## Input
What the agent receives when delegated to.

## Process
1. Numbered steps the agent runs through (3-7 steps).
2. Each step is an action verb.

## Rules
- Constraints and guardrails.
- Short imperatives, not paragraphs.

## Output
A concrete template, not a description. Shows exactly what the agent returns.
```

Keep the body portable:

- Do not duplicate the tool list from the frontmatter
- Do not reference specific AI providers in the prose
- Do not include persona bloat or filler preamble

See [system-prompts reference](../skills/tools/agent-creator/references/system-prompts.md) for patterns and worked examples.

## Archetypes

Agents fall into three archetypes. The archetype determines tool permissions, isolation, and memory defaults.

| Archetype | Scope | Isolation | Memory | Example tools |
|---|---|---|---|---|
| **Specialist** | Single repeatable task | Only when modifying files | Stateless | Read, Grep, Glob, Bash |
| **Role** | Entire domain of responsibility | Only for dev roles | Often `project` | Read, Grep, Glob, Bash (+ Edit, Write for dev roles) |
| **Team-Lead** | Coordinates parallel workers | No (delegates) | Stateless | Read, Grep, Glob, Bash, Agent(...) |

See [archetypes reference](../skills/tools/agent-creator/references/archetypes.md) for worked examples and anti-patterns.

## Handoff Contracts

Agents can declare what artifacts they expect as input and what artifacts they produce as output. These declarations help orchestrators and teams verify that workflows chain correctly.

```yaml
expects:
  - investigation-report
produces:
  - architecture-decision
```

Both fields are optional. When present, they reference artifact types defined in [artifacts.md](artifacts.md). Agents should handle missing artifacts gracefully - the contract is a signal, not a hard gate. See the artifact spec for the full catalog and guidelines.

## Conventions

- One agent file per role
- Reference skills by their `name` field, not by file path
- Keep the system prompt focused and actionable
- Define clear workflows for each type of task the agent handles
- Use an output template, not prose
- Trim tool allowlists to the minimum that lets the workflow finish
- Read-only by default - add write tools only when the agent legitimately modifies files

## Tuning (Optional)

Agents whose behavior meaningfully varies by team preference can include a `## Tuning` section in their body. This follows the supplement pattern: on first activation, the agent asks the user a short questionnaire (3-5 questions) about their preferences, saves the answers alongside the agent file as a `.tune.md` supplement, and reuses them on subsequent activations.

### When to include tuning

- The agent has 3+ behavioral knobs that vary by team (e.g., review depth, output format, framework context)
- Different teams would reasonably want different defaults
- The settings are stable enough to reuse across sessions

Do not add tuning for agents where behavior is fixed by design (e.g., investigator, cold-reviewer).

### Tune file convention

- File name: `.{agent-name}.tune.md` (dot-prefixed to stay out of agent discovery scans)
- Location: alongside the agent file in the same directory
- Format: simple `KEY: value` pairs, one per line, with a header comment
- Created by the agent on first activation via interactive questions
- Editable by the user at any time; deletable to re-run setup

### How to add tuning to an agent

1. Add a `## Tuning` section to the agent body listing available knobs with defaults
2. In the Process, add a first step: "Check for `.{agent-name}.tune.md` alongside this file. If missing, ask the team preference questions and save. If present, load silently."
3. Reference knobs as `$VARIABLE_NAME` throughout the process and rules

See the [tuning reference](../skills/tools/agent-creator/references/tuning.md) for the full pattern and examples.

## Naming Conventions

- Lowercase letters, digits, and hyphens only
- Starts with a letter
- Describes the role (e.g. `reviewer`, `migration-planner`), not the task (e.g. `review-pr-123`)
- File name matches the `name` field (e.g. `migration-planner.md`)
- Avoid generic names (`agent1`, `helper`, `assistant`)

## Marketplace Registration

Every agent is registered in `.claude-plugin/marketplace.json`:

- Specialist agents go into the `agents-virtuoso` plugin and an individual `agent-{name}` plugin
- Role agents go into `agents-virtuoso`, the matching `role-{name}` plugin, and the role skill is paired with the agent

Example:

```json
{
  "name": "agent-reviewer",
  "description": "...",
  "source": "./",
  "agents": ["./agents/reviewer.md"]
}
```

Bump the marketplace `metadata.version`:

- Patch for content edits to an existing agent
- Minor for a new agent
- Major for rename, restructure, or breaking changes

## Validation

Run through the validation checklist before committing: [validation reference](../skills/tools/agent-creator/references/validation.md).

The most common rejection reasons:

- Description lacks trigger phrases
- Tool allowlist is missing or overly permissive
- Agent modifies files but has no `isolation: worktree`
- Output section is vague prose instead of a template
- Body contains provider-specific or tool-specific phrasing

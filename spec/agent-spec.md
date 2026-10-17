# Agent Specification

This document defines the conventions for agents in the Code Virtuoso marketplace. Agents are sub-agents - standalone markdown files that define a specialized role, its allowed tools, and its system prompt.

For a guided, interactive design flow, use the `agent-creator` skill. This spec is the reference for reviewers and contributors.

## Contents

- [Location](#location)
- [File format](#file-format)
- [Archetypes](#archetypes)
- [Handoff contracts](#handoff-contracts)
- [Conventions](#conventions)
- [Tuning (optional)](#tuning-optional)
- [Naming conventions](#naming-conventions)
- [Marketplace registration](#marketplace-registration)
- [Validation](#validation)

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

A role agent has no paired skill. Its templates, checklists, and guides live in `roles/{name}/` at the repository root, and the agent body points to them by path. They are plain files without frontmatter, so nothing loads them until the agent opens one. Agents are not nested inside skill directories.

## File format

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
| `isolation` | Set to `worktree` when the agent changes source code. Omit for read-only agents, documentation-only writers, and planning roles that run in place. |
| `memory` | Persistent memory scope: `user`, `project`, or `local`. Use for role agents that benefit from cross-session context. |
| `skills` | List of skill names (by `name` field, not path) to preload into the agent's context at startup. See [Skill preloading](#skill-preloading). |
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

### Body content

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

### Skill preloading

Preload at most four skills, and only skills the agent needs on every run. Names resolve against every installed plugin, not only the agent's own. Checked on Claude Code 2.1.306 with a plugin agent that preloads `security` while the skill ships in a different plugin:

| Setup | Result |
|---|---|
| Bare name (`security`), the plugin that holds the skill is installed | Preloaded into the subagent |
| Scoped name (`knowledge-virtuoso:security`), that plugin is installed | Preloaded |
| Skill's plugin not installed, or the name is wrong | Nothing is preloaded and there is no error or warning |
| Subagent started by the Agent tool, or by a skill with `context: fork` and `agent:` | Preloaded |
| Agent run as the main session (`claude --agent`) | Preloaded skills were not injected. Subagents spawned with the Agent tool get them |

So a missing skill fails silently. Agents must work without their preloads (the preload adds guidance, it is never the only copy of an instruction the agent cannot do without), and bundles that preload from another bundle should say which bundle to install. Prefer bare names: they keep working when a skill moves between bundles.

## Archetypes

Agents fall into three archetypes. The archetype determines tool permissions, isolation, and memory defaults.

| Archetype | Scope | Isolation | Memory | Example tools |
|---|---|---|---|---|
| **Specialist** | Single repeatable task | Only when modifying files | Stateless | Read, Grep, Glob, Bash |
| **Role** | Entire domain of responsibility. The agent plus its `roles/{name}/` references | Only for dev roles | Often `project` | Read, Grep, Glob, Bash (+ Edit, Write for dev roles) |
| **Team-Lead** | Coordinates parallel workers | No (delegates) | Stateless | Read, Grep, Glob, Bash, Agent(...) |

See [archetypes reference](../skills/tools/agent-creator/references/archetypes.md) for worked examples and anti-patterns.

## Handoff contracts

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
- Pair `Edit` and `Write` with `isolation: worktree` when the agent changes source code. Documentation-only writers and planning roles that write only planning documents may run in place
- A role agent reads its `roles/{name}/` files by path. Do not create a role skill for it

## Tuning (optional)

Agents whose behavior varies by team preference can include a `## Tuning` section in their body. Settings live in the layered Code Virtuoso config under `agents.<agent-name>`, as defined in [config-spec.md](config-spec.md). The agent reads them and never prompts, because subagents cannot ask the user. A setup run in the main session asks the questions (3-5) and writes the answers.

### When to include tuning

- The agent has 3+ behavioral knobs that vary by team (e.g., review depth, output format, framework context)
- Different teams would reasonably want different defaults
- The settings are stable enough to reuse across sessions

Do not add tuning for agents where behavior is fixed by design (e.g., investigator, cold-reviewer).

### Config convention

- Namespace: `agents.{agent-name}` in the layered config (user, project shared, project local)
- Keys: camelCase (e.g., `reviewDepth`), one JSON value per key
- Location: never next to the agent file. That directory is a replaceable cache in plugin installs. See [config-spec.md](config-spec.md) for paths and precedence
- Team-wide choices go to the project shared file (`.code-virtuoso/config.json`), personal choices to the user file
- Missing keys use the defaults in the agent's Tuning table. When any key is missing, the agent ends its report with: `Defaults used for: <keys>. Run setup to save them.`
- Settings are editable by the user at any time. Never store secrets

### How to add tuning to an agent

1. Add a `## Tuning` section to the agent body listing the keys with options and defaults, plus the steps for reading `agents.{agent-name}` from the layered config
2. In the Process, add a first step: "Read `agents.{agent-name}` from the layered config. Never ask the user. Use the default for any missing key."
3. Reference the keys by name (e.g., `reviewDepth`) throughout the process and rules

See the [tuning reference](../skills/tools/agent-creator/references/tuning.md) for the full pattern and examples.

## Naming conventions

- Lowercase letters, digits, and hyphens only
- Starts with a letter
- Describes the role (e.g. `reviewer`, `migration-planner`), not the task (e.g. `review-pr-123`)
- File name matches the `name` field (e.g. `migration-planner.md`)
- Avoid generic names (`agent1`, `helper`, `assistant`)

## Marketplace registration

Every agent is registered in the `agents` list of the `agents-virtuoso` entry in `.claude-plugin/marketplace.json`. That entry uses `"source": "./"` because agents and workflows live at the repository root. Skill-only bundles use `"source": "./skills"` so they do not register the root `agents/` directory a second time.

Wrapper skills that run an agent with `agent: agents-virtuoso:{name}` ship in the same entry, so the agent and its wrapper install together.

Bump the marketplace `metadata.version`:

- Patch for content edits to an existing agent
- Minor for a new agent
- Major for rename, restructure, or breaking changes

## Validation

Run through the validation checklist before committing: [validation reference](../skills/tools/agent-creator/references/validation.md).

The most common rejection reasons:

- Description lacks trigger phrases
- Tool allowlist is missing or overly permissive
- Agent changes source code but has no `isolation: worktree`
- Output section is vague prose instead of a template
- Body contains provider-specific or tool-specific phrasing

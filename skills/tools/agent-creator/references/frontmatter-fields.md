# Agent Frontmatter Fields

Frontmatter is the only metadata read before the agent is invoked. Treat it as a contract with the orchestrator: `name` identifies the agent, `description` triggers delegation, and the rest shapes what happens once the agent runs.

## Contents

- [Portability](#portability)
- [Field reference](#field-reference)
- [Field combinations to validate](#field-combinations-to-validate)
- [Example templates](#example-templates)

## Portability

Only five fields are portable across agent platforms:

| Portable | Platform-specific |
|---|---|
| `name` | `tools`, `disallowedTools` |
| `description` | `model`, `isolation`, `memory` |
| `skills` | `mcpServers`, `hooks`, `permissionMode` |
| `expects` | `color`, `effort`, `background`, `maxTurns` |
| `produces` | |

Write the body to be portable. Adapt platform-specific frontmatter when moving the agent between platforms. Codex plugins cannot ship agents, so this library generates Codex agent files from the Markdown agents with `python3 scripts/build-codex-agents.py`. The generator keeps `name`, `description`, and the body, and drops the rest.

Plugin agents in Claude Code ignore `hooks`, `mcpServers`, and `permissionMode`. Put hooks in the plugin's `hooks/hooks.json` and MCP servers in its `.mcp.json`, or place the agent in `.claude/agents/` if it needs these fields.

## Field reference

### `name` (required)

A unique kebab-case identifier. Matches the filename without the `.md` extension.

```yaml
name: migration-planner
```

Rules:

- Lowercase letters, digits, and hyphens only
- Start with a letter
- Describe the role, not the task (`reviewer`, not `review-this-pr`)
- Keep it short (one or two hyphenated words is ideal)

### `description` (required)

The only field read during delegation decisions. Every word should earn its place.

Format: `{what it does}. {when to delegate}.`

Good:

```yaml
description: Read-only deep exploration of a specific codebase area. Delegate when you need structured investigation of how something works, where something is used, or what a subsystem does.
```

Bad:

```yaml
description: An agent that helps with code.
```

Patterns that work:

- Include trigger phrases the orchestrator can match ("delegate when", "use after", "invoke for")
- Name the output shape when it is a key differentiator ("returns prioritised findings with severity")
- Mention constraints that prevent mis-use ("read-only", "runs in a worktree")

Avoid:

- Marketing adjectives ("powerful", "full", "advanced")
- Redundant self-reference ("this agent is an agent that...")
- Anything the orchestrator cannot verify from the description alone

### `tools` (platform-specific, strongly recommended)

An allowlist of tools the agent can use. Omitting it inherits everything from the caller, which is rarely what you want.

```yaml
tools: Read, Grep, Glob, Bash
```

See [tool-selection.md](tool-selection.md) for per-archetype defaults and the decision tree.

### `disallowedTools` (platform-specific, optional)

A denylist applied before the allowlist resolves. Use it when you want "everything except writes":

```yaml
disallowedTools: Write, Edit
```

If both `tools` and `disallowedTools` are set, the denylist wins for overlapping entries.

### `skills` (portable, optional)

Skills whose content is injected into the agent's context at startup. Sub-agents do not inherit skills from the caller, so list them explicitly.

```yaml
skills:
  - security
  - debugging
```

Rules:

- Reference skills by bare `name`, not path. Bare names resolve across every installed plugin, so they keep working when a skill moves between bundles
- Include one to four skills. More is usually wasted context
- Only include skills the agent needs on every run. Anything it needs sometimes belongs in a reference file it opens by path
- A skill that is not installed, or whose name is wrong, is skipped with no error. The agent must work without its preloads, and a bundle that preloads from another bundle should say which one to install
- Skills marked run-by-name (`disable-model-invocation: true`) cannot be preloaded
- Preloads are injected when the agent starts as a subagent. They were not injected when the agent runs as the main session (`claude -p --agent`)
- Do not preload a role skill. Roles have none: a role agent reads files from `roles/<role>/` by path

### `model` (platform-specific, optional, discouraged)

Do not hardcode provider-specific model identifiers in shared agent definitions. Model selection is a user or platform concern.

If you must set it (e.g. for a local personal agent that should always use a fast model):

```yaml
model: haiku
```

For distributable agents (marketplace, team-shared, plugin), omit the field entirely and let the caller or platform decide.

### `isolation` (platform-specific, optional)

Set to `worktree` when the agent changes source code. The agent operates on a temporary copy of the repository, and the orchestrator reviews changes before merging.

```yaml
isolation: worktree
```

Leave unset for read-only agents, for documentation-only writers, and for planning roles that write only planning documents. Those run in place.

### `memory` (platform-specific, optional)

Gives the agent a persistent directory that survives across sessions.

```yaml
memory: project
```

Setting `memory` also enables the Read, Write, and Edit tools for the agent, so it can manage its notes. An agent with `memory` is therefore not read-only, whatever its `tools` list says. If auto memory is turned off, the field has no effect.

Scopes:

| Scope | Directory | Use when |
|---|---|---|
| `user` | `~/.claude/agent-memory/<name>/` | Agent should remember learnings across all your projects |
| `project` | `.claude/agent-memory/<name>/` | Agent's knowledge is project-specific and shareable via version control |
| `local` | `.claude/agent-memory-local/<name>/` | Agent's knowledge is project-specific but should not be committed |

`project` is the default for role agents that accumulate context.

### `mcpServers` (platform-specific, optional)

Gives the agent access to MCP servers the main conversation does not have. Use it for tools that should stay scoped to this one agent (e.g. a Playwright server for a browser-testing agent). Ignored for plugin agents.

```yaml
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  - github
```

### `permissionMode` (platform-specific, optional)

Overrides how the agent handles permission prompts. Use sparingly. A permissive mode inside a sub-agent undermines the caller's safety posture. Ignored for plugin agents.

| Mode | Behaviour |
|---|---|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits in the working directory |
| `plan` | Read-only plan mode |
| `bypassPermissions` | Skip prompts. Use with great care |

### `hooks` (platform-specific, optional)

Lifecycle hooks scoped to this agent. Common uses: require passing tests before the agent goes idle, and block certain tool calls before they run. Ignored for plugin agents.

### `maxTurns` (platform-specific, optional)

Cap on the number of agentic turns before the agent stops. Use it for agents that can loop, such as a reviewer that keeps finding "one more thing".

### `expects` and `produces` (portable, optional)

Lists of artifact type names from the artifact catalog (`spec/artifacts.md` in this repository). They document what the agent takes in and hands back so orchestrators and team recipes can check that steps chain. Harnesses ignore them: nothing validates or enforces the contract at run time. The body must still say what to do when an expected artifact is missing.

```yaml
expects:
  - investigation-report
produces:
  - architecture-decision
```

### `color`, `effort`, `background`, `initialPrompt` (platform-specific, optional)

UX and runtime conveniences. Omit unless you have a specific need. `initialPrompt` is ignored for plugin agents.

## Field combinations to validate

| Combination | Why it matters |
|---|---|
| `isolation: worktree` without any write tools | Agent cannot modify anything, so remove the isolation |
| `memory` set but the agent is meant to be read-only | `memory` enables Write and Edit. Drop the memory or accept the write access |
| `Write`/`Edit` in `tools` on an agent that changes source code, without `isolation: worktree` | Agent edits the main tree before review. Documentation-only writers and planning roles may run in place |
| `memory: project` on a stateless specialist | Wasted complexity, so remove the memory field |
| `skills` naming a run-by-name skill or a role skill | Cannot be preloaded, or does not exist. Point the body at reference files by path |
| `hooks`, `mcpServers`, or `permissionMode` on an agent that ships in a plugin | Ignored. Move to the plugin or to `.claude/agents/` |
| `skills` list longer than four entries | Context bloat, so trim to the essentials |
| `model` hardcoded in a distributable agent | Non-portable, so remove it |
| `permissionMode: bypassPermissions` on anything shared | Safety risk, so justify or remove |

## Example templates

### Stateless specialist (read-only)

```yaml
---
name: example-reviewer
description: {what} Delegate when {trigger}.
tools: Read, Grep, Glob, Bash
skills:
  - testing
  - security
---
```

### Source-code specialist

```yaml
---
name: example-implementer
description: {what} Delegate when {trigger}.
tools: Read, Grep, Glob, Bash, Edit, Write
isolation: worktree
skills:
  - testing
---
```

### Role agent with memory

```yaml
---
name: example-role
description: {what} Delegate when {trigger}.
tools: Read, Grep, Glob, Bash
memory: project
skills:
  - supporting-skill
---
```

The body lists the files in `roles/example-role/` and when to open each one. `memory` lets this agent write its notes, and the body says it writes nothing else.

### Documentation writer (runs in place)

```yaml
---
name: example-doc-writer
description: {what} Delegate when {trigger}.
tools: Read, Grep, Glob, Bash, Edit, Write
---
```

The body limits writes to documentation files, so no worktree is needed.

### Team-lead that spawns specialists

```yaml
---
name: example-lead
description: {what} Delegate when {trigger}.
tools: Read, Grep, Glob, Bash, Agent(specialist-a, specialist-b)
---
```

# Platforms

Agent platforms differ in frontmatter fields, file locations, and how agents interact. This reference covers the ones most relevant when authoring portable agent definitions.

## Contents

- [Scope and priority](#scope-and-priority)
- [Claude Code](#claude-code)
- [Cursor](#cursor)
- [Codex / AGENTS.md convention](#codex--agentsmd-convention)
- [Generic / plain-Markdown platforms](#generic--plain-markdown-platforms)
- [Inter-agent communication](#inter-agent-communication)
- [Porting checklist](#porting-checklist)
- [Marketplace / plugin distribution](#marketplace--plugin-distribution)

## Scope and priority

Most platforms support multiple scopes for agent definitions. When names collide, the higher-priority scope wins.

| Scope | Use for | Commit to repo? |
|---|---|---|
| Managed / organisation | Org-wide agents deployed by admins | Yes (in managed settings repo) |
| Session / CLI-flag | One-off testing, automation scripts | No (ephemeral) |
| Project | Agents specific to this codebase | Yes |
| User / personal | Personal agents reused across projects | No (user home directory) |
| Plugin / marketplace | Agents shipped as distributable bundles | Yes (in plugin repo) |

Project scope is the right default for team-shared work. Personal scope is for individual preferences. Plugin scope is for redistribution.

## Claude Code

### Scope paths

| Scope | Path |
|---|---|
| Project | `.claude/agents/<name>.md` |
| User | `~/.claude/agents/<name>.md` |
| Plugin | Inside the plugin's `agents/` directory |
| Managed | `.claude/agents/` inside the managed settings directory |
| CLI | Passed via `--agents '{...}'` as JSON |

Project agents are discovered by walking up from the working directory. Restart the session or use `/agents` to load manually-added files.

### Frontmatter

All fields listed in [frontmatter-fields.md](frontmatter-fields.md) are supported. Plugin agents do not support `hooks`, `mcpServers`, or `permissionMode` for security reasons. Copy the agent to `.claude/agents/` if you need those.

### Interaction

- The orchestrator delegates by matching the agent's description against the task
- A sub-agent runs in its own context window and returns only its output
- Sub-agents cannot spawn other sub-agents, which prevents infinite nesting
- Agents running as the main thread (`claude --agent`) can spawn sub-agents via the `Agent(...)` tool

### Agent teams (experimental)

Claude Code also supports agent teams, where multiple teammates run in parallel and communicate with each other. Teammates can reference sub-agent definitions by name, inheriting their `tools` and `model`. When a sub-agent definition runs as a teammate:

- The definition's body is appended to the teammate system prompt as additional instructions, not as a replacement
- `skills` and `mcpServers` are not applied. The teammate loads them from project and user settings
- Team coordination tools remain available even when `tools` restricts others

If you want the same agent to work both as a sub-agent and as a teammate, keep the body self-contained and do not assume tools outside the allowlist are present.

## Cursor

Cursor is primarily an AI coding editor, not a sub-agent orchestrator. It has no direct sub-agent equivalent, but it supports:

- Rules files (`.cursor/rules/*.mdc`) for project-wide instructions
- Custom modes for different behaviours per session

If you want to bring a sub-agent definition into Cursor, convert it into a rules file by:

1. Dropping the frontmatter except for `description`
2. Writing the body as a `## [Agent Name] Mode` section in the rules file
3. Adding the trigger condition as guidance for when to apply that mode

See the `agentic-rules-writer` skill for producing these conversions.

## Codex / AGENTS.md convention

The `AGENTS.md` convention (used by OpenAI Codex and several other agents) is a single Markdown file at the project root that contains all agent-related guidance. It is a flat document, not a sub-agent registry in the Claude Code sense.

To port a sub-agent definition to an `AGENTS.md`-driven platform:

1. Add a `## [Agent Name]` section to `AGENTS.md`
2. Copy the role statement, Input, Process, Rules, and Output under that section
3. Note the trigger condition from the original `description` as the section's first paragraph

## Generic / plain-Markdown platforms

Many platforms (Windsurf, Copilot, Gemini CLI, Cline, Continue, Trae, Roo Code, Amp, Goose, Augment, Kilo Code) read a single plain-Markdown instructions file. To use a sub-agent definition there:

1. Flatten the frontmatter. Keep only the portable `name`, `description`, and body
2. Write the body as a section in the instructions file
3. Describe how the user should invoke the agent ("When you want an investigation, say 'investigate X'")

This loses delegation and context isolation but keeps the structured prompt.

## Inter-agent communication

### Sub-agent model (most platforms)

- The caller delegates with a prompt
- The sub-agent works in its own context
- The sub-agent returns output
- The caller integrates it

Sub-agents do not talk to each other.

### Agent-team model (Claude Code experimental, similar multi-agent frameworks)

- A lead coordinates multiple teammates
- Teammates can message each other directly
- Shared task lists coordinate work
- Each teammate is a full, independent session

Design for sub-agent mode by default. Move to team mode only when parallel exploration or adversarial debate adds real value. The token cost is much higher.

## Porting checklist

Before distributing an agent across platforms:

- [ ] Body is platform-portable (no tool names, no provider-specific phrasing)
- [ ] Tool permissions expressed in frontmatter, not duplicated in the body
- [ ] Description has trigger phrases the target platform will actually match
- [ ] `model` omitted (users configure it per platform)
- [ ] Isolation and memory documented in the agent's README if you ship one
- [ ] File name matches the `name` frontmatter field

## Marketplace / plugin distribution

If you ship the agent as part of a plugin or marketplace bundle, also do the following:

- Registering the agent in the plugin's manifest (`marketplace.json`, `plugin.json`, or equivalent)
- Versioning the plugin when the agent changes (patch for content, minor for new agent, major for breaking)
- Updating the plugin's README to list the agent and its purpose
- Pairing the agent with any skills it preloads, so installing the plugin makes both available

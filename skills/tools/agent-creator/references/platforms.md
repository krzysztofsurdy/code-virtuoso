# Platforms

Agent platforms differ in frontmatter fields, file locations, and how agents interact. This reference covers the ones most relevant when authoring portable agent definitions.

## Contents

- [Scope and priority](#scope-and-priority)
- [Claude Code](#claude-code)
- [Cursor](#cursor)
- [Codex](#codex)
- [Generic / plain-Markdown platforms](#generic--plain-markdown-platforms)
- [Inter-agent communication](#inter-agent-communication)
- [Porting checklist](#porting-checklist)
- [Plugin and marketplace distribution](#plugin-and-marketplace-distribution)

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

All fields listed in [frontmatter-fields.md](frontmatter-fields.md) are supported, except that plugin agents ignore `hooks`, `mcpServers`, `permissionMode`, and `initialPrompt` for security reasons. Copy the agent to `.claude/agents/` if you need those, or put hooks and MCP servers in the plugin itself. Setting `memory` also enables Read, Write, and Edit for the agent.

Preloaded `skills` resolve by bare name across all installed plugins, are skipped silently when the skill is missing, and cannot include run-by-name skills (`disable-model-invocation: true`). They were not injected when an agent ran as the main session (`claude -p --agent`).

### Interaction

- The orchestrator delegates by matching the agent's description against the task
- A sub-agent runs in its own context window and returns only its output
- Sub-agents cannot spawn other sub-agents, which prevents infinite nesting
- Agents running as the main thread (`claude --agent`) can spawn sub-agents via the `Agent(...)` tool

### Teams

A team in this library is a workflow: a Markdown recipe plus a script in `workflows/`, run as `/<plugin>:<name>`. It needs no team config file, and there is no `TeamCreate` tool. See the `agent-orchestration` skill and `spec/team-spec.md` in the repository.

Claude Code also has experimental agent teams, enabled with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, where teammates run in parallel and message each other. The lead spawns each teammate with the `Agent` tool and a `name`. Teammates can reference sub-agent definitions by name, inheriting their `tools` and `model`. When a sub-agent definition runs as a teammate:

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

## Codex

Codex runs custom agents from standalone TOML files in `~/.codex/agents/` (personal) or `.codex/agents/` (project). Each file defines `name`, `description`, and `developer_instructions`, and Codex identifies the agent by `name`. Codex plugins cannot ship agents, so agents install separately from the plugin that carries the skills. Codex also reads `AGENTS.md` at the project root for general instructions.

In this library you do not write the TOML. `python3 scripts/build-codex-agents.py` generates `codex/agents/<name>.toml` from each `agents/<name>.md`, and `scripts/install-codex-agents.sh` copies them into place. The conversion keeps `name` and `description`, uses the body as `developer_instructions`, drops `tools`, `skills`, and `isolation`, and rewrites `${CLAUDE_PLUGIN_ROOT}` to `${CODE_VIRTUOSO_HOME}`. Agents with no `Edit` or `Write` and no `memory` get "Do not modify files." added, which is an instruction and not a sandbox. Run the script with `--check` to see whether the generated files are out of date, and never edit the TOML by hand.

Codex subagents are managed by the parent session, which spawns them and relays results. They do not message each other.

Sources: [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents).

## Generic / plain-Markdown platforms

Many platforms (Windsurf, which is now Devin Desktop, Copilot, Antigravity CLI, Cline, Continue, Trae, Roo Code, Amp, Goose, Augment, Kilo Code) read plain-Markdown instruction files. To use a sub-agent definition there:

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

Codex has no peer messaging. For a recipe that fans out, the parent session spawns the agents and relays their results.

Design for sub-agent mode by default. Move to team mode only when parallel exploration or adversarial debate adds real value. The token cost is much higher.

## Porting checklist

Before distributing an agent across platforms:

- [ ] Body is platform-portable (no tool names, no provider-specific phrasing)
- [ ] Tool permissions expressed in frontmatter, not duplicated in the body
- [ ] Description has trigger phrases the target platform will actually match
- [ ] `model` omitted (users configure it per platform)
- [ ] Isolation is set only when the agent changes source code, and `memory` is a deliberate choice because it grants Write and Edit
- [ ] File name matches the `name` frontmatter field

## Plugin and marketplace distribution

If you ship the agent in a Claude Code plugin:

- Place the file in the plugin's `agents/` directory. The plugin entry (or the root entry that owns `agents/`) picks it up. In this library, the `agents-virtuoso` entry (source `./`) lists every agent
- Remember that an entry with the repository root as its source registers every agent in `agents/`. Skill-only bundles use a narrower source such as `./skills`
- Version the plugin when the agent changes (patch for content, minor for a new agent, major for breaking changes)
- List the agent in the README and AGENTS tables, and run `python3 scripts/build-codex-agents.py` so Codex users get it too
- If the agent preloads skills from another bundle, say which bundle to install, because a missing skill is skipped silently

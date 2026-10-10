# Platform notes

Verified 2026-10-21 against the vendor docs listed under each platform. Orchestration features change fast, so check the linked page when a detail matters. The rest of this skill stays platform-neutral, this file is where tool names and limits live.

## Contents

- [What each platform offers](#what-each-platform-offers)
- [Claude Code](#claude-code)
- [Codex](#codex)
- [Cursor](#cursor)
- [Windsurf](#windsurf)
- [Other tools](#other-tools)

## What each platform offers

| Capability | Claude Code | Codex | Cursor | Windsurf |
|---|---|---|---|---|
| Subagents with own context | Yes | Yes | Yes | Devin Local agent, preview toggle. Cascade has none |
| Parallel subagents | Yes | Yes | Yes | With the Devin Local agent |
| Peer messaging between agents | Yes, in agent teams (experimental) | Not documented | Not documented | Not documented |
| Shared task list | Yes, in agent teams, model dependent | Not documented | Not documented | Not documented |
| Per-agent filesystem isolation | Worktree option | Not documented for subagents | Worktree or cloud VM per subagent | Worktree sessions |
| Scripted, repeatable orchestration | Plugin and project workflows | No | No | Markdown slash-command workflows (single agent) |

"Not documented" means the vendor docs describe no such feature. Assume it is absent and fall back to parent-managed subagents.

## Claude Code

Sources: https://code.claude.com/docs/en/agent-teams.md, /sub-agents.md, /workflows.md, /worktrees.md, /tools-reference.md, /cross-session-messaging.md.

### Subagents

The parent calls the Agent tool. A subagent returns its result to the caller. A subagent that was given a `name` can be addressed later with `SendMessage`. Plugin subagents are addressed by scoped name, for example `agents-virtuoso:cold-reviewer`. Plugin subagents ignore the `hooks`, `mcpServers`, and `permissionMode` frontmatter fields.

### Worktree isolation starts from the default branch

A subagent with `isolation: worktree` gets a worktree that branches from the repository's default branch (`origin/HEAD`), not from the caller's current commit. Work that builds on unmerged changes will not see them. Fixes:

- Set `worktree.baseRef` to `"head"` in settings so new worktrees branch from your current HEAD.
- Or merge or push what the agent needs first.
- With no remote, or no cached `origin/HEAD`, Claude Code falls back to your local HEAD.

### Agent teams (experimental)

Teams are off by default. Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in the environment or in `settings.json`.

| Fact | Detail |
|---|---|
| How a team forms | There is no team-creation tool. The lead calls the Agent tool with a `name` while the flag is on, and that subagent launches as a teammate. Exceptions: a fork, or a call that passes `isolation` on the call itself |
| Side effect of the flag | Every named subagent becomes a teammate, including ones Claude names on its own. Set the variable to `0` to get ordinary subagents back, no restart needed |
| Messaging | Teammates message each other by name with `SendMessage`. `ListAgents` exists only where cross-session messaging is enabled (Claude Code v2.1.224 or later) |
| Shared task list | `TaskCreate`, `TaskGet`, `TaskList`, `TaskUpdate`. Default only on Opus 4.7, Sonnet 4.6, Haiku 4.5, and earlier models. On newer models set `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` before starting, or teammates coordinate by messages only |
| Using agent definitions | A teammate named after an agent definition gets its `tools`, `model`, and body (appended to the system prompt). It does not get the definition's `skills`, and the definition's `isolation` is not applied |
| Consequence | Restate the skills a teammate needs in its spawn prompt. Split files between teammates yourself, because there is no per-teammate worktree |
| Context | A teammate loads project context (CLAUDE.md, skills, MCP) but not the lead's conversation. Put task detail in the spawn prompt |
| Permissions | Teammates start with the lead's permission mode, and prompts surface in the lead session |
| Limits | One team per session. No nested teams. The lead is fixed. In-process teammates are not restored by `/resume` or `/rewind`. Interactive sessions only, so no teams in `claude -p` or the SDK (a named subagent there runs as an ordinary subagent) |
| Quality gates | Hooks: `TeammateIdle` (exit 2 keeps the teammate working), `TaskCreated` and `TaskCompleted` (exit 2 blocks and sends feedback) |
| Runtime files | `~/.claude/teams/{team}/config.json` holds runtime state. Do not author it. A project-level `.claude/teams/teams.json` is not recognized |
| Cost | Each teammate is a full session, so tokens scale with team size. Docs suggest 3 to 5 teammates and 5 to 6 tasks per teammate |

Teams fit work where teammates must talk: competing-hypothesis debugging, parallel review with cross-challenge, cross-layer features. For independent fan-out where only results matter, use subagents or a workflow.

### Plugin and project workflows

A workflow is a script the runtime executes, so the plan lives in code and intermediate results stay out of your context.

| Fact | Detail |
|---|---|
| Availability | All paid plans, the Anthropic API, Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry. On Pro, enable "Dynamic workflows" in `/config`. No experimental flag |
| Where files live | `workflows/` at a plugin root, or `.claude/workflows/` in a project |
| How to run | A plugin workflow named `review-squad` in plugin `agents-virtuoso` runs as `/agents-virtuoso:review-squad`. Progress shows in `/workflows` |
| Script contract | First statement is `export const meta = {name, description, whenToUse?, phases?}` as a pure literal. The body is plain JavaScript with top-level `await`, using `agent()`, `parallel()`, `pipeline()`, `phase()`, `log()`, and the `args` global |
| Agent options | `label`, `phase`, `schema` (JSON Schema, returns validated JSON), `agentType` (a registered subagent, plugin ones by scoped name), `isolation: 'worktree'`, `model`, `effort` |
| Forbidden | `Date.now()`, `Math.random()`, no-argument `new Date()` (they throw, so runs can resume), and `import()` |
| Limits | 16 concurrent agents by default, 1,000 agents per run, 4,096 items per `parallel()` or `pipeline()` call |
| No user input | A run cannot ask you questions mid-run. For sign-off between stages, run each stage as its own workflow |
| Headless | Works with `claude -p` and the SDK. Allow it with a `Workflow` or `Workflow(<name>)` permission rule |
| Failure | `agent()` resolves to `null` if stopped or on an unrecoverable error. `parallel()` and `pipeline()` keep the `null`, so filter before use |

Pick a workflow over a team when the control flow is known in advance: fan out, verify, merge. Pick a team when the next step depends on what teammates tell each other.

## Codex

Source: https://learn.chatgpt.com/docs/agent-configuration/subagents.md

- Current Codex releases enable subagent workflows by default. Codex spawns subagents when you ask, or when `AGENTS.md` or a skill asks for delegation. Say how to split the work, whether to wait for all agents, and what each should return.
- The parent manages everything: spawning, routing follow-up instructions, waiting, and closing threads. The docs describe no peer messaging between subagents and no shared task list.
- Built-in agents: `default`, `worker`, `explorer`. Custom agents are standalone TOML files in `.codex/agents/` (project) or `~/.codex/agents/` (personal), each with `name`, `description`, and `developer_instructions`, plus optional `model` and `model_reasoning_effort`.
- Subagents inherit the parent's sandbox, approvals, provider, and MCP servers. A custom agent file cannot override them, and an instruction like "do not edit files" does not create a read-only sandbox.
- Settings live under `[agents]` in `config.toml`: `enabled`, `max_concurrent_threads_per_session`, `default_subagent_model`, `default_subagent_reasoning_effort`.
- The docs advise parallel agents for read-heavy work (exploration, tests, triage) and care with parallel writes, because agents editing at once create conflicts. They describe no per-subagent worktree, so partition files strictly.

To use this repo's agents in Codex, copy each agent's description and body into a TOML file's `description` and `developer_instructions`.

## Cursor

Source: https://cursor.com/docs/subagents.md

- Subagents run in the editor, the CLI, and cloud agents. Each has its own context and returns a final message to the parent.
- Custom subagents are Markdown with YAML frontmatter in `.cursor/agents/` or `~/.cursor/agents/`. Cursor also reads `.claude/agents/` and `.codex/agents/` for compatibility, so this repo's agent files load as they are. `.cursor/` wins on a name clash.
- Subagents run in the foreground (blocks) or background (`is_background: true`). The parent launches several at once by sending multiple Task calls in one message.
- Each subagent gets its own environment and branch, either a local git worktree or a cloud VM, and changes stay there until the parent merges them.
- A subagent can be resumed by its agent ID. Since Cursor 2.5 a subagent can launch child subagents, but a child cannot launch further ones.
- No peer messaging or agent-team feature is documented.

## Windsurf

Source: https://docs.windsurf.com/llms.txt and the Devin Local agent page linked from it.

- Cascade, the original agent, has no subagents. It runs several sessions side by side, supports parallel work in git worktrees, and has Markdown workflows that are saved prompts for one agent, not multi-agent scripts.
- The Devin Local agent inside Windsurf can spawn subagents in the foreground or background. It is gated by a "Subagents (Preview)" toggle, and custom subagents are Markdown files under an `agents/` directory.
- No peer messaging or shared task list is documented. Treat this section as likely to change and recheck before relying on it.

## Other tools

For any other harness, check three things in its docs before choosing a mode: can the parent spawn isolated subagents, can it run several at once, and can they write without colliding (worktrees or clones). If none is documented, run the sequential or inline form of each pattern, see [teams.md](teams.md).

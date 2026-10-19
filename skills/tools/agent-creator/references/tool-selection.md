# Tool Selection

Sub-agents inherit every tool the caller has unless you say otherwise. That is almost never what you want. Start from the minimum set and add tools only when the workflow cannot finish without them.

## Contents

- [The decision tree](#the-decision-tree)
- [Per-archetype defaults](#per-archetype-defaults)
- [Denylist pattern](#denylist-pattern)
- [MCP tool scoping](#mcp-tool-scoping)
- [Common mistakes](#common-mistakes)
- [Tool name portability](#tool-name-portability)

## The decision tree

Work through these questions in order. Add a tool only when the answer is yes.

1. **Does the agent need to read files?** -> `Read`
2. **Does the agent need to search text?** -> `Grep`
3. **Does the agent need to find files by pattern?** -> `Glob`
4. **Does the agent need to run commands** (tests, audits, linters, git)? -> `Bash`
5. **Does the agent need to edit existing files?** -> `Edit`. Set `isolation: worktree` when those files are source code
6. **Does the agent need to create new files?** -> `Write`. Set `isolation: worktree` when those files are source code
7. **Does the agent keep notes across sessions?** -> set `memory`. Claude Code then enables Read, Write, and Edit on its own, so the agent gains write access without you listing it
8. **Does the agent need to fetch external documentation?** -> `WebFetch`, `WebSearch`
9. **Does the agent need to spawn other agents?** -> `Agent(...)` with an allowlist of agent types
10. **Does the agent need MCP tools?** -> Scope them via `mcpServers` instead of inheriting them (not available to plugin agents)

Stop at the lowest level that lets the agent finish its job.

## Per-archetype defaults

### Investigator / Explorer

```yaml
tools: Read, Grep, Glob, Bash
```

Bash is for running read-only analysis (`git log`, `git blame`, `find`). No Edit or Write.

### Reviewer / Auditor

```yaml
tools: Read, Grep, Glob, Bash
```

Same as investigator. Reviewers report findings; they do not fix.

### Dependency Auditor

```yaml
tools: Read, Grep, Glob, Bash
```

Bash runs `npm audit`, `composer audit`, `pip-audit`, etc. Still read-only.

### Documentation Writer

```yaml
tools: Read, Grep, Glob, Bash, Edit, Write
```

No worktree: the agent touches documentation only, so it runs in place. Limit write permissions with system prompt rules: "only modify files under `docs/` or files matching `*.md`, `CHANGELOG*`, `README*`". Add `isolation: worktree` if the agent may also touch code.

### Implementer / Dev Role

```yaml
tools: Read, Grep, Glob, Bash, Edit, Write
isolation: worktree
```

Isolation is non-negotiable for agents that change source code. The orchestrator reviews and merges.

### Planner / Architect

```yaml
tools: Read, Grep, Glob, Bash
```

Planners do not implement. A role such as an architect may write its design documents, ADRs, and memory notes in place: give it `Edit` and `Write` (or `memory`) and state in the body that it never touches source code. Reads of its templates come from `roles/<role>/` files by path.

### Team-Lead / Coordinator

```yaml
tools: Read, Grep, Glob, Bash, Agent(worker-a, worker-b)
```

The `Agent(...)` allowlist restricts which sub-agent types the lead can spawn. Without it, the lead can spawn anything the platform exposes, which is rarely what you want. Use plugin-scoped names for plugin agents (`agents-virtuoso:reviewer`). If the roster, phases, and gates are the same every run, write a team workflow instead of a lead agent.

## Denylist pattern

Sometimes it is simpler to say "everything except writes":

```yaml
disallowedTools: Write, Edit
```

Use this when:

- The agent is a generalist that needs broad read access but must stay read-only
- The agent inherits many MCP tools and you only want to block specific ones

Avoid this when:

- A short allowlist can express the intent. Allowlists are clearer to audit

## MCP tool scoping

If the agent needs an MCP server the main conversation does not need, define it inline in `mcpServers`. That keeps tool descriptions out of the parent context. Plugin agents ignore `mcpServers`: ship the server in the plugin's `.mcp.json` or place the agent in `.claude/agents/`.

```yaml
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
```

The parent conversation does not pay for `playwright`'s tool descriptions, and the agent gets exclusive access.

## Common mistakes

| Mistake | Consequence |
|---|---|
| Inheriting all tools by omitting `tools` | Agent can do anything the caller can, which breaks least privilege |
| Giving an investigator `Write` "just in case" | Scope creep; reviewers start editing |
| Allowing `Bash` without thinking about which commands will run | A Bash-enabled agent can do anything a shell can, including `rm -rf` |
| Missing `isolation: worktree` on an agent that changes source code | Changes land in the main tree before review |
| Forgetting that `memory` grants Write and Edit | A "read-only" reviewer with memory can edit files. Drop the memory or say so in the body |
| Putting `hooks`, `mcpServers`, or `permissionMode` on a plugin agent | Ignored. Configure them in the plugin or place the agent in `.claude/agents/` |
| Letting a team-lead spawn anything via bare `Agent` | Unexpected sub-agent types may be spawned. Pin with `Agent(a, b)` |
| Hardcoding MCP tools in the parent when only one agent needs them | Parent pays for tool descriptions it never uses |

## Tool name portability

Tool names are not standardised across agent platforms. The examples in this skill use Claude Code tool names. When moving an agent to another platform, map them:

| Capability | Claude Code | Other platforms |
|---|---|---|
| Read files | `Read` | May be called `read_file`, `open`, `view` |
| Search text | `Grep` | May be `search`, `ripgrep`, `find_in_files` |
| Search files | `Glob` | May be `find_files`, `list_files` |
| Shell commands | `Bash` | May be `shell`, `run_command`, `terminal` |
| Edit files | `Edit` | May be `edit_file`, `patch`, `apply_diff` |
| Create files | `Write` | May be `write_file`, `create_file` |
| Web fetch | `WebFetch` | May be `fetch_url`, `browse`, `http_get` |
| Spawn sub-agent | `Agent(...)` | May be `delegate`, `spawn_agent` |

Keep the intent in the agent's system prompt portable and adapt the frontmatter tool names when porting. For Codex, `scripts/build-codex-agents.py` drops `tools` and adds "Do not modify files." to agents that have no `Edit` or `Write` and no `memory`. That line is an instruction, not a sandbox.

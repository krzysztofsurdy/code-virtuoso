# Tool Selection

Sub-agents inherit every tool the caller has unless you say otherwise. That is almost never what you want. Start from the minimum set and add tools only when the workflow cannot complete without them.

## The Decision Tree

Walk through these questions in order. Add a tool only when the answer is yes.

1. **Does the agent need to read files?** -> `Read`
2. **Does the agent need to search text?** -> `Grep`
3. **Does the agent need to find files by pattern?** -> `Glob`
4. **Does the agent need to run commands** (tests, audits, linters, git)? -> `Bash`
5. **Does the agent need to edit existing files?** -> `Edit` (and set `isolation: worktree`)
6. **Does the agent need to create new files?** -> `Write` (and set `isolation: worktree`)
7. **Does the agent need to fetch external documentation?** -> `WebFetch`, `WebSearch`
8. **Does the agent need to spawn other agents?** -> `Agent(...)` with an allowlist of agent types
9. **Does the agent need MCP tools?** -> Scope them via `mcpServers`, do not silently inherit

Stop at the lowest level that lets the agent finish.

## Per-Archetype Defaults

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
isolation: worktree
```

Write permissions scoped via system prompt rules: "only modify files under `docs/` or files matching `*.md`, `CHANGELOG*`, `README*`".

### Implementer / Dev Role

```yaml
tools: Read, Grep, Glob, Bash, Edit, Write
isolation: worktree
```

Isolation is non-negotiable. The orchestrator reviews and merges.

### Planner / Architect

```yaml
tools: Read, Grep, Glob, Bash
```

Planners do not implement. If they need to produce an ADR file, they can write that through a doc-writer specialist instead.

### Team-Lead / Coordinator

```yaml
tools: Read, Grep, Glob, Bash, Agent(worker-a, worker-b)
```

The `Agent(...)` allowlist restricts which sub-agent types the lead can spawn. Without it, the lead can spawn anything the platform exposes, which is rarely intended.

## Denylist Pattern

Sometimes it is easier to say "everything except writes":

```yaml
disallowedTools: Write, Edit
```

Use this when:

- The agent is a generalist that needs broad read access but must stay read-only
- The agent inherits many MCP tools and you only want to block specific ones

Avoid this when:

- You can express the intent with a short allowlist instead - allowlists are clearer to audit

## MCP Tool Scoping

If the agent needs an MCP server the main conversation does not need, define it inline in `mcpServers`. This keeps tool descriptions out of the parent context.

```yaml
mcpServers:
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
```

The parent conversation does not pay for `playwright`'s tool descriptions, and the agent gets exclusive access.

## Common Mistakes

| Mistake | Consequence |
|---|---|
| Inheriting all tools by omitting `tools` | Agent can do anything the caller can - no principle of least privilege |
| Giving an investigator `Write` "just in case" | Scope creep; reviewers start editing |
| Allowing `Bash` without considering what commands get run | A Bash-enabled agent can do anything a shell can, including `rm -rf` |
| Missing `isolation: worktree` on an Edit-capable agent | Changes land in the main tree before review |
| Letting a team-lead spawn anything via bare `Agent` | Unexpected sub-agent types may be spawned - pin with `Agent(a, b)` |
| Hardcoding MCP tools in the parent when only one agent needs them | Parent pays for tool descriptions it never uses |

## Tool Name Portability

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

Keep the intent in the agent's system prompt portable; adapt the frontmatter tool names when porting.

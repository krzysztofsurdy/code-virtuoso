# Pipelines and participants

`pipelines.json` defines reusable **participants** (the roles a step can run as) and **pipelines** (named, ordered groups of participants used as a compile-time template). It is optional: a backlog whose steps name no `participant` runs fine without it, there is just no role framing.

The word "pipeline" is used on purpose. Code Virtuoso already has agent teams (see the `agent-teams` skill), and a loop pipeline is something else: an ordered list of steps' roles, not a group of agents that talk to each other.

## Project file and user file

Participants and pipelines can live in two places, checked in this order:

1. **Project** - `<git root>/.code-virtuoso/loop/pipelines.json`, committed, shared with the team. Specific to one repository.
2. **User** - `${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json`. Personal, shared across every project on the machine, never in a repository.

A participant or pipeline defined in the project file wins if the same name exists in both; anything not found there falls back to the user file. Define your usual roles once in the user file, and every backlog can reference them by name. A project that needs a one-off variant overrides just that name in its own file.

A step references a participant by name: `"participant": "backend-dev"`. The engine resolves that name against `pipelines.json` at run time and frames the step's prompt accordingly. An unknown or omitted name means no framing.

Earlier versions kept the user file at `~/.claude/loop-virtuoso/teams.json` and the project file at `.delivery-loop/teams.json`, with a `teams` key. `/loop-virtuoso:start` copies or moves both to the new places and renames the key once; nothing reads the old paths afterwards.

## Participant kinds

A participant is one of two kinds.

### `agent` - delegate to an existing subagent

Hands the step to a Claude Code subagent that already exists in the environment.

```json
{ "kind": "agent", "agent": "agents-virtuoso:backend-dev" }
```

Use the installed, scoped name (`agents-virtuoso:<name>`). A bare name such as `backend-dev` is accepted: the loop resolves it to `agents-virtuoso:backend-dev` when the `agents-virtuoso` plugin is installed and ships an agent with that file name, and uses the bare name unchanged otherwise (for example a custom agent in `.claude/agents`). A name that already contains a colon is never rewritten. The step prompt and Mode B's `--agent` flag both get the resolved name.

The step prompt instructs the worker to delegate to that subagent (via the Task tool in Mode A, or a real `--agent` invocation in Mode B - see the Mode A/B fidelity note in `iteration-loop/SKILL.md`).

**Worktree-isolated agents (Mode B, open gap).** Some subagents (for example `backend-dev`, `frontend-dev`, `implementer` in `agents-virtuoso`) declare `isolation: worktree` in their own frontmatter - they do their work in a separate git worktree, not the checkout the verify gate grades. Mode A's prompt tells the delegating session to merge that worktree back into the checkout before ending its turn, which works because the delegating session itself isn't isolated. Mode B's `--agent` flag runs the named agent as the *top-level* process for that iteration, so there's no non-isolated outer session left to do the merge - whether that process can (or does) merge its own worktree back before exiting is unverified. Until this is confirmed, avoid `backend-dev`/`frontend-dev`/`implementer` (or any agent with `isolation: worktree`) as agent-kind participants under Mode B; they're fine under Mode A, and read-only agents (`reviewer`, `qa-engineer`, `investigator`, `acceptance-verifier`, and similar) aren't affected under either mode since they declare `isolation: none`.

### `persona` - an inline custom role

Defines the role inline, no pre-existing subagent needed.

```json
{
  "kind": "persona",
  "systemPrompt": "You are a meticulous reviewer. Reject anything not covered by a test.",
  "allowedTools": ["Read", "Grep", "Bash(vendor/bin/* *)"]
}
```

## Pipelines are templates, not runtime objects

A pipeline groups participant names into an ordered list:

```json
{ "description": "Build then independently review", "members": ["backend-dev", "qa-reviewer"] }
```

`backlog-compiler` can expand a pipeline into an item's steps (one step per member, in order). The engine never sees pipelines - it only ever runs participants, one step at a time. A pipeline exists purely to save you repeating the same participant sequence across items.

## Minimal `pipelines.json`

```json
{
  "participants": {
    "backend-dev": { "kind": "agent", "agent": "agents-virtuoso:backend-dev" },
    "qa-reviewer": {
      "kind": "persona",
      "systemPrompt": "You are a meticulous reviewer. Reject anything not covered by a test.",
      "allowedTools": ["Read", "Grep", "Bash(vendor/bin/* *)"]
    }
  },
  "pipelines": {
    "build-and-review": { "description": "Build then independently review", "members": ["backend-dev", "qa-reviewer"] }
  }
}
```

Keep it small - a couple of participants is plenty to start. Add more only when a backlog genuinely needs distinct roles owning distinct phases.

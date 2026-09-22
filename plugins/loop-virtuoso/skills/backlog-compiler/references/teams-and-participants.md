# Teams and participants

`.delivery-loop/teams.json` defines reusable **participants** (the roles a step can run as) and **teams** (named, ordered groups of participants used as a compile-time template). It is optional: a backlog whose steps name no `participant` runs fine without it — there's just no role framing.

## Project-local vs. global

Participants and teams can live in two places, checked in this order:

1. **Project-local** — `.delivery-loop/teams.json`, next to that project's `backlog.json`. Specific to one project.
2. **Global** — `~/.claude/loop-virtuoso/teams.json`. Shared across every project on the machine.

A participant or team defined in the project-local file wins if the same name exists in both; anything not found locally falls back to the global library. This means you can define your usual roles (`backend-dev`, `qa-reviewer`, whatever your stack's team actually looks like) once in the global file, and every project's backlog can reference them by name without redefining them — while a project that needs a one-off variant can still override just that name locally.

A step references a participant by name: `"participant": "backend-dev"`. The engine resolves that name against `teams.json` at run time and frames the step's prompt accordingly. An unknown or omitted name means no framing.

## Participant kinds

A participant is one of two kinds.

### `agent` — delegate to an existing subagent

Hands the step to a Claude Code subagent that already exists in the environment.

```json
{ "kind": "agent", "agent": "backend-dev" }
```

The step prompt instructs the worker to delegate to that subagent (via the Task tool in Mode A, or a real `--agent` invocation in Mode B — see the Mode A/B fidelity note in `iteration-loop/SKILL.md`).

**Worktree-isolated agents (Mode B, open gap).** Some subagents (e.g. `backend-dev`, `frontend-dev`, `implementer` in `agents-virtuoso`) declare `isolation: worktree` in their own frontmatter — they do their work in a separate git worktree, not the checkout the verify gate grades. Mode A's prompt tells the delegating session to merge that worktree back into the checkout before ending its turn, which works because the delegating session itself isn't isolated. Mode B's `--agent` flag runs the named agent as the *top-level* process for that iteration, so there's no non-isolated outer session left to do the merge — whether that process can (or does) merge its own worktree back before exiting is unverified. Until this is confirmed, avoid `backend-dev`/`frontend-dev`/`implementer` (or any agent with `isolation: worktree`) as agent-kind participants under Mode B; they're fine under Mode A, and read-only agents (`reviewer`, `qa-engineer`, `investigator`, `acceptance-verifier`, and similar) aren't affected under either mode since they declare `isolation: none`.

### `persona` — an inline custom role

Defines the role inline, no pre-existing subagent needed.

```json
{
  "kind": "persona",
  "systemPrompt": "You are a meticulous reviewer. Reject anything not covered by a test.",
  "allowedTools": ["Read", "Grep", "Bash(vendor/bin/* *)"]
}
```

## Teams are templates, not runtime objects

A team groups participant names into an ordered list:

```json
{ "description": "Build then independently review", "members": ["backend-dev", "qa-reviewer"] }
```

`backlog-compiler` can expand a team into an item's steps (one step per member, in order). The engine never sees teams — it only ever runs participants, one step at a time. "Team" exists purely to save you repeating the same participant sequence across items.

## Minimal `.delivery-loop/teams.json`

```json
{
  "participants": {
    "backend-dev": { "kind": "agent", "agent": "backend-dev" },
    "qa-reviewer": {
      "kind": "persona",
      "systemPrompt": "You are a meticulous reviewer. Reject anything not covered by a test.",
      "allowedTools": ["Read", "Grep", "Bash(vendor/bin/* *)"]
    }
  },
  "teams": {
    "build-and-review": { "description": "Build then independently review", "members": ["backend-dev", "qa-reviewer"] }
  }
}
```

Keep it small — a couple of participants is plenty to start. Add more only when a backlog genuinely needs distinct roles owning distinct phases.

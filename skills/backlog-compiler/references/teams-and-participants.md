# Teams and participants

`.delivery-loop/teams.json` defines reusable **participants** (the roles a step can run as) and **teams** (named, ordered groups of participants used as a compile-time template). It is optional: a backlog whose steps name no `participant` runs fine without it — there's just no role framing.

A step references a participant by name: `"participant": "backend-dev"`. The engine resolves that name against `teams.json` at run time and frames the step's prompt accordingly. An unknown or omitted name means no framing.

## Participant kinds

A participant is one of two kinds.

### `agent` — delegate to an existing subagent

Hands the step to a Claude Code subagent that already exists in the environment.

```json
{ "kind": "agent", "agent": "backend-dev" }
```

The step prompt instructs the worker to delegate to that subagent (via the Task tool in Mode A, or a real `--agent` invocation in Mode B — see the Mode A/B fidelity note in `iteration-loop/SKILL.md`).

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

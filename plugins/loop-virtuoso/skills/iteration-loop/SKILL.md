---
name: iteration-loop
description: Documents and orchestrates the autonomous execution loop over a .delivery-loop/backlog.json — session-supervised or unattended batch mode, both gated by deterministic verification rather than self-report. Use when asked to run, monitor, or explain the delivery loop, or after backlog-compiler has produced a backlog.
user-invocable: true
argument-hint: "[start|status|cancel]"
---

# Iteration Loop

Executes a `.delivery-loop/backlog.json` one step at a time. Each item is a sequence of steps; the loop advances by step, and an item is `verified` only when all of its steps are. The defining property of this loop, worth restating before anything else: **no agent — worker or reviewer — ever decides that a step is done.** A script runs the step's literal `verifyCommand` and checks its exit code; only that script writes status (item status is never stored — it is derived from the steps). This skill documents how to run the loop and what each outcome means; it does not itself judge completion.

## The two modes

| | Mode A — session-supervised | Mode B — unattended batch |
|---|---|---|
| Invoked via | `/loop-virtuoso:start` | `scripts/run-batch.sh path/to/backlog.json` |
| Runs | Inside your current Claude Code session, via a `Stop` hook | Fresh `claude -p` process per iteration |
| Use for | Watching it work, stepping away briefly, backlogs of 5-15 items | Large backlogs, overnight/CI runs |
| Stops automatically when | Backlog exhausted, blocked out, max iterations, stall, or violation limit | Same conditions, plus a cumulative cost cap and a usage/rate-limit guard |

Mode B is intentionally **not** a slash command — it spawns long-running detached processes that don't fit a single tool-call turn. Run it directly from a terminal, from CI, or from within a session via `claude --bg --exec "$(pwd)/scripts/run-batch.sh .delivery-loop/backlog.json"` if you want it tracked as a background job you can `claude logs`/`claude stop`.

### Participant fidelity differs between modes

A step's `participant` (see `backlog-compiler`) is honored with different strength in each mode — state this honestly, the two are not equivalent:

- **Mode B** spawns a fresh process per step, so it can pass real CLI flags — `--agent <name>` for an `agent` participant, `--append-system-prompt` for a `persona` — and that invocation genuinely runs as the participant.
- **Mode A** is one continuous session; it can't re-spawn itself per step. It can only ask the model to role-play the participant through the prompt text: delegate via the Task tool for an `agent` participant, or "act as: …" for a `persona`. That's a softer instruction, not a hard guarantee of isolation.

If a participant boundary needs to be real (genuinely isolated tools or system prompt per role), run that backlog in Mode B.

## Starting Mode A

`/loop-virtuoso:start [path-to-backlog]` (defaults to `.delivery-loop/backlog.json`) runs `scripts/setup-start.sh`, which:
1. Validates the backlog (`scripts/validate-backlog.sh`).
2. Archives a previous run if the branch changed (`scripts/archive-run.sh`).
3. Writes `.delivery-loop/session.local.json` — the only thing that arms the hooks in `hooks/hooks.json`. Without this file, both hooks no-op immediately and the plugin has zero effect on a normal session.
4. Prints the first step's prompt.

From there, every time you try to end the turn, the `Stop` hook in `hooks/stop-hook.sh` intercepts: it runs the verification gate against the step you just worked on, applies the result via `scripts/lib/backlog.sh`, and either feeds back the next step's prompt (`{"decision":"block","reason":...}`) or lets the session end because a stop-reason below was reached.

## Stopping early

`/loop-virtuoso:cancel` removes `.delivery-loop/session.local.json`. The backlog itself is untouched — items already `verified` stay `verified`, `pending` items stay `pending`, and a later `/loop-virtuoso:start` picks up where it left off.

## Checking progress

`/loop-virtuoso:status` (or `scripts/status.sh` directly) reports: items and steps verified/pending/blocked (per-step progress, since the loop advances by step), current iteration vs. `maxIterations`, consecutive stall/violation counts, cumulative cost if tracked, and the tail of `.delivery-loop/progress.log` — the durable, script-written audit trail (never written by the model).

## Visibility

Two records, written only by scripts, never the model:
- `.delivery-loop/progress.log` — human-readable, one summary line per iteration.
- `.delivery-loop/events.jsonl` — the machine-readable complete record: one JSON object per state transition (`run_started`, `step_verdict`, `item_verified`/`item_blocked`, `run_stopped`), each with a UTC timestamp. `tail -f` it or `jq` over it for full execution detail rather than relying on the summary.

## The write-boundary guard

Two layers, both documented in full in `references/write-boundary.md`:
1. A `PreToolUse` hook denies any Edit/Write aimed at `config.protectedPaths` or the backlog file itself, in real time, before the edit happens.
2. The verification gate diffs the working tree against the iteration's starting commit and checks every changed file against `protectedPaths`, regardless of which tool produced the change — the backstop nothing slips past.

This is why `config.allowedTools` can stay reasonably broad (see `backlog-compiler`'s stack defaults): the guard, not the allowlist, is what keeps the agent off its own grading files.

## Stop-reason state machine

Full detail in `references/stop-reasons.md`. Summary:

| Reason | Meaning | Backlog state after |
|---|---|---|
| `complete` | No pending items remain, none blocked | Session state removed, summary printed |
| `blocked_out` | No pending items remain, some are `blocked` | Session state removed, blocked items + last failures reported |
| `max_iterations` | Iteration count hit `config.maxIterations` | Preserved — rerun to continue |
| `stalled` | `maxStallIterations` consecutive iterations with an empty git diff | Preserved — investigate why no changes are being made |
| `violation_limit` | `maxViolations` cumulative protected-path violations | Preserved — investigate why the worker keeps targeting protected files |
| `corrupted` | State file or backlog.json failed to parse | Investigate manually before rerunning `/loop-virtuoso:start` |
| `total_budget_exceeded` *(Mode B only)* | Cumulative `total_cost_usd` hit `config.totalBudgetUsd` — reported under both API billing and a subscription, though it's not what actually limits a subscription plan | Preserved — rerun to continue |
| `invocation_failed` *(Mode B only)* | A `claude -p` call returned no usable result — under a subscription this is usually a usage/rate limit, which never surfaces as a cost figure | Preserved — rerun once the limit window resets |

## When to use this vs. running it yourself

Good fit: well-defined backlogs with objective, scriptable acceptance criteria — schema changes, endpoint implementations, component additions, dependency bumps, test-coverage gaps.

Bad fit: work whose "done" genuinely requires human judgment (visual design review, UX calls, architectural decisions), or a backlog item you couldn't write a `verifyCommand` for — if `backlog-compiler` couldn't turn a criterion into a command, don't run it through this loop; do it directly instead.

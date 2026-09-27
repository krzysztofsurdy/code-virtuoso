# loop-virtuoso

A deterministic, backlog-driven autonomous execution loop for Claude Code. Feeds an agent one small backlog step at a time. Gates completion on an exit code and a write-boundary guard, not the agent's claim. Compile a spec into a backlog, point the loop at it; a step flips to `verified` only when a script - not a model - confirms it, and an item is done only when all its steps are.

## Installation

```
/plugin marketplace add krzysztofsurdy/code-virtuoso
/plugin install loop-virtuoso@code-virtuoso
```

The plugin ships from the [code-virtuoso](https://github.com/krzysztofsurdy/code-virtuoso) marketplace.

## Quickstart

1. **Compile a backlog.** Run `/loop-virtuoso:backlog-compiler` (or just describe the work and let Claude reach for the skill) on a PRD, ticket, or freeform feature description. It produces `.delivery-loop/backlog.json` - each item is one or more steps, each step sized to a single context window, ordered by dependency, with a literal `verifyCommand` per step.
2. **Run the loop.** Either:
   - `/loop-virtuoso:start` - session-supervised (Mode A), inside your current Claude Code session.
   - `scripts/run-batch.sh .delivery-loop/backlog.json` - unattended batch (Mode B), a fresh process per iteration.
3. **Check progress** with `/loop-virtuoso:status`, and stop early with `/loop-virtuoso:cancel` (backlog state is preserved either way).

## Why an exit code, not a claim

An agent that can write the files grading its own work will sometimes game the check - edit a test, a fixture, or the verify command instead of fixing the code. So the agent never makes the call. A script runs the step's literal `verifyCommand`, checks the exit code, and writes the `status`. The agent is never asked whether it succeeded. (The `iteration-loop` skill covers the mechanics in full.)

## Commands

| Command | What it does |
|---|---|
| `/loop-virtuoso:backlog-compiler [source]` | Compile a PRD, ticket, or feature description into `.delivery-loop/backlog.json`. Implemented as a skill, not a `commands/*.md` file, but invokable the same way. |
| `/loop-virtuoso:start [backlog]` | Start the session-supervised loop (Mode A) over the backlog (default `<git root>/.delivery-loop/backlog.json`). Refuses to start on a dirty tree or on the default branch; see "Start-of-run checks". |
| `/loop-virtuoso:status [backlog]` | Report verified/pending/blocked counts (item and step level), iteration vs. max, stall/violation counts, and the progress-log/events tail. Cost is Mode B-only, tracked in its own run output, not shown here. |
| `/loop-virtuoso:cancel` | Remove the session-local file to stop the loop and record a `run_stopped` event with reason `cancelled`; the backlog is left untouched. |
| `/loop-virtuoso:help` | Show a short overview of the plugin and its commands. |

## Two modes

| Mode A - session-supervised | Mode B - unattended batch |
|---|---|
| `/loop-virtuoso:start` | `scripts/run-batch.sh path/to/backlog.json` |
| Runs in your current session via a `Stop` hook | Fresh `claude -p` process per iteration |
| Watching it work, brief unattended stretches, backlogs of ~5-15 items | Large backlogs, overnight or CI runs; adds a cumulative cost cap |

Pick Mode A to supervise a modest backlog. Pick Mode B for large or unattended runs. Mode B is not a slash command - it spawns long-running detached processes that don't fit a single tool-call turn.

## Teams and participants

Steps are the default unit, and an item is usually a single step. When a backlog benefits from distinct roles owning distinct phases (e.g. implement, then an independent review), a step can name a `participant` defined in an optional `.delivery-loop/teams.json`:

- `agent` - delegate the step to an existing Claude Code subagent.
- `persona` - an inline role with its own system prompt and tool list.

A `team` is a named, ordered group of participants that `backlog-compiler` expands into steps; the engine only ever runs participants. With no `teams.json`, steps carry no participant and run with no role framing - the simple default. The `backlog-compiler` skill walks through producing both. Note the fidelity difference: Mode B honors a participant with real per-step CLI flags; Mode A can only role-play it within one session (see the `iteration-loop` skill).

`teams.json` can live in two places, checked in that order: project-local (`.delivery-loop/teams.json`) first, then a shared global library at `~/.claude/loop-virtuoso/teams.json`. Define your usual roles once globally and reference them from any project's backlog; a project-local entry with the same name overrides the global one. See `references/teams-and-participants.md` in the `backlog-compiler` skill.

## Visibility

Every state transition is recorded by scripts, never the model:

- `.delivery-loop/progress.log` - human-readable, written the same way by both modes: a `run-start` line, a line when each iteration starts and when it ends, then `stop` and `run-end` lines. Mode B adds the running cost to the iteration and `run-end` lines.
- `.delivery-loop/events.jsonl` - machine-readable, one JSON object per transition (step verdict, item verified/blocked, loop stopped). `tail -f` or `jq` it for full detail.

## Start-of-run checks

Both modes run the same checks before the first iteration, and refuse to start if any fails:

- The backlog validates (`scripts/validate-backlog.sh`). This is a hard gate in both modes.
- The backlog lives in a `.delivery-loop` directory inside a git repository. The session file is always written to `<git root>/.delivery-loop/session.local.json`, so the hooks find it from any subdirectory.
- `backlog.branch` is set and is not the repository's default branch (`main`, `master`, or the branch `origin/HEAD` points at).
- The working tree has no modified or untracked files outside `.delivery-loop/`. The loop commits checkpoints, so commit or stash your own work first.
- The current branch is `backlog.branch`. If it is not, the loop switches to that branch (or creates it from the current commit), which is only possible because the tree is clean.

Mode A also needs a Claude Code session id so the Stop hook only drives the session that started the loop.

## Archiving a run

Starting a run never moves its backlog. The `backlog-compiler` skill runs `scripts/archive-run.sh <backlog> <new-branch>` before it writes a new backlog. That archives the old run into `.delivery-loop/archive/<date>-<branch>/` when the run finished (no pending items) or when the new branch differs from the old one. `backlog.json`, `progress.log`, and `events.jsonl` move there; `teams.json` is copied, so your participants stay available for the next run. A run with pending items and an unchanged branch is left alone. You can also run the script by hand.

## Safety defaults

- **`acceptEdits` + a scoped `allowedTools` allowlist of specific binaries - not `bypassPermissions`, and not a bare interpreter.** Auto-approve edits; name exactly which commands the worker may run, each one a specific tool or subcommand (`vendor/bin/phpunit`, `npm run test`), never a general-purpose interpreter (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`). That distinction is the actual boundary, not the list's length - see `allowed-tools-by-stack.md`'s "Why no bare interpreters" for why one interpreter grant undoes everything below.
- **Write-boundary guard, three parts.** A content-tamper check compares `backlog.json`/`teams.json` against a snapshot taken before each step, restoring and flagging any edit - including a rewritten `verifyCommand` - before anything else runs; the snapshot lives outside the project directory, unreachable by the worker's Edit/Write tools. A `PreToolUse` hook denies `Edit`, `Write`, and `NotebookEdit` to `config.protectedPaths` before the edit happens. A post-iteration `git diff` audit checks every changed file against `protectedPaths` regardless of which tool changed it. A violation is counted once: the offending paths are reverted to their state at the start of the iteration (a new offending file is deleted), so the next iteration does not trip over the same change. None of this defends against a worker with a bare interpreter in its `allowedTools` - Bash isn't sandboxed to the project directory the way Edit/Write are, so arbitrary code execution reaches anywhere the OS user can, snapshot location included. A curated, interpreter-free allowlist is what makes these three parts a real guarantee rather than a convention; broadening past that requires running the worker in an OS-level sandbox instead (see `permission-modes.md`).
- **Checkpoint commits never take more than the loop may own.** After a passing or failing iteration the loop commits tracked changes plus new files that are allowed: not secret-like (`.env`, `.env.*`, `*.pem`, `*.key`, and similar) and, if `config.allowedPaths` is set, matching one of its globs. A new file that is outside `allowedPaths` or secret-like is a violation. Commit hooks always run; the loop never uses `--no-verify`, so pre-commit secret scanners still apply. Because the loop only starts from a clean tree, nothing you had lying around can be swept into a checkpoint.
- **Six stop reasons, plus two Mode-B-only additions** - the loop ends via exactly one, written to `.delivery-loop/progress.log`:
  - `complete` - no pending items remain and none are blocked; every item reached `verified`.
  - `blocked_out` - no pending items remain, but at least one is `blocked` (it exhausted `maxAttemptsPerItem` without its `verifyCommand` passing).
  - `max_iterations` - the iteration count hit `config.maxIterations`; backlog state is preserved, rerun to continue.
  - `stalled` - `maxStallIterations` consecutive iterations produced an empty git diff (no changes at all); preserved, investigate why.
  - `violation_limit` - `maxViolations` cumulative protected-path violations were recorded by the git-diff audit; preserved, tighten `protectedPaths`/`allowedTools`.
  - `corrupted` - the session-state file or backlog failed to parse; the broken state file is removed and the loop stops rather than guessing.
  - `total_budget_exceeded` *(Mode B only)* - cumulative `total_cost_usd` across the run hit `config.totalBudgetUsd`. This is reported even on a Claude subscription (it's a notional figure, not a separate charge), so the gate still works there - it just isn't the thing that actually limits a subscription plan.
  - `invocation_failed` *(Mode B only)* - a `claude -p` call returned no usable result. The most common real-world cause under a subscription is the plan's own usage/rate limit, which doesn't show up as a cost at all; rerun once the window resets.

`/loop-virtuoso:cancel` is not one of these: it records `run_stopped` with reason `cancelled` and removes the session file.

For the authoritative detail on stop reasons, the write-boundary guard, and the backlog schema, see the `iteration-loop` and `backlog-compiler` skills shipped with this plugin.

## Self-review

This design went through five rounds of independent adversarial review before shipping, including a critical finding (a worker could rewrite its own `verifyCommand`) and its own fix's own bypass, both closed. See [`REVIEW.md`](REVIEW.md) for the honest account - what was found, what's fixed, and the two remaining trade-offs stated plainly rather than hidden.

## License

MIT

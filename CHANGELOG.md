# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-07-01

### Fixed

- The verify gate no longer reports `stall` just because no *tracked* file changed. `verifyCommand` now always runs; an empty diff only affects how a failure gets classified afterward (`stall` if it still fails, `fail` if it doesn't). Previously, a turn that fixed something outside git's view entirely (a corrupted gitignored `vendor/` autoloader, a stale build cache) while the real implementation from an earlier iteration's checkpoint was already correct and committed would report `stall` forever — `verifyCommand` never even ran, because `start_sha` and `HEAD` were identical (the previous iteration's own checkpoint commit), so the diff came back empty by construction. Climbed toward `maxStallIterations` despite the step being genuinely done.

## [1.1.1] - 2026-07-01

### Fixed

- Mode A's delegation prompt for `agent`-kind participants now warns that the subagent may work in an isolated git worktree (e.g. `agents-virtuoso`'s `backend-dev`/`frontend-dev`/`implementer`, which declare `isolation: worktree`) and instructs the delegating session to merge that worktree back into the checkout before ending its turn. Without this, the verify gate always grades the real checkout, never the subagent's worktree, so a correctly-implemented step could exhaust all attempts and land `blocked` for looking like nothing happened. Mode B's `--agent` flag has the same underlying issue with no verified fix yet — see the new callout in `teams-and-participants.md`.
- The verify gate no longer assumes the project directory (the parent of `.delivery-loop/`) is the git repo root. When the project sits inside a bigger repo (a monorepo), `verifyCommand` now runs from the project directory instead of the repo root, and `git diff`/`ls-files` output — always repo-root-relative — is normalized back to project-relative paths before matching `protectedPaths` or excluding the loop's own directory. A step's diff scope stays repo-wide (a sibling directory a step legitimately touches, e.g. `--cwd ../other-package`, is still seen and correctly path-checked), only the frame of reference for matching changed.

## [1.1.0] - 2026-07-01

### Added

- Global teams library at `~/.claude/loop-virtuoso/teams.json`, shared across every project on the machine. A project's own `.delivery-loop/teams.json` is still checked first and overrides the global library by name; anything not defined locally falls back to it. `validate-backlog.sh` and `status.sh` both resolve participants/teams through both layers.

## [1.0.0] - 2026-07-01

### Added

- `backlog-compiler` skill — converts a PRD, ticket, or freeform feature description into a `.delivery-loop/backlog.json`, sizing each step to one context window, ordering items by dependency, and writing a literal `verifyCommand` per step.
- `iteration-loop` skill — orchestrates and documents the execution loop over a backlog, with completion gated by deterministic verification rather than self-report.
- Two run modes: Mode A (session-supervised, via a `Stop` hook inside the current Claude Code session) and Mode B (unattended batch, a fresh process per iteration with a cumulative cost cap).
- Write-boundary guard: a content-tamper check that snapshots `backlog.json`/`teams.json` outside the project directory before each step and restores/flags any edit to them (including a rewritten `verifyCommand`) before any other check runs, a `PreToolUse` hook denying `Edit`/`Write` to protected paths in real time, and a post-iteration `git diff` audit in the verification gate that catches changes from any tool.
- Six-state stop-reason machine: `complete`, `blocked_out`, `max_iterations`, `stalled`, `violation_limit`, and `corrupted`, plus two Mode-B-only additions: `total_budget_exceeded` (cumulative `total_cost_usd` hit the configured cap — reported under both API billing and a subscription) and `invocation_failed` (a `claude -p` call returned no usable result, typically a subscription's usage/rate limit, which never surfaces as a cost figure).
- Four slash commands: `/loop-virtuoso:start`, `/loop-virtuoso:status`, `/loop-virtuoso:cancel`, and `/loop-virtuoso:help`.
- Multi-step backlog items: each item is an ordered sequence of `steps`, each step carrying its own `participant`, `instructions`, `verifyCommand`, `status`, `attempts`, and `notes`. Item status is derived from its steps, never stored separately; a single-step item is the common case.
- Reusable participants and teams via `.delivery-loop/teams.json`: a participant is either an `agent` (delegate to an existing Claude Code subagent) or an inline `persona` (own system prompt and tool list); a team is a named, ordered group of participants used as a compile-time template that the engine expands into steps but never runs as a unit.
- Structured event log at `.delivery-loop/events.jsonl` — one JSON object per state transition (step verdict, item verified/blocked, loop stopped) — alongside the human-readable `progress.log`.
- `REVIEW.md` — the record of five rounds of adversarial review this design went through, including a critical finding (a worker could rewrite its own `verifyCommand`) and the two real, documented trade-offs that remain.

### Fixed

- Default `allowedTools` for every stack no longer include bare general-purpose interpreters (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) — each was an unconditional arbitrary-file-write grant that defeated the tamper-detection guarantee entirely; package-manager installs narrowed to specific subcommands, with their remaining lifecycle-script risk documented rather than silently present.
- `backlog_protected_paths` now also protects `teams.json`, not only `backlog.json`, at the real-time `PreToolUse` layer.
- `scripts/validate-backlog.sh`'s participant-structure check rewritten to run entirely in `jq` after a bash `IFS`-splitting bug caused it to falsely reject every valid `persona` participant.
- `hooks/guard-protected-paths.sh`'s path resolution now walks up to the nearest existing ancestor directory before resolving symlinks, closing a gap where a brand-new file in a not-yet-created directory fell back to an unresolved path and could bypass the real-time guard.
- A `case` statement nested directly inside a `$(...)` command substitution in `scripts/lib/verify-gate.sh` did not parse on bash 3.2 (macOS's default `/bin/bash`) — moved into its own function.

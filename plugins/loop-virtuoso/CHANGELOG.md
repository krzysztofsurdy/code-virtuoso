# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-10-26

Guardrails and setup tooling for sessions outside a loop. Every new guard is off by default: installing or updating the plugin changes nothing until you set `loop.guard` in a config layer or approve a `harden` diff.

### Added

- Opt-in guard hooks, configured in the `loop.guard` config namespace:
  - `guard-secrets.sh` (`PreToolUse`, `blockSecrets: true`) blocks Read, Grep, Glob, Edit, Write, MultiEdit, NotebookEdit and Bash calls aimed at `.env` files, private keys, `.ssh/`, `.aws/`, `.gnupg/` and similar, and bare `printenv` or `env`. Its matching is a copy of the `hooks-and-guardrails` playbook's `block-secret-reads.sh`, kept in sync by a parity test.
  - `guard-tests.sh` (`PreToolUse`, `protectTests: "ask"` or `"deny"`) asks before, or denies, edits to files that match `testGlobs` and already exist in `HEAD`. New test files are always allowed.
  - `guard-stop.sh` (`Stop`, `stopGate: true`) runs `ticket-delivery.commands.lint`, `.staticAnalysis` and `.test` before a session with uncommitted changes ends, and blocks the stop with the last 40 lines of the first failing command.
  - `guard-tests.sh` and `guard-stop.sh` do nothing while a loop session is active; `protectedPaths` and the verify gate own that case.
- `/loop-virtuoso:harden` (`scripts/harden.sh [--scope user|project] [--apply] [--with statusline,telemetry,sandbox]`): merges a guardrail baseline into Claude Code `settings.json` (empty attribution, `permissions.deny` for secrets, `permissions.ask` for force pushes, hard resets and dependency changes) and the `loop.guard` defaults into the matching config layer. Dry-run diff by default; `--apply` backs up each changed file, never removes a user value, and is idempotent.
- `scripts/statusline.sh`: a statusline with directory, branch, model, session cost, context use and loop progress. `harden --with statusline` installs a copy in the config home so the path survives plugin updates.
- `/loop-virtuoso:doctor` (`scripts/doctor.sh [--json]`): a read-only audit of the Claude Code setup. Reports duplicate skills and agents, the skill listing size against an estimated budget, an oversized global CLAUDE.md and dead skill references in it, plaintext MCP secrets (server and key name only), settings gaps, guards not enabled, and orphan plugin caches, each with a severity and a fix.
- `/loop-virtuoso:eval-setup` (`scripts/eval-setup.sh [suite.json] [-k N] [--arms setup,vanilla] [--max-cost-usd N] [--dry-run]`): runs a task suite k times with the user's setup and with vanilla Claude Code (`--safe-mode`, overridable with `loop.evalSetup.vanillaArgs`), each trial in a throwaway worktree graded by its `verifyCommand`. Reports pass@k, pass^k, cost and the setup minus vanilla delta, and appends each run to `.code-virtuoso/loop/evals/history.jsonl`. The command always runs a dry run first.
- `/loop-virtuoso:scaffold <devcontainer|issue-to-pr|pilot-backlog> [--force]` and `templates/`: a devcontainer with a non-root user and an egress-allowlist firewall, a GitHub Actions workflow that turns a labelled issue or an `@claude` mention into a draft pull request, and a small pilot backlog. It refuses to overwrite; `--force` backs up first.
- `iteration-loop` references: `guardrails.md` (guard config, limits, doctor checks), `observability.md` (statusline, telemetry, loop cost and events, harden), `setup-evals.md` (building a suite, reading pass@k and pass^k, the vanilla arm, cost control), and a Reference Files table in `SKILL.md`.

### Changed

- Path resolution and glob matching moved from `hooks/guard-protected-paths.sh` and `scripts/lib/backlog.sh` to `scripts/lib/paths.sh`, shared by the loop guard, the verify gate and the new test guard. Matching behaviour is unchanged.
- The `claude -p` invocation and the `invocation_failed` hint moved from `scripts/run-batch.sh` to `scripts/lib/invoke.sh`, shared with `eval-setup.sh`. `run-batch.sh` behaves as before.

## [2.0.0] - 2026-10-21

First release inside code-virtuoso. Versions 1.0.0 to 1.1.2 shipped from the standalone loop-virtuoso repository. This major release moves the storage layout and also carries the fixes made since 1.1.2.

### Changed

- Storage follows the Code Virtuoso config convention (`spec/config-spec.md`). `.delivery-loop/` became `<git root>/.code-virtuoso/loop/`. The committed plan, `loop/backlog.json`, holds items, steps, `verifyCommand`s and config and never changes during a run. Run state is in `loop/state/` (ignored): `state.json` (each step's `status`, `attempts`, `notes`), `session.local.json`, `events.jsonl`, `progress.log`. A finished run is archived to `loop/archive/YYYY-MM-DD-<slug>/` (committed), with the final backlog and a copy of the state. `.code-virtuoso/.gitignore` (`*.local.json`, `loop/state/`) is created, or its missing lines appended, the first time the loop writes there.
- "Teams" are now "pipelines" everywhere (code, docs, skills), to avoid a clash with Code Virtuoso agent teams. The user file moved from `~/.claude/loop-virtuoso/teams.json` to `${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json`; the project file is `loop/pipelines.json`. The `teams` key is now `pipelines`.
- Agent participants use installed scoped names (`agents-virtuoso:<name>`). A bare name resolves to `agents-virtuoso:<name>` when that plugin is installed and ships the agent; other names are used as written.
- The loop reads the `loop` namespace of the merged config layers (user, project shared, project local) for settings the backlog's own `config` leaves out (`maxIterations`, `permissionMode`, `allowedTools`, `allowedPaths`, `protectedPaths`, and the other limits). `protectedPaths` from both sources are combined. `validate-backlog.sh` checks the effective config and fails on a config or pipelines file that is not valid JSON.
- Checkpoint commits follow `ticket-delivery.commitFormat` (placeholders `{ticket}`, `{summary}`, `{item}`, `{step}`; the ticket id comes from `ticket-delivery.ticketIdPattern` matched against `backlog.branch`). Without a format, or when the ticket cannot be found, the message stays `loop-virtuoso: ITEM/step`. New `scripts/branch-name.sh` prints a branch name from `ticket-delivery.branchPattern`.
- Tamper-check snapshots moved from `$TMPDIR/loop-virtuoso-snapshots` to `${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso/loop/snapshots/`. The check now also covers `.code-virtuoso/config.json`, `config.local.json` and `loop/pipelines.json`, including a file that did not exist when the step began. `.code-virtuoso/**` is always protected from Edit and Write, and the preflight and the git-diff audit treat that directory as loop infrastructure.
- `backlog-compiler` no longer reads the `ticket-delivery` `.supplement.md`; it reads the merged config. `iteration-loop` is a reference skill only (no `user-invocable`, no `argument-hint`); the commands start, status and cancel run the loop. The plugin docs link `ticket-writer`, `ticket-delivery` and `finishing-branch`.

### Migration

- `/loop-virtuoso:start` and `run-batch.sh` move an existing `.delivery-loop/` to `.code-virtuoso/loop/` once (the backlog is split into plan and state), print what moved, and advise removing a `.delivery-loop` line from `.git/info/exclude`. A global `~/.claude/loop-virtuoso/teams.json` is copied to the user pipelines path when that file does not exist. Nothing reads the old paths afterwards. If both layouts hold a backlog, the loop refuses to start.

### Security

- The loop no longer runs `git add -A` and `git commit --no-verify`. Checkpoint commits stage tracked changes plus new files that are allowed (not secret-like such as `.env`, and inside the optional `config.allowedPaths`), and commit hooks always run. A new file outside `allowedPaths` or with a secret-like name is a violation. Both run modes now refuse to start when the working tree has modified or untracked files outside `.code-virtuoso/`, so a stray `.env` can never be swept into a commit.

### Fixed

- `backlog.branch` is enforced: both modes refuse to run when it is the default branch (`main`, `master`, or the `origin/HEAD` target) and switch to it (or create it) from a clean tree.
- Mode A now writes `progress.log` like Mode B, so completed Mode A runs are archived. Both modes write the same `run-start`, per-iteration, `stop`, and `run-end` lines.
- Hooks, `status.sh`, and `cancel.sh` find the session file at `<git root>/.code-virtuoso/loop/state/session.local.json`, so starting or working from a subdirectory works. The session file stores an absolute backlog path.
- Mode B validates the backlog as a hard gate (it used to swallow the result) and applies the same config defaults as Mode A, including `permissionMode: acceptEdits`.
- `archive-run.sh` copies `pipelines.json` instead of moving it, archives on a finished run or on a branch change (new optional second argument), and is no longer run at start, which could move the backlog about to be executed. The `backlog-compiler` skill runs it before writing a new backlog.
- A violation now reverts the offending paths (and commits the revert if the worker had committed the change), so one violation no longer repeats every iteration until `violation_limit`.
- The `PreToolUse` guard also covers `NotebookEdit`.
- A session file with an empty `sessionId` is no longer claimed by whichever session stops first; `/loop-virtuoso:start` refuses to start without a session id.
- `/loop-virtuoso:cancel` is now `scripts/cancel.sh`: it records a `run_stopped` event with reason `cancelled` and removes the temporary snapshots. Snapshots are also removed when a run stops.

### Documentation

- The docs agree on the security boundary: the guard and a narrow, interpreter-free `allowedTools` list work together, neither is enough alone. `/loop-virtuoso:status` shows no cost line (in Mode B, cost is in `progress.log`).
- License is MIT and the install command uses the `code-virtuoso` marketplace.

## [1.1.2] - 2026-07-01

### Fixed

- The verify gate no longer reports `stall` just because no *tracked* file changed. `verifyCommand` now always runs; an empty diff only affects how a failure gets classified afterward (`stall` if it still fails, `fail` if it doesn't). Previously, a turn that fixed something outside git's view entirely (a corrupted gitignored `vendor/` autoloader, a stale build cache) while the real implementation from an earlier iteration's checkpoint was already correct and committed would report `stall` forever - `verifyCommand` never even ran, because `start_sha` and `HEAD` were identical (the previous iteration's own checkpoint commit), so the diff came back empty by construction. Climbed toward `maxStallIterations` despite the step being genuinely done.

## [1.1.1] - 2026-07-01

### Fixed

- Mode A's delegation prompt for `agent`-kind participants now warns that the subagent may work in an isolated git worktree (e.g. `agents-virtuoso`'s `backend-dev`/`frontend-dev`/`implementer`, which declare `isolation: worktree`) and instructs the delegating session to merge that worktree back into the checkout before ending its turn. Without this, the verify gate always grades the real checkout, never the subagent's worktree, so a correctly-implemented step could exhaust all attempts and land `blocked` for looking like nothing happened. Mode B's `--agent` flag has the same underlying issue with no verified fix yet - see the new callout in `teams-and-participants.md`.
- The verify gate no longer assumes the project directory (the parent of `.delivery-loop/`) is the git repo root. When the project sits inside a bigger repo (a monorepo), `verifyCommand` now runs from the project directory instead of the repo root, and `git diff`/`ls-files` output - always repo-root-relative - is normalized back to project-relative paths before matching `protectedPaths` or excluding the loop's own directory. A step's diff scope stays repo-wide (a sibling directory a step legitimately touches, e.g. `--cwd ../other-package`, is still seen and correctly path-checked), only the frame of reference for matching changed.

## [1.1.0] - 2026-07-01

### Added

- Global teams library at `~/.claude/loop-virtuoso/teams.json`, shared across every project on the machine. A project's own `.delivery-loop/teams.json` is still checked first and overrides the global library by name; anything not defined locally falls back to it. `validate-backlog.sh` and `status.sh` both resolve participants/teams through both layers.

## [1.0.0] - 2026-07-01

### Added

- `backlog-compiler` skill - converts a PRD, ticket, or freeform feature description into a `.delivery-loop/backlog.json`, sizing each step to one context window, ordering items by dependency, and writing a literal `verifyCommand` per step.
- `iteration-loop` skill - orchestrates and documents the execution loop over a backlog, with completion gated by deterministic verification rather than self-report.
- Two run modes: Mode A (session-supervised, via a `Stop` hook inside the current Claude Code session) and Mode B (unattended batch, a fresh process per iteration with a cumulative cost cap).
- Write-boundary guard: a content-tamper check that snapshots `backlog.json`/`teams.json` outside the project directory before each step and restores/flags any edit to them (including a rewritten `verifyCommand`) before any other check runs, a `PreToolUse` hook denying `Edit`/`Write` to protected paths in real time, and a post-iteration `git diff` audit in the verification gate that catches changes from any tool.
- Six-state stop-reason machine: `complete`, `blocked_out`, `max_iterations`, `stalled`, `violation_limit`, and `corrupted`, plus two Mode-B-only additions: `total_budget_exceeded` (cumulative `total_cost_usd` hit the configured cap - reported under both API billing and a subscription) and `invocation_failed` (a `claude -p` call returned no usable result, typically a subscription's usage/rate limit, which never surfaces as a cost figure).
- Four slash commands: `/loop-virtuoso:start`, `/loop-virtuoso:status`, `/loop-virtuoso:cancel`, and `/loop-virtuoso:help`.
- Multi-step backlog items: each item is an ordered sequence of `steps`, each step carrying its own `participant`, `instructions`, `verifyCommand`, `status`, `attempts`, and `notes`. Item status is derived from its steps, never stored separately; a single-step item is the common case.
- Reusable participants and teams via `.delivery-loop/teams.json`: a participant is either an `agent` (delegate to an existing Claude Code subagent) or an inline `persona` (own system prompt and tool list); a team is a named, ordered group of participants used as a compile-time template that the engine expands into steps but never runs as a unit.
- Structured event log at `.delivery-loop/events.jsonl` - one JSON object per state transition (step verdict, item verified/blocked, loop stopped) - alongside the human-readable `progress.log`.
- `REVIEW.md` - the record of five rounds of adversarial review this design went through, including a critical finding (a worker could rewrite its own `verifyCommand`) and the two real, documented trade-offs that remain.

### Fixed

- Default `allowedTools` for every stack no longer include bare general-purpose interpreters (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) - each was an unconditional arbitrary-file-write grant that defeated the tamper-detection guarantee entirely; package-manager installs narrowed to specific subcommands, with their remaining lifecycle-script risk documented rather than silently present.
- `backlog_protected_paths` now also protects `teams.json`, not only `backlog.json`, at the real-time `PreToolUse` layer.
- `scripts/validate-backlog.sh`'s participant-structure check rewritten to run entirely in `jq` after a bash `IFS`-splitting bug caused it to falsely reject every valid `persona` participant.
- `hooks/guard-protected-paths.sh`'s path resolution now walks up to the nearest existing ancestor directory before resolving symlinks, closing a gap where a brand-new file in a not-yet-created directory fell back to an unresolved path and could bypass the real-time guard.
- A `case` statement nested directly inside a `$(...)` command substitution in `scripts/lib/verify-gate.sh` did not parse on bash 3.2 (macOS's default `/bin/bash`) - moved into its own function.

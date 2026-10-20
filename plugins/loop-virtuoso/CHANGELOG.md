# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - first release inside code-virtuoso

Earlier 1.x versions (1.0.0 to 1.1.2) shipped from the standalone loop-virtuoso repository. Versions inside code-virtuoso restart at 1.0.0, so this entry also carries the fixes made since 1.1.2.

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

# The write-boundary guard, in full

The motivating problem: an agent with write access to the files that grade its own work will, with non-trivial frequency, satisfy the letter of the check instead of the intent - editing a test file, a fixture, or the verification command itself rather than fixing the underlying code. This is documented, named behavior (reward hacking / specification gaming), not a hypothetical edge case. The guard exists to make it structurally impossible, not just discouraged by instruction.

## The control-file tamper check (the one that matters most)

Neither layer below, on its own, stops a worker from rewriting a step's own `verifyCommand` to something trivial like `true` directly in `backlog.json` - layer 1 only watches `Edit`/`Write` calls, and layer 2 deliberately excludes `.code-virtuoso/` from its change scan (it's infrastructure, not work product, and a worker's legitimate writes there would otherwise look identical to its own). A path-based check can't close this gap either: rewriting `verifyCommand` doesn't touch any path a glob would flag.

What does close it: `verify_gate_run` (`scripts/lib/verify-gate.sh`) compares the current content of the loop's control files against a snapshot taken right before the worker saw the step's prompt. The files are `loop/backlog.json` (the plan), `loop/pipelines.json`, `.code-virtuoso/config.json` and `.code-virtuoso/config.local.json`. A file that did not exist at snapshot time is guarded by its absence: creating it mid-step is a violation and the file is removed. The snapshot is taken once per step by `verify_gate_snapshot_all`, called from `scripts/setup-start.sh`, `hooks/stop-hook.sh`, and `scripts/run-batch.sh`. Any difference - `verifyCommand`, `config`, a persona's `allowedTools`, a loosened `loop` setting, anything - is restored from the snapshot and reported as a `violation`, before any other check runs.

The plan is never written by the engine, so any change to it during a run is tampering by definition. Run state (`loop/state/`) is the engine's own and is not snapshotted; the worker is kept out of it by the `PreToolUse` guard, which protects everything under `.code-virtuoso/`.

The user layer (the user `config.json` and the user `pipelines.json`, see `backlog-compiler`'s `pipelines-and-participants.md`) is deliberately not part of this check - it isn't part of the project the worker's Edit/Write tools can reach at all, for the same reason the tamper-check's own snapshot lives outside the project tree. It's still subject to the same Bash caveat as everything else here: a worker with a bare interpreter can reach it, same as it can reach anything else the OS user can.

The snapshot itself lives **outside the project directory** (`verify_gate_snapshot_path`, a deterministic path under `${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso/loop/snapshots/`), not as a sibling file next to `backlog.json`. An earlier version kept it as a sibling file; a worker with the same Edit/Write access used to tamper with `backlog.json` could just as easily overwrite a sibling snapshot to match, laundering the comparison instead of failing it.

**This closes the Edit/Write vector, not the Bash one, and that distinction matters.** Claude Code scopes the Edit and Write tools to the project directory, so moving the snapshot outside the tree makes it genuinely unreachable *through those two tools*. It does not make the snapshot unreachable through Bash: Bash is not sandboxed to the project directory, and the hashing scheme that picks the snapshot's path is public (it's in this repo), so a worker with a bare general-purpose interpreter in its `allowedTools` (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) can compute the same path and launder the snapshot exactly as it could when the snapshot lived inside the project. Whether that's reachable in practice comes down entirely to what `config.allowedTools` actually grants - see `backlog-compiler`'s `allowed-tools-by-stack.md` and `permission-modes.md` for why bare interpreters are excluded from every default for exactly this reason, and what to do (OS-level sandboxing, not a bash-side workaround) if a project genuinely needs broader Bash than a curated allowlist provides. There is no way to close this at the file-location level once the worker can execute arbitrary code; only confining where that code can execute closes it.

## Layer 1 - `PreToolUse` hook (real time)

`hooks/guard-protected-paths.sh` is wired to the `PreToolUse` event for the `Edit`, `Write`, and `NotebookEdit` tools in `hooks/hooks.json`. (`NotebookEdit` names its target `notebook_path` rather than `file_path`; the hook reads either.) On every such call, before the edit happens:

1. Find `<git root>/.code-virtuoso/loop/state/session.local.json` from the hook's working directory. If there is no git repository or no such file, exit 0 immediately: no loop is active, the hook has no opinion.
2. Otherwise read `config.protectedPaths` from the backlog the session references, combined with the `protectedPaths` of the `loop` namespace in the shared config, plus `.code-virtuoso/**` (always implicitly protected: the plan, pipelines, config layers, and loop state - the worker is never told it may open them, and this hook makes that structural rather than a matter of the worker following instructions).
3. If the tool call's `tool_input.file_path` matches any protected glob, return `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<path> is a protected verification file for this loop"}}`. The edit never happens.
4. Otherwise exit 0 - defer to whatever the session's normal permission flow would do.

This only covers the `Edit`, `Write`, and `NotebookEdit` tools directly. A Bash command that writes to a protected path through some other mechanism (a redirect, `sed -i`, an inline script) is not caught here - that's what layer 2 is for. An earlier draft of this design added a third, heuristic layer trying to pattern-match dangerous-looking Bash commands; it was cut because it would both false-positive on harmless commands and false-negative on anything not in its pattern list, while adding no coverage that layer 2 doesn't already provide unconditionally.

## Layer 2 - post-iteration git-diff audit (authoritative)

Implemented once, in `scripts/lib/verify-gate.sh`, and called identically by both the `Stop` hook (Mode A) and `run-batch.sh` (Mode B) - there is exactly one place this logic lives.

1. Before the worker invocation starts, record the current commit SHA.
2. After it finishes, `git diff --name-only <start-sha>` - this captures the *result* of any tool, Bash included, regardless of which specific command produced it.
3. Check every changed path against `config.protectedPaths`. Any match is a violation. A file that did not exist at the start of the iteration is also a violation if its name is secret-like (`.env`, `.env.*`, `*.pem`, `*.key`, and similar) or, when `config.allowedPaths` is set, it matches none of those globs.
4. A violation means the iteration is **not credited** - the step's `status` does not change, its `attempts` does not increment (this wasn't a legitimate attempt at the task), and a separate violation counter increments toward `config.maxViolations`.
5. The offending paths are then reverted: a tracked path is restored to its content at the iteration's start commit, a new path is deleted, and if the worker had committed the offending change the revert is committed too. Only the offending paths are touched; the worker's other changes stay in the tree and are judged normally next iteration. Without the revert, the next iteration would see the same changed file and count the same violation again, so one bad iteration would burn the whole `maxViolations` budget.

This is the backstop nothing can route around: it doesn't matter which tool was used or whether layer 1 had a rule for it, because it inspects the tree state that resulted, not the mechanism that produced it.

## Checkpoint commits

After every iteration that is not a violation, the gate makes a checkpoint commit so the next iteration's `start_sha` is meaningful. The checkpoint stages tracked changes plus new files that pass the same new-file rule as layer 2 (not secret-like, inside `config.allowedPaths` when set, not protected). Everything else stays untracked and is never committed. Commit hooks run: the loop never uses `--no-verify`, so a pre-commit secret scanner or linter still applies, and a commit a hook rejects is simply not made.

This only works because a run starts from a clean tree. `loop_preflight` (`scripts/lib/preflight.sh`) refuses to start when files outside `.code-virtuoso/` are modified or untracked, so any untracked file the gate sees during a run was created during the run, never something you had lying around.

## Who writes what

`scripts/lib/backlog.sh` is the only code path with permission to mutate a step's `status` field, which lives in `loop/state/state.json` (the plan, `backlog.json`, holds no status; item status is never stored - it's derived from the steps), and it does so only in response to a verify-gate result - never in response to anything the worker said about its own progress. A separate LLM-based reviewer agent, if the target project has one installed, may run after the mechanical gate passes and log an advisory note, but it never overrides the mechanical gate.

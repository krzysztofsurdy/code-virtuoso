# The write-boundary guard, in full

The motivating problem: an agent with write access to the files that grade its own work will, with non-trivial frequency, satisfy the letter of the check instead of the intent — editing a test file, a fixture, or the verification command itself rather than fixing the underlying code. This is documented, named behavior (reward hacking / specification gaming), not a hypothetical edge case. The guard exists to make it structurally impossible, not just discouraged by instruction.

## The control-file tamper check (the one that matters most)

Neither layer below, on its own, stops a worker from rewriting a step's own `verifyCommand` to something trivial like `true` directly in `backlog.json` — layer 1 only watches `Edit`/`Write` calls, and layer 2 deliberately excludes the loop's own directory from its change scan (it's infrastructure, not work product, and a worker's legitimate writes there would otherwise look identical to its own). A path-based check can't close this gap either: rewriting `verifyCommand` doesn't touch any path a glob would flag.

What does close it: `verify_gate_run` (`scripts/lib/verify-gate.sh`) compares `backlog.json`'s and `teams.json`'s current content against a snapshot taken right before the worker saw the step's prompt (`verify_gate_snapshot_all`, called once per step from `scripts/setup-start.sh`, `hooks/stop-hook.sh`, and `scripts/run-batch.sh`). Any difference — `verifyCommand`, `status`, `config`, a persona's `allowedTools`, anything — is restored from the snapshot and reported as a `violation`, before any other check runs.

The snapshot itself lives **outside the project directory** (`verify_gate_snapshot_path`, a deterministic path under `$TMPDIR`), not as a sibling file next to `backlog.json`. An earlier version kept it as a sibling file; a worker with the same Edit/Write access used to tamper with `backlog.json` could just as easily overwrite a sibling snapshot to match, laundering the comparison instead of failing it.

**This closes the Edit/Write vector, not the Bash one, and that distinction matters.** Claude Code scopes the Edit and Write tools to the project directory, so moving the snapshot outside the tree makes it genuinely unreachable *through those two tools*. It does not make the snapshot unreachable through Bash: Bash is not sandboxed to the project directory, and the hashing scheme that picks the snapshot's path is public (it's in this repo), so a worker with a bare general-purpose interpreter in its `allowedTools` (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) can compute the same path and launder the snapshot exactly as it could when the snapshot lived inside the project. Whether that's reachable in practice comes down entirely to what `config.allowedTools` actually grants — see `backlog-compiler`'s `allowed-tools-by-stack.md` and `permission-modes.md` for why bare interpreters are excluded from every default for exactly this reason, and what to do (OS-level sandboxing, not a bash-side workaround) if a project genuinely needs broader Bash than a curated allowlist provides. There is no way to close this at the file-location level once the worker can execute arbitrary code; only confining where that code can execute closes it.

## Layer 1 — `PreToolUse` hook (real time)

`hooks/guard-protected-paths.sh` is wired to the `PreToolUse` event for the `Edit` and `Write` tools in `hooks/hooks.json`. On every such call, before the edit happens:

1. If `.delivery-loop/session.local.json` doesn't exist, exit 0 immediately — no loop is active, the hook has no opinion.
2. Otherwise read `config.protectedPaths` from the backlog the session references, plus the backlog file's own path (always implicitly protected — the worker is never told it may open `.delivery-loop/backlog.json`, and this hook makes that structural rather than a matter of the worker following instructions).
3. If the tool call's `tool_input.file_path` matches any protected glob, return `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<path> is a protected verification file for this loop"}}`. The edit never happens.
4. Otherwise exit 0 — defer to whatever the session's normal permission flow would do.

This only covers the `Edit`/`Write` tools directly. A Bash command that writes to a protected path through some other mechanism (a redirect, `sed -i`, an inline script) is not caught here — that's what layer 2 is for. An earlier draft of this design added a third, heuristic layer trying to pattern-match dangerous-looking Bash commands; it was cut because it would both false-positive on harmless commands and false-negative on anything not in its pattern list, while adding no coverage that layer 2 doesn't already provide unconditionally.

## Layer 2 — post-iteration git-diff audit (authoritative)

Implemented once, in `scripts/lib/verify-gate.sh`, and called identically by both the `Stop` hook (Mode A) and `run-batch.sh` (Mode B) — there is exactly one place this logic lives.

1. Before the worker invocation starts, record the current commit SHA.
2. After it finishes, `git diff --name-only <start-sha>` — this captures the *result* of any tool, Bash included, regardless of which specific command produced it.
3. Check every changed path against `config.protectedPaths`. Any match is a violation.
4. A violation means the iteration is **not credited** — the step's `status` does not change, its `attempts` does not increment (this wasn't a legitimate attempt at the task), and a separate violation counter increments toward `config.maxViolations`.

This is the backstop nothing can route around: it doesn't matter which tool was used or whether layer 1 had a rule for it, because it inspects the tree state that resulted, not the mechanism that produced it.

## Who writes what

`scripts/lib/backlog.sh` is the only code path with permission to mutate a step's `status` field in `backlog.json` (item status is never stored — it's derived from the steps), and it does so only in response to a verify-gate result — never in response to anything the worker said about its own progress. A separate LLM-based reviewer agent, if the target project has one installed, may run after the mechanical gate passes and log an advisory note, but it never overrides the mechanical gate.

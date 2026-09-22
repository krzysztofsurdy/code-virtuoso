# Stop-reason state machine, in full

Both modes terminate via exactly one named reason, written to `.delivery-loop/progress.log` and printed to the user. There is no other way out of the loop.

## `complete`

No `pending` items remain in the backlog, and none are `blocked`. Every item reached `verified` — meaning all of its steps passed their own `verifyCommand`. The session state file is removed; a summary (item count, total iterations used, total cost if tracked) is printed.

## `blocked_out`

No `pending` items remain, but at least one is `blocked` — one of its steps exhausted `config.maxAttemptsPerItem` tries without its `verifyCommand` passing (and a blocked step blocks its whole item, since later steps depend on it). This is a deliberately distinct outcome from `complete`: the loop ran to its natural end, but didn't finish the backlog. The report lists every blocked item and step with its last verify-gate failure output, so a human can decide whether to rewrite it, fix something by hand, or split it further.

## `max_iterations`

The iteration counter reached `config.maxIterations` while items were still `pending`. This is a budget exhausted, not a failure — the backlog state is preserved exactly as it stood, and a follow-up `/loop-virtuoso:start` or `run-batch.sh` invocation continues from the same `pending` items. If this triggers repeatedly on the same backlog, the items are probably still too large (see `backlog-compiler`'s sizing rule).

## `stalled`

`config.maxStallIterations` consecutive iterations each produced an **empty git diff** — the precise definition used here. This is distinct from "verification failed," which has a diff and is handled entirely by the per-step `attempts` counter instead. A stall means the worker made no changes at all for several iterations in a row, which usually means it's confused about the task, blocked by something outside the backlog's description, or stuck waiting on a permission it doesn't have. Investigate the prompt and `config.allowedTools` before restarting.

## `violation_limit`

`config.maxViolations` cumulative protected-path violations were recorded by the verify-gate's git-diff audit (see `write-boundary.md`). This is the rarest and most concerning stop reason — it means the worker repeatedly produced changes inside `config.protectedPaths` despite the `PreToolUse` guard denying direct Edit/Write attempts there, meaning it found another route (a Bash command not covered by layer 1). Treat this as a signal to tighten `protectedPaths` or `allowedTools`, not just to restart.

## `corrupted`

`.delivery-loop/session.local.json` or `.delivery-loop/backlog.json` failed to parse as valid JSON, or a required field was missing/malformed. The hook removes the broken state file and stops rather than guessing — manually inspect both files before running `/loop-virtuoso:start` again.

## Two more, Mode B only: `total_budget_exceeded` and `invocation_failed`

Mode A has no per-invocation cost data to read, so it relies on `maxIterations` alone for cost control. Mode B can see `total_cost_usd` after every iteration, so it adds `total_budget_exceeded`: cumulative cost across the run hit `config.totalBudgetUsd`. Same handling as `max_iterations` — backlog state preserved, exit code 1.

**`total_cost_usd` is reported either way — it just isn't the limiting factor for subscription users.** Tested against the real CLI under a Claude subscription (team plan, not API billing), it returns a real, non-zero notional figure even though the user isn't separately charged for it. So `total_budget_exceeded` fires correctly on a subscription too; it simply isn't what actually constrains a subscription plan. The real subscription-specific gap is `invocation_failed`: the plan's own usage/rate limit doesn't surface as a cost figure at all — it just makes the `claude -p` invocation fail outright. When an invocation returns no usable result (not a max-turns/max-budget cutoff, which still returns valid JSON), Mode B stops immediately with `invocation_failed` rather than burning through retries against an active limit or miscounting it as a stall. The log line includes a best-effort hint from stderr (e.g. "likely a usage/rate limit") but doesn't claim certainty about the cause — just rerun later once the limit window resets; backlog state is preserved exactly like every other guardrail stop.

## Per-step attempt accounting

`attempts` is tracked per step and increments exactly once per failed verify-gate result for that step (a passing result moves the step straight to `verified` and the counter stops mattering). `maxAttemptsPerItem: 3` means a step gets **3 total tries** before flipping to `blocked` — not 3 retries after an initial attempt, i.e. attempts 1, 2, and 3 all count, and the third failure is what triggers `blocked`. A blocked step blocks its item. (The config key keeps its `…PerItem` name for single-step items, the common case, where step and item are the same thing.)

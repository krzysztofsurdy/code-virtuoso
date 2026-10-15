---
description: "Start the session-supervised delivery loop (Mode A) over a backlog"
argument-hint: "[path-to-backlog] (default <git root>/.code-virtuoso/loop/backlog.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-start.sh:*)"]
---

# Start the delivery loop (Mode A)

Run the setup script, passing along the backlog path argument if the user gave one:

```
${CLAUDE_PLUGIN_ROOT}/scripts/setup-start.sh $ARGUMENTS
```

No argument defaults to `.code-virtuoso/loop/backlog.json` at the git root, so it works from any subdirectory. If the project still has the old `.delivery-loop/` directory, the script first moves it to `.code-virtuoso/loop/` and copies an old global teams file to the user pipelines path; relay what it prints about that, including any advice to remove a `.delivery-loop` line from `.git/info/exclude`. The script validates the backlog, then refuses to start unless the working tree is clean (outside `.code-virtuoso/`) and `backlog.branch` is not the default branch. It switches to `backlog.branch` (creating it if needed), writes `<git root>/.code-virtuoso/loop/state/session.local.json` (the file that arms the hooks), and prints the first item's prompt. It does not archive anything: the `backlog-compiler` skill archives a finished or abandoned run before writing a new backlog. When the run ends with `complete`, suggest the `finishing-branch` skill.

If the script refuses, relay its message to the user: they need to commit or stash their changes, or pick a feature branch, before trying again.

After it runs:

1. Work the prompt the script printed - implement that one item and make its `verifyCommand` pass. Do not edit test files, the verify command, or anything under `.code-virtuoso/`; changes to those are rejected.
2. The `Stop` hook now intercepts each turn-end. It runs the verification gate on the item you just worked, records the result, and either feeds back the next item's prompt or lets the session end at a documented stop reason (`complete`, `blocked_out`, `max_iterations`, `stalled`, `violation_limit`, `corrupted`).
3. Do not decide an item or the backlog is done - only the gate flips an item to `verified`. Keep working each prompt the hook hands you until it releases the turn.

To stop early: `/loop-virtuoso:cancel`. To check progress: `/loop-virtuoso:status`.

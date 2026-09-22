---
description: "Start the session-supervised delivery loop (Mode A) over a backlog"
argument-hint: "[path-to-backlog] (default .delivery-loop/backlog.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-start.sh:*)"]
---

# Start the delivery loop (Mode A)

Run the setup script, passing along the backlog path argument if the user gave one:

```
${CLAUDE_PLUGIN_ROOT}/scripts/setup-start.sh $ARGUMENTS
```

No argument defaults to `.delivery-loop/backlog.json`. The script validates the backlog, archives a previous run if the branch changed, writes `.delivery-loop/session.local.json` (the file that arms the hooks), and prints the first item's prompt.

After it runs:

1. Work the prompt the script printed — implement that one item and make its `verifyCommand` pass. Do not edit test files, the verify command, or `.delivery-loop/backlog.json`; changes to those are rejected.
2. The `Stop` hook now intercepts each turn-end. It runs the verification gate on the item you just worked, records the result, and either feeds back the next item's prompt or lets the session end at a documented stop reason (`complete`, `blocked_out`, `max_iterations`, `stalled`, `violation_limit`, `corrupted`).
3. Do not decide an item or the backlog is done — only the gate flips an item to `verified`. Keep working each prompt the hook hands you until it releases the turn.

To stop early: `/loop-virtuoso:cancel`. To check progress: `/loop-virtuoso:status`.

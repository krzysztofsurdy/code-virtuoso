---
description: "Cancel the active delivery loop; backlog state is left untouched"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/cancel.sh:*)"]
---

# Cancel the delivery loop

The loop is armed only while `<git root>/.delivery-loop/session.local.json` exists. Cancelling removes that file. The backlog itself is left untouched: `verified` items stay `verified`, `pending` items stay `pending`, and a later `/loop-virtuoso:start` resumes from where it left off.

Run the cancel script:

```
${CLAUDE_PLUGIN_ROOT}/scripts/cancel.sh
```

It finds the session file from the git root (so the current directory does not matter), records a `run_stopped` event with reason `cancelled` in `events.jsonl`, removes the loop's temporary snapshots, and removes the session file. Relay its output: either "No active loop." or the iteration the loop was cancelled at.

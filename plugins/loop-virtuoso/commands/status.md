---
description: "Report loop progress: counts, iteration, stalls, log tail"
argument-hint: "[path-to-backlog] (default <git root>/.code-virtuoso/loop/backlog.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/status.sh:*)"]
---

# Loop status

Run the status script, passing along the backlog path argument if the user gave one:

```
${CLAUDE_PLUGIN_ROOT}/scripts/status.sh $ARGUMENTS
```

No argument defaults to `.code-virtuoso/loop/backlog.json` at the git root.

Relay the output verbatim. It reports items verified/pending/blocked, iteration vs. `maxIterations`, stall and violation counts, and the tails of `.code-virtuoso/loop/state/progress.log` and `.code-virtuoso/loop/state/events.jsonl`. It shows no cost line; in Mode B the running cost is in the `progress.log` lines. Don't summarize or add commentary unless the user asks a follow-up.

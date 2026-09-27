---
description: "Report delivery-loop progress: counts, iteration, stalls, log tail"
argument-hint: "[path-to-backlog] (default <git root>/.delivery-loop/backlog.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/status.sh:*)"]
---

# Delivery-loop status

Run the status script, passing along the backlog path argument if the user gave one:

```
${CLAUDE_PLUGIN_ROOT}/scripts/status.sh $ARGUMENTS
```

No argument defaults to `.delivery-loop/backlog.json` at the git root.

Relay the output verbatim. It reports items verified/pending/blocked, iteration vs. `maxIterations`, stall and violation counts, and the tails of `.delivery-loop/progress.log` and `.delivery-loop/events.jsonl`. It shows no cost line; in Mode B the running cost is in the `progress.log` lines. Don't summarize or add commentary unless the user asks a follow-up.

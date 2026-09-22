---
description: "Report delivery-loop progress: counts, iteration, stalls, cost, log tail"
argument-hint: "[path-to-backlog] (default .delivery-loop/backlog.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/status.sh:*)"]
---

# Delivery-loop status

Run the status script, passing along the backlog path argument if the user gave one:

```
${CLAUDE_PLUGIN_ROOT}/scripts/status.sh $ARGUMENTS
```

No argument defaults to `.delivery-loop/backlog.json`.

Relay the output verbatim. It reports items verified/pending/blocked, iteration vs. `maxIterations`, stall and violation counts, cost if tracked, and the tail of `.delivery-loop/progress.log`. Don't summarize or add commentary unless the user asks a follow-up.

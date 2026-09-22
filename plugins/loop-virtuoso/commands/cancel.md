---
description: "Cancel the active delivery loop; backlog state is left untouched"
allowed-tools: ["Bash(test -f .delivery-loop/session.local.json:*)", "Bash(cat .delivery-loop/session.local.json:*)", "Bash(rm .delivery-loop/session.local.json)"]
---

# Cancel the delivery loop

The loop is armed only while `.delivery-loop/session.local.json` exists. Cancelling means removing that one file — the backlog itself is left untouched: `verified` items stay `verified`, `pending` items stay `pending`, and a later `/loop-virtuoso:start` resumes from where it left off.

1. Check whether `.delivery-loop/session.local.json` exists (`test -f .delivery-loop/session.local.json`).
2. If it does not exist, report: "No active loop." and stop.
3. If it exists, read its `iteration` field before removing it (`cat` the file and note the value), then remove the file (`rm .delivery-loop/session.local.json`).
4. Report that the loop was cancelled and at which iteration (e.g. "Cancelled at iteration 7. Backlog state preserved — run /loop-virtuoso:start to resume.").

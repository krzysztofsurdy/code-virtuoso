---
description: "Explain what loop-virtuoso does, its two modes, and its commands"
---

# loop-virtuoso

loop-virtuoso runs a deterministic, backlog-driven autonomous execution loop. It feeds an agent one small backlog item at a time. An item flips to `verified` only when a script runs its literal `verifyCommand`, that command exits 0, and a write-boundary guard confirms no protected file was touched — never on the agent's say-so.

## Two modes

- **Mode A — session-supervised** (`/loop-virtuoso:start`): runs inside your current Claude Code session via a `Stop` hook. Best for watching it work, stepping away briefly, and backlogs of roughly 5–15 items.
- **Mode B — unattended batch** (`scripts/run-batch.sh path/to/backlog.json`): a fresh `claude -p` process per iteration, with a cumulative cost cap. Best for large backlogs and overnight/CI runs. It is intentionally not a slash command because it spawns long-running detached processes.

## Commands

| Command | What it does |
|---|---|
| `/loop-virtuoso:start [backlog]` | Start Mode A over the backlog (default `.delivery-loop/backlog.json`). |
| `/loop-virtuoso:status [backlog]` | Report counts, iteration, stall/violation counts, cost, and the progress-log tail. |
| `/loop-virtuoso:cancel` | Remove the session-local file to stop the loop; backlog state is preserved. |
| `/loop-virtuoso:help` | Show this overview. |

## Getting a backlog

You need a `.delivery-loop/backlog.json` before starting. Use the **`backlog-compiler`** skill to convert a PRD, ticket, or freeform feature description into a loop-ready backlog — it sizes each item to a single context window, orders items by dependency, and writes a literal `verifyCommand` for each one.

For the full behavior — stop reasons, the write-boundary guard, and configuration — see the `iteration-loop` skill.

---
description: "Explain what loop-virtuoso does, its two modes, and its commands"
---

# loop-virtuoso

loop-virtuoso runs a deterministic, backlog-driven autonomous execution loop. It feeds an agent one small backlog item at a time. An item flips to `verified` only when a script runs its literal `verifyCommand`, that command exits 0, and a write-boundary guard confirms no protected file was touched - never on the agent's say-so.

## Two modes

- **Mode A - session-supervised** (`/loop-virtuoso:start`): runs inside your current Claude Code session via a `Stop` hook. Best for watching it work, stepping away briefly, and backlogs of roughly 5-15 items.
- **Mode B - unattended batch** (`scripts/run-batch.sh path/to/backlog.json`): a fresh `claude -p` process per iteration, with a cumulative cost cap. Best for large backlogs and overnight/CI runs. It is intentionally not a slash command because it spawns long-running detached processes.

## Commands

| Command | What it does |
|---|---|
| `/loop-virtuoso:start [backlog]` | Start Mode A over the backlog (default `.code-virtuoso/loop/backlog.json` at the git root). Needs a clean working tree and refuses to run on the default branch. |
| `/loop-virtuoso:status [backlog]` | Report counts, iteration, stall/violation counts, and the progress-log and events tails. |
| `/loop-virtuoso:cancel` | Stop the loop and record a `cancelled` event; backlog state is preserved. |
| `/loop-virtuoso:harden [--scope user\|project] [--with statusline,telemetry,sandbox]` | Show a dry-run diff of a guardrail baseline for your Claude Code settings; applies it only after you approve. |
| `/loop-virtuoso:doctor` | Read-only audit of your Claude Code setup: duplicate skills and agents, skill listing size, dead CLAUDE.md skill references, plaintext MCP secrets (key names only), settings gaps, orphan plugin caches. |
| `/loop-virtuoso:eval-setup [suite] [-k N]` | Measure your setup (CLAUDE.md, skills, plugins) against vanilla Claude Code (`--safe-mode`) on a fixed task suite: pass@k, pass^k, delta, cost. Dry run first; real runs cost money. |
| `/loop-virtuoso:scaffold <devcontainer\|issue-to-pr\|pilot-backlog> [--force]` | Copy a starter template to the git root. Refuses to overwrite; `--force` backs up first. |
| `/loop-virtuoso:help` | Show this overview. |

## Guard hooks (opt-in)

Three hooks guard ordinary sessions that run no loop (the secrets guard also acts inside one). All are off until you set them in the `loop.guard` config namespace:

- `blockSecrets: true` blocks tool calls aimed at secret files (`.env`, keys, `~/.ssh`).
- `protectTests: "ask"` or `"deny"` asks before, or denies, edits to test files already committed; `testGlobs` sets which files count. New test files are always allowed.
- `stopGate: true` runs the lint, static analysis and test commands from `ticket-delivery.commands` before the session stops, and blocks the stop when one fails.

`/loop-virtuoso:harden` can turn on `blockSecrets` and `protectTests` for you. See `references/guardrails.md` in the `iteration-loop` skill.

## Getting a backlog

You need a `.code-virtuoso/loop/backlog.json` before starting. Use the **`backlog-compiler`** skill to convert a PRD, ticket, or freeform feature description into a loop-ready backlog - it sizes each item to a single context window, orders items by dependency, and writes a literal `verifyCommand` for each one.

For the full behavior - stop reasons, the write-boundary guard, and configuration - see the `iteration-loop` skill.

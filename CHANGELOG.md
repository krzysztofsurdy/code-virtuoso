# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-01

### Added

- `backlog-compiler` skill — converts a PRD, ticket, or freeform feature description into a `.delivery-loop/backlog.json`, sizing each step to one context window, ordering items by dependency, and writing a literal `verifyCommand` per step.
- `iteration-loop` skill — orchestrates and documents the execution loop over a backlog, with completion gated by deterministic verification rather than self-report.
- Two run modes: Mode A (session-supervised, via a `Stop` hook inside the current Claude Code session) and Mode B (unattended batch, a fresh process per iteration with a cumulative cost cap).
- Write-boundary guard: a content-tamper check that snapshots `backlog.json`/`teams.json` outside the project directory before each step and restores/flags any edit to them (including a rewritten `verifyCommand`) before any other check runs, a `PreToolUse` hook denying `Edit`/`Write` to protected paths in real time, and a post-iteration `git diff` audit in the verification gate that catches changes from any tool.
- Six-state stop-reason machine: `complete`, `blocked_out`, `max_iterations`, `stalled`, `violation_limit`, and `corrupted`, plus two Mode-B-only additions: `total_budget_exceeded` (cumulative `total_cost_usd` hit the configured cap — reported under both API billing and a subscription) and `invocation_failed` (a `claude -p` call returned no usable result, typically a subscription's usage/rate limit, which never surfaces as a cost figure).
- Four slash commands: `/loop-virtuoso:start`, `/loop-virtuoso:status`, `/loop-virtuoso:cancel`, and `/loop-virtuoso:help`.
- Multi-step backlog items: each item is an ordered sequence of `steps`, each step carrying its own `participant`, `instructions`, `verifyCommand`, `status`, `attempts`, and `notes`. Item status is derived from its steps, never stored separately; a single-step item is the common case.
- Reusable participants and teams via `.delivery-loop/teams.json`: a participant is either an `agent` (delegate to an existing Claude Code subagent) or an inline `persona` (own system prompt and tool list); a team is a named, ordered group of participants used as a compile-time template that the engine expands into steps but never runs as a unit.
- Structured event log at `.delivery-loop/events.jsonl` — one JSON object per state transition (step verdict, item verified/blocked, loop stopped) — alongside the human-readable `progress.log`.

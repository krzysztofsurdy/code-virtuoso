---
tags: [outcome, context-engineering]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

We use Codex and Claude Code on the same repo. The same project rules sit in both AGENTS.md and CLAUDE.md and they have drifted apart. How should we set the files up, and will it also cut the token cost of each Claude Code session?

---
tags: [outcome, agent-creator]
max_turns: 14
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create the sub-agent file agents/doc-checker.md for our Claude Code plugin. It checks docs for stale commands. Here are my answers so you do not need to ask: it must stay read-only and never change files, but it should remember what it found between sessions (project memory). It should preload our release-notes skill (skills/release-notes) on every run. I also want a PreToolUse hook and our docs-lint MCP server attached to this agent itself. The plugin ships to other teams. I approve all of this, so write only the one agent file.

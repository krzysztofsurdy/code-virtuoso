---
tags: [outcome, hooks-and-guardrails]
max_turns: 8
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I set up a Claude Code hook to stop the agent from ever reading my .env file, but it still got read. The files are in .claude/. Please find out why and fix it, then show me the final hook script and the final settings.json hooks entry in your reply.

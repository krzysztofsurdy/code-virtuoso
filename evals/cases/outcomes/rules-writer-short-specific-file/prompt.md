---
tags: [outcome, agentic-rules-writer]
max_turns: 16
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the shared project rules file for this repo. It is for Claude Code only, team scope, no other tools. Here are my answers so you do not need to ask: the commands are the ones in package.json, commits look like "PROJ-123: description" and branches like feat/PROJ-123_short_name, money is stored as integer cents and nobody edits anything under generated/ by hand, ask before adding a dependency. Never force-push main and never read .env files. I have no personal preferences. I approve all of this, and write only the file: do not install deny rules or hooks.

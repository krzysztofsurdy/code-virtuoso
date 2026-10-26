---
tags: [outcome, plugin-creator]
max_turns: 14
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

This repo holds our team's Claude Code content: two skills under skills/ and one reviewer agent under agents/. Package it as installable plugins from this one repo, with a marketplace file at the repo root, so people can install either "team-skills" (the two skills) or "team-agents" (the reviewer agent) separately. Answers so you do not need to ask: owner is "Platform Team", marketplace name "platform-tools", plugin names as above, no hooks, no MCP servers, no other components. I approve all of this, so write the files and do not ask me anything.

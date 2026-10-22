---
tags: [trigger, godot]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Our CI runs godot --headless on tests/runner.gd and the job is green even when an assert fails. Find out why and fix the runner.

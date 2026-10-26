---
tags: [outcome, godot]
max_turns: 10
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill, Edit, Write]
---

Our CI script ci.sh prints "CI green" on every push, but a teammate saw "Assertion failed" in the log of tests/run.gd and the add() function is obviously wrong. Why does the job pass, and how do I make CI fail properly? Explain the cause for each of the two godot commands in ci.sh, then give me the fixed tests/run.gd and ci.sh in your answer.

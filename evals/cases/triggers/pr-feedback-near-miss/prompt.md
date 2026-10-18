---
tags: [trigger, near-miss, pr-feedback]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Review this diff for bugs: -  return a + b
+  return a - b   # in function add(a, b)

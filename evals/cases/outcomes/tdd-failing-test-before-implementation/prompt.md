---
tags: [outcome, tdd]
max_turns: 14
timeout_seconds: 300
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---

Add a function slugify(title) to slug.py: lowercase the title, turn runs of spaces and punctuation into one hyphen, and trim hyphens from the ends. So 'Hello, World!' becomes 'hello-world'. The tests run with: python3 -m unittest

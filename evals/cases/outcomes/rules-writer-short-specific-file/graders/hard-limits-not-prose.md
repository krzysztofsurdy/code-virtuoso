---
type: regex
target:
  source: file
  path: AGENTS.md
flags: i
match: not_contains
pattern: 'never (force.?push|read[^\n]{0,30}\.env|commit secrets)'
---

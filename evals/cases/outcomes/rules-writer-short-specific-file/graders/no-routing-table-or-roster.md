---
type: regex
target:
  source: file
  path: AGENTS.md
flags: i
match: not_contains
pattern: '(?:^|\n)#+\s*(?:skills?|agents?|teams?)\b|\|\s*(?:skill|agent)s?\s*\|'
---

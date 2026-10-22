---
type: regex
target:
  source: file
  path: AGENTS.md
flags: i
match: not_contains
pattern: '(?:^|[\s(`])/(?:[a-z]+-)+[a-z]+\b|\bskills?\b'
---

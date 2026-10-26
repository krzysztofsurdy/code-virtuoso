---
type: regex
target:
  source: file
  path: agents/doc-checker.md
match: not_contains
pattern: '(?:^|\n)skills\s*:\s*(?:\[[^\]]*release-notes|(?:\n\s*-[^\n]*)*?\n\s*-\s*[''"]?release-notes)'
weight: 2
---

---
type: regex
target:
  source: file
  path: agents/doc-checker.md
match: not_contains
pattern: '(?:^|\n)(?:hooks|mcpServers|permissionMode)\s*:'
weight: 2
---

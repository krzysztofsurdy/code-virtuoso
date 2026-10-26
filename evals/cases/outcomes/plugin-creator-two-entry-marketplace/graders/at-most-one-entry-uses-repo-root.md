---
type: regex
target:
  source: file
  path: .claude-plugin/marketplace.json
pattern: '^(?![\s\S]*"source"\s*:\s*"\./?"[\s\S]*"source"\s*:\s*"\./?")[\s\S]*"source"[\s\S]*$'
weight: 3
---

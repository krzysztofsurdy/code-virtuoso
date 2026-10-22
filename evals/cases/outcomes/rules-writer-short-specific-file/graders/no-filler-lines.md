---
type: regex
target:
  source: file
  path: AGENTS.md
flags: i
match: not_contains
pattern: 'simplicity first|minimal blast radius|root causes only|read before editing|prefer editing over|don.t guess|prove it works|minimal diffs|premature abstraction|remove dead code|clean, (well-structured|maintainable)|prefer official docs|follow owasp|solid principles'
---

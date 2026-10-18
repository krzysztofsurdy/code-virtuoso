---
type: tool_order
before:
  tool: Bash
  input_match: 'unittest'
after:
  tool: Write
  input_match: '"file_path"\s*:\s*"[^"]*/slug\.py"'
---

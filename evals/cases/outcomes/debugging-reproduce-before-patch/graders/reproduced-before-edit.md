---
type: tool_order
before:
  tool: Bash
  input_match: '1,299|1299|checkout\(|parse_price\('
after:
  tool: Edit
  input_match: '"file_path"\s*:\s*"[^"]*orders\.py"'
weight: 2
---

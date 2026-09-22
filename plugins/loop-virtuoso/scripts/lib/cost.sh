#!/bin/bash
# Extracts/accumulates total_cost_usd from `claude -p --output-format json`.
# Mode B only -- Mode A relies on --max-iterations for cost control instead.

# cost_extract <json_output>
# Defaults to 0 if the field is absent, so a missing/older CLI build degrades
# the budget check to a no-op rather than crashing the loop.
cost_extract() {
  local json_output="$1"
  echo "$json_output" | jq -r '.total_cost_usd // 0' 2>/dev/null || echo 0
}

# cost_budget_exceeded <cumulative_usd> <budget_usd_or_null>
cost_budget_exceeded() {
  local cumulative="$1" budget="$2"
  [[ -z "$budget" || "$budget" == "null" ]] && return 1
  awk -v c="$cumulative" -v b="$budget" 'BEGIN { exit !(c >= b) }'
}

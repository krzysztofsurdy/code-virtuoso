#!/bin/bash
# Suite validation and metrics for eval-setup.sh.
#
# A suite is <root>/.code-virtuoso/loop/evals/suite.json:
#   {"version": 1,
#    "tasks": [{"id", "prompt", "setup"?, "verifyCommand"}],
#    "config": {"k"?, "maxTurns"?, "allowedTools"?, "permissionMode"?, "maxCostUsd"?}}
# A task is a backlog step in eval form: the literal verifyCommand is the only
# grader, exit 0 = pass.

EVALS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$EVALS_LIB_DIR/config.sh"

EVALS_DEFAULT_VANILLA_ARGS='["--safe-mode"]'

evals_dir_for_root() { echo "$1/${CV_DIR_NAME}/loop/evals"; }

# evals_suite_problems <suite_file>
# One problem per line; nothing when the suite is valid.
evals_suite_problems() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "suite file not found: $file"
    return
  fi
  if ! jq empty "$file" >/dev/null 2>&1; then
    echo "suite is not valid JSON: $file"
    return
  fi
  jq -r '
    def text: type == "string" and length > 0;
    def posint: type == "number" and . >= 1 and . == floor;
    def tid: if type == "object" then .id else null end;
    if type != "object" then "suite is not a JSON object" else
    [
      (if .version == 1 then empty else "version must be 1" end),
      (if (.tasks | type) == "array" and (.tasks | length) > 0 then empty else "tasks missing or empty" end),
      (if (.tasks | type) == "array" then
        (.tasks | to_entries[] | .key as $i | .value as $t |
          ("task[" + ($i | tostring) + "]" + (if ($t | tid | text) then " (" + $t.id + ")" else "" end)) as $ref |
          if ($t | type) != "object" then $ref + ": not an object" else
            (if ($t.id | text) then empty else $ref + ": missing or empty id" end),
            (if ($t.prompt | text) then empty else $ref + ": missing or empty prompt" end),
            (if ($t.verifyCommand | text) then empty else $ref + ": verifyCommand missing or empty" end),
            (if ($t | has("setup")) and ($t.setup | type) != "string" then $ref + ": setup must be a string" else empty end)
          end),
        ([.tasks[] | tid | select(type == "string")] | group_by(.) | map(select(length > 1) | .[0]) | .[] | "duplicate task id: " + .)
      else empty end),
      ((.config // {}) as $c |
        if ($c | type) != "object" then "config must be an object" else
          (if ($c | has("k")) and ($c.k | posint | not) then "config.k must be a positive integer" else empty end),
          (if ($c | has("maxTurns")) and ($c.maxTurns | posint | not) then "config.maxTurns must be a positive integer" else empty end),
          (if ($c | has("permissionMode")) and ($c.permissionMode | text | not) then "config.permissionMode must be a non-empty string" else empty end),
          (if ($c | has("allowedTools")) and (($c.allowedTools | type) != "array" or ($c.allowedTools | all(text) | not)) then "config.allowedTools must be an array of strings" else empty end),
          (if ($c | has("maxCostUsd")) and (($c.maxCostUsd | type) != "number" or $c.maxCostUsd <= 0) then "config.maxCostUsd must be a positive number" else empty end)
        end)
    ] | .[]
    end
  ' "$file"
}

# evals_vanilla_args <root>
# loop.evalSetup.vanillaArgs from the merged config layers, else the default,
# as a compact JSON array. Returns 1 when the configured value is not an
# array of strings.
evals_vanilla_args() {
  local args
  args="$(cv_merged_config "$1" | jq -c --argjson def "$EVALS_DEFAULT_VANILLA_ARGS" '.loop.evalSetup.vanillaArgs // $def')"
  echo "$args" | jq -e 'type == "array" and all(type == "string")' >/dev/null || return 1
  echo "$args"
}

# evals_summarize <trials_jsonl> <tasks_json_array> <arms_json_array>
# Trial lines are {task, arm, trial, pass, costUsd, turns, durationSec}.
# Rows per task and arm: passes/trials, passAtK (at least one pass), passHatK
# (every trial passed). Arm totals count only tasks that ran at least one
# trial, so a cost-capped run is not scored as failures. delta is setup minus
# vanilla, null unless both arms ran.
evals_summarize() {
  jq -s -c --argjson order "$2" --argjson arms "$3" '
    def r6: (. * 1000000 | round) / 1000000;
    def count(f): map(select(f)) | length;
    . as $trials
    | [ $order[] as $t | $arms[] as $a
        | [ $trials[] | select(.task == $t and .arm == $a) ] as $ts
        | { task: $t, arm: $a,
            trials: ($ts | length),
            passes: ($ts | count(.pass)),
            costUsd: ([$ts[].costUsd] | add // 0 | r6),
            turns: ([$ts[].turns] | add // 0),
            durationSec: ([$ts[].durationSec] | add // 0) }
        | .passAtK = (.passes >= 1)
        | .passHatK = (.trials > 0 and .passes == .trials) ] as $rows
    | { tasks: $rows,
        arms: (reduce $arms[] as $a ({};
          ([ $rows[] | select(.arm == $a and .trials > 0) ]) as $r
          | .[$a] = {
              tasks: ($r | length),
              passAtK: ($r | count(.passAtK)),
              passHatK: ($r | count(.passHatK)),
              passes: ([$r[].passes] | add // 0),
              trials: ([$r[].trials] | add // 0),
              costUsd: ([$r[].costUsd] | add // 0 | r6) }
          | .[$a].passRate = (if .[$a].trials > 0 then (.[$a].passes / .[$a].trials * 10000 | round) / 10000 else 0 end))),
        totalCostUsd: ([$trials[].costUsd] | add // 0 | r6) }
    | .delta = (if (.arms | has("setup") and has("vanilla")) then
        { passAtK: (.arms.setup.passAtK - .arms.vanilla.passAtK),
          passHatK: (.arms.setup.passHatK - .arms.vanilla.passHatK),
          passRate: ((.arms.setup.passRate - .arms.vanilla.passRate) * 10000 | round / 10000) }
      else null end)
  ' "$1"
}

# evals_sha256 <file>
evals_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

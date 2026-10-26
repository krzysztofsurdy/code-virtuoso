#!/bin/bash
# Suite validation and metrics for eval-setup.sh.
#
# A suite is <root>/.code-virtuoso/loop/evals/suite.json:
#   {"version": 1,
#    "tasks": [{"id", "prompt", "setup"?, "verifyCommand"}],
#    "config": {"k"?, "maxTurns"?, "allowedTools"?, "permissionMode"?, "maxCostUsd"?,
#               "protectedPaths"?}}
# A task is a backlog step in eval form: the literal verifyCommand is the only
# grader, exit 0 = pass.

EVALS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$EVALS_LIB_DIR/config.sh"
# shellcheck source=./paths.sh
source "$EVALS_LIB_DIR/paths.sh"

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
          (if ($c | has("protectedPaths")) and (($c.protectedPaths | type) != "array" or ($c.protectedPaths | all(text) | not)) then "config.protectedPaths must be an array of strings" else empty end),
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

# evals_protected_globs <root> <suite_file>
# config.protectedPaths from the suite, else loop.guard.testGlobs, else the
# default test globs, as a compact JSON array ready for paths_match_any.
evals_protected_globs() {
  local globs
  globs="$(jq -c '.config.protectedPaths // empty' "$2")"
  [[ -n "$globs" ]] || globs="$(cv_test_globs "$1")"
  paths_with_root_variants "$globs"
}

# evals_snapshot <worktree>
# A git tree of every file in <worktree> that git does not ignore, tracked or
# not, built in a throwaway index so the agent's own index or commits do not
# change the baseline.
evals_snapshot() {
  local index_dir rc=0
  index_dir="$(mktemp -d)"
  (
    cd "$1"
    cp "$(git rev-parse --git-path index)" "$index_dir/index" 2>/dev/null || true
    GIT_INDEX_FILE="$index_dir/index" git add -A .
    GIT_INDEX_FILE="$index_dir/index" git write-tree
  ) || rc=$?
  rm -rf "$index_dir"
  return "$rc"
}

# evals_tampered_paths <worktree> <base_tree> <after_tree> <globs_json>
# Files of <base_tree> modified or deleted in <after_tree> that match a glob,
# one per line. New files never count.
evals_tampered_paths() {
  local path
  while IFS= read -r -d '' path; do
    paths_match_any "$path" "$4" && echo "$path"
  done < <(git -C "$1" diff-tree -r -z --name-only --no-renames --diff-filter=DMT "$2" "$3")
  return 0
}

# evals_summarize <trials_jsonl> <tasks_json_array> <arms_json_array> <k>
# Trial lines are {task, arm, trial, pass, tampered, costUsd, turns, durationSec}.
# Rows per task and arm: passes/trials, complete (exactly k trials ran),
# passAtK (at least one pass), passHatK (complete and every trial passed).
# Arm totals and delta count only tasks complete in every arm, so a run cut
# off between arms compares the same tasks on both sides;
# excludedPartialTasks counts the tasks that ran but were left out.
evals_summarize() {
  jq -s -c --argjson order "$2" --argjson arms "$3" --argjson k "$4" '
    def r6: (. * 1000000 | round) / 1000000;
    def count(f): map(select(f)) | length;
    . as $trials
    | [ $order[] as $t | $arms[] as $a
        | [ $trials[] | select(.task == $t and .arm == $a) ] as $ts
        | { task: $t, arm: $a,
            trials: ($ts | length),
            passes: ($ts | count(.pass)),
            tampered: ($ts | count(.tampered)),
            costUsd: ([$ts[].costUsd] | add // 0 | r6),
            turns: ([$ts[].turns] | add // 0),
            durationSec: ([$ts[].durationSec] | add // 0) }
        | .complete = (.trials == $k)
        | .passAtK = (.passes >= 1)
        | .passHatK = (.complete and .passes == $k) ] as $rows
    | [ $order[] | . as $t | select([ $rows[] | select(.task == $t) | .complete ] | all) ] as $fair
    | { tasks: $rows,
        arms: (reduce $arms[] as $a ({};
          ([ $rows[] | select(.arm == $a and (.task | IN($fair[]))) ]) as $r
          | .[$a] = {
              tasks: ($r | length),
              passAtK: ($r | count(.passAtK)),
              passHatK: ($r | count(.passHatK)),
              passes: ([$r[].passes] | add // 0),
              trials: ([$r[].trials] | add // 0),
              costUsd: ([$r[].costUsd] | add // 0 | r6),
              tampered: ([ $rows[] | select(.arm == $a) | .tampered ] | add // 0) }
          | .[$a].passRate = (if .[$a].trials > 0 then (.[$a].passes / .[$a].trials * 10000 | round) / 10000 else 0 end))),
        excludedPartialTasks: ([ $rows[] | select(.trials > 0) | .task ] | unique | map(select(IN($fair[]) | not)) | length),
        tamperedTrials: ($trials | count(.tampered)),
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

#!/bin/bash
# Measure the user's own Claude Code setup against a vanilla Claude Code.
#   ./scripts/eval-setup.sh [suite.json] [-k N] [--arms setup,vanilla]
#                           [--max-cost-usd N] [--dry-run]
#
# Default suite: <git root>/.code-virtuoso/loop/evals/suite.json. For each
# task, k trials per arm, interleaved (trial 1 of every arm, then trial 2...)
# so a cost cap cuts every arm at the same depth. A trial is a throwaway
# detached worktree at HEAD: run the task's setup, one `claude -p`, a tamper
# audit (a changed or deleted protected file fails the trial), then the
# literal verifyCommand (exit 0 = pass). The worktree is always removed.
#
# Arms:
#   setup    plain `claude -p`: CLAUDE.md, skills, plugins, hooks, MCP, settings
#   vanilla  the same call plus loop.evalSetup.vanillaArgs (default
#            --safe-mode: no customizations, same auth, model and permissions)
#
# One JSON line per run goes to <root>/.code-virtuoso/loop/evals/history.jsonl.
# Exit 0 when every trial ran; 1 on an invalid suite or a stop (cost_cap,
# setup_failed, invocation_failed).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/evals.sh
source "$SCRIPT_DIR/lib/evals.sh"
# shellcheck source=./lib/cost.sh
source "$SCRIPT_DIR/lib/cost.sh"
# shellcheck source=./lib/invoke.sh
source "$SCRIPT_DIR/lib/invoke.sh"
# shellcheck source=./lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"

usage() {
  echo "usage: eval-setup.sh [suite.json] [-k N] [--arms setup,vanilla] [--max-cost-usd N] [--dry-run]" >&2
  exit 1
}

# need_value <flag> <remaining-arg-count>
need_value() { (( $2 >= 2 )) || { echo "error: $1 needs a value" >&2; usage; }; }

suite=""
k_flag=""
arms_csv="setup,vanilla"
max_cost_flag=""
dry_run=0
while (( $# > 0 )); do
  case "$1" in
    -k) need_value "$1" $#; k_flag="$2"; shift 2 ;;
    --arms) need_value "$1" $#; arms_csv="$2"; shift 2 ;;
    --max-cost-usd) need_value "$1" $#; max_cost_flag="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage ;;
    -*) echo "error: unknown option: $1" >&2; usage ;;
    *) suite="$1"; shift ;;
  esac
done

root="$(loop_repo_root .)"
if [[ -z "$root" ]]; then
  echo "error: not inside a git repository; trials run in git worktrees" >&2
  exit 1
fi
root="$(cd "$root" && pwd -P)"
evals_dir="$(evals_dir_for_root "$root")"
suite="${suite:-$evals_dir/suite.json}"
history_file="$evals_dir/history.jsonl"

problems="$(evals_suite_problems "$suite")"
if [[ -n "$problems" ]]; then
  echo "error: invalid suite $suite:" >&2
  echo "$problems" | sed 's/^/  - /' >&2
  exit 1
fi

arms=()
IFS=',' read -r -a requested_arms <<< "$arms_csv"
for arm in "${requested_arms[@]+"${requested_arms[@]}"}"; do
  case "$arm" in
    setup|vanilla) arms+=("$arm") ;;
    *) echo "error: unknown arm \"$arm\" (use setup, vanilla or both)" >&2; exit 1 ;;
  esac
done
(( ${#arms[@]} > 0 )) || { echo "error: --arms is empty" >&2; exit 1; }
arms_json="$(jq -nc '$ARGS.positional' --args "${arms[@]}")"

k="${k_flag:-$(jq -r '.config.k // 3' "$suite")}"
[[ "$k" =~ ^[1-9][0-9]*$ ]] || { echo "error: -k must be a positive integer (got: $k)" >&2; exit 1; }
max_cost="${max_cost_flag:-$(jq -r '.config.maxCostUsd // empty' "$suite")}"
if [[ -n "$max_cost" ]] && ! [[ "$max_cost" =~ ^[0-9]*\.?[0-9]+$ ]]; then
  echo "error: --max-cost-usd must be a positive number (got: $max_cost)" >&2
  exit 1
fi
max_turns="$(jq -r '.config.maxTurns // 40' "$suite")"
permission_mode="$(jq -r '.config.permissionMode // "acceptEdits"' "$suite")"
allowed_tools=()
while IFS= read -r tool; do
  [[ -n "$tool" ]] && allowed_tools+=("$tool")
done < <(jq -r '.config.allowedTools // [] | .[]' "$suite")

vanilla_args_json="$(evals_vanilla_args "$root")" || {
  echo "error: loop.evalSetup.vanillaArgs must be an array of strings" >&2
  exit 1
}
vanilla_args=()
while IFS= read -r a; do
  vanilla_args+=("$a")
done < <(echo "$vanilla_args_json" | jq -r '.[]')

task_count="$(jq '.tasks | length' "$suite")"
tasks_json="$(jq -c '[.tasks[].id]' "$suite")"
protected_globs="$(evals_protected_globs "$root" "$suite")"
head_sha="$(git -C "$root" rev-parse --verify -q HEAD)" || {
  echo "error: the repository has no commits; trials start from HEAD" >&2
  exit 1
}

base_args=(--output-format json --permission-mode "$permission_mode" --max-turns "$max_turns")
if (( ${#allowed_tools[@]} > 0 )); then
  base_args+=(--allowedTools "${allowed_tools[@]}")
fi

# arm_args <arm>: the arm's extra CLI arguments, one per line.
arm_args() {
  [[ "$1" == vanilla ]] || return 0
  printf '%s\n' "${vanilla_args[@]+"${vanilla_args[@]}"}"
}

# remaining_budget <cap> <spent>: the cap minus the spend, without trailing zeros.
remaining_budget() {
  awk -v cap="$1" -v spent="$2" 'BEGIN { s = sprintf("%.6f", cap - spent); sub(/0+$/, "", s); sub(/\.$/, "", s); print s }'
}

echo "Suite      : $suite ($task_count tasks)"
echo "Repository : $root @ ${head_sha:0:12} (worktrees start from HEAD; uncommitted changes are not in them)"
echo "Arms       : ${arms[*]}"
echo "Trials     : $((task_count * ${#arms[@]} * k)) trials ($task_count tasks x ${#arms[@]} arms x k=$k)"
echo "Max turns  : $max_turns per trial"
echo "Cost cap   : ${max_cost:+\$}${max_cost:-none}"
echo "History    : $history_file"

if (( dry_run )); then
  echo
  echo "Dry run: nothing is invoked. Per-trial command:"
  for arm in "${arms[@]}"; do
    extra="$(arm_args "$arm" | paste -sd ' ' -)"
    printf '  %-8s claude -p <prompt> %s\n' "$arm" "${base_args[*]}${extra:+ $extra}"
  done
  echo
  echo "Tasks:"
  jq -r '.tasks[] | "  \(.id): verify `\(.verifyCommand)`" + (if (.setup // "") != "" then ", setup `\(.setup)`" else "" end)' "$suite"
  exit 0
fi

run_tmp="$(mktemp -d)"
trials_file="$run_tmp/trials.jsonl"
: > "$trials_file"
worktree=""

remove_worktree() {
  [[ -n "$worktree" ]] || return 0
  git -C "$root" worktree remove --force "$worktree" >/dev/null 2>&1 || rm -rf "$worktree"
  worktree=""
}
cleanup() {
  remove_worktree
  git -C "$root" worktree prune >/dev/null 2>&1 || true
  rm -rf "$run_tmp"
}
trap cleanup EXIT

cumulative_cost=0
stop_reason="complete"
trial_seq=0

echo
for (( i = 0; i < task_count; i++ )); do
  task_json="$(jq -c ".tasks[$i]" "$suite")"
  task_id="$(echo "$task_json" | jq -r '.id')"
  prompt="$(echo "$task_json" | jq -r '.prompt')"
  setup_cmd="$(echo "$task_json" | jq -r '.setup // empty')"
  verify_cmd="$(echo "$task_json" | jq -r '.verifyCommand')"

  for (( trial = 1; trial <= k; trial++ )); do
    for arm in "${arms[@]}"; do
      if cost_budget_exceeded "$cumulative_cost" "$max_cost"; then
        stop_reason="cost_cap"
        echo "stop reason=cost_cap cost=$cumulative_cost cap=$max_cost"
        break 3
      fi

      trial_seq=$((trial_seq + 1))
      worktree="$run_tmp/wt-$trial_seq"
      git -C "$root" worktree add --detach -q "$worktree" "$head_sha"

      if [[ -n "$setup_cmd" ]] && ! setup_out="$(cd "$worktree" && bash -c "$setup_cmd" 2>&1 </dev/null)"; then
        stop_reason="setup_failed"
        echo "stop reason=setup_failed task=$task_id detail=\"$(invoke_failure_detail "$setup_out")\""
        break 3
      fi

      base_tree="$(evals_snapshot "$worktree")"

      claude_args=(-p "$prompt" "${base_args[@]}")
      [[ -z "$max_cost" ]] || claude_args+=(--max-budget-usd "$(remaining_budget "$max_cost" "$cumulative_cost")")
      while IFS= read -r a; do
        [[ -n "$a" ]] && claude_args+=("$a")
      done < <(arm_args "$arm")

      started="$(date +%s)"
      invoke_claude "$worktree" "${claude_args[@]}" </dev/null
      duration=$(( $(date +%s) - started ))
      if ! invoke_result_ok "$INVOKE_JSON"; then
        stop_reason="invocation_failed"
        echo "stop reason=invocation_failed task=$task_id arm=$arm hint=\"$(invoke_failure_hint "$INVOKE_STDERR")\" detail=\"$(invoke_failure_detail "$INVOKE_STDERR")\""
        break 3
      fi

      cost="$(cost_extract "$INVOKE_JSON")"
      turns="$(echo "$INVOKE_JSON" | jq -r '.num_turns // 0')"
      cumulative_cost="$(awk -v a="$cumulative_cost" -v b="$cost" 'BEGIN { printf "%.6f", a + b }')"

      tampered_paths="$(evals_tampered_paths "$worktree" "$base_tree" "$(evals_snapshot "$worktree")" "$protected_globs")"
      pass=false tampered=false verdict=fail
      if [[ -n "$tampered_paths" ]]; then
        tampered=true
        verdict="tampered ($(echo "$tampered_paths" | paste -sd ' ' -))"
      elif (cd "$worktree" && bash -c "$verify_cmd" >/dev/null 2>&1 </dev/null); then
        pass=true verdict=pass
      fi
      remove_worktree

      jq -nc --arg task "$task_id" --arg arm "$arm" --argjson trial "$trial" --argjson pass "$pass" \
        --argjson tampered "$tampered" --argjson cost "$cost" --argjson turns "$turns" --argjson dur "$duration" \
        '{task: $task, arm: $arm, trial: $trial, pass: $pass, tampered: $tampered, costUsd: $cost, turns: $turns, durationSec: $dur}' >> "$trials_file"
      echo "$task_id $arm trial $trial/$k: $verdict cost=$cost turns=$turns ${duration}s"
    done
  done
done
remove_worktree

summary="$(evals_summarize "$trials_file" "$tasks_json" "$arms_json" "$k")"

mkdir -p "$evals_dir"
echo "$summary" | jq -c \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg sha "$head_sha" \
  --arg suite "${suite#"$root"/}" --arg hash "$(evals_sha256 "$suite")" \
  --argjson k "$k" --argjson maxTurns "$max_turns" --argjson arms "$arms_json" \
  --argjson vanilla "$vanilla_args_json" --arg reason "$stop_reason" \
  '{ts: $ts, gitSha: $sha, suite: $suite, suiteHash: $hash, k: $k, maxTurns: $maxTurns,
    armsRun: $arms, vanillaArgs: $vanilla, stopReason: $reason} + .' >> "$history_file"

yes_no() { [[ "$1" == true ]] && echo yes || echo no; }
signed() { awk -v v="$1" 'BEGIN { printf (v > 0 ? "+%s" : "%s"), v }'; }

echo
echo "----------------------------------------"
printf '%-16s %-8s %-7s %-7s %-7s %s\n' Task Arm Passes "pass@k" "pass^k" Cost
while IFS=$'\t' read -r t a p n at ht c; do
  printf '%-16s %-8s %-7s %-7s %-7s $%s\n' "$t" "$a" "$p/$n" "$(yes_no "$at")" "$(yes_no "$ht")" "$c"
done < <(echo "$summary" | jq -r '.tasks[] | [.task, .arm, .passes, .trials, .passAtK, .passHatK, .costUsd] | @tsv')
echo
while IFS=$'\t' read -r a n at ht p tr c; do
  printf '%-8s pass@k %s/%s  pass^k %s/%s  passes %s/%s  cost $%s\n' "$a" "$at" "$n" "$ht" "$n" "$p" "$tr" "$c"
done < <(echo "$summary" | jq -r '.arms | to_entries[] | [.key, .value.tasks, .value.passAtK, .value.passHatK, .value.passes, .value.trials, .value.costUsd] | @tsv')
if [[ "$(echo "$summary" | jq -r '.delta != null')" == true ]]; then
  echo "Delta (setup - vanilla): pass@k $(signed "$(echo "$summary" | jq -r .delta.passAtK)")  pass^k $(signed "$(echo "$summary" | jq -r .delta.passHatK)")  pass rate $(signed "$(echo "$summary" | jq -r .delta.passRate)")"
fi
excluded="$(echo "$summary" | jq -r .excludedPartialTasks)"
if (( excluded > 0 )); then
  echo "Excluded    : $excluded partial task(s) with fewer than k=$k trials in an arm; totals and delta leave them out"
fi
tampered_total="$(echo "$summary" | jq -r .tamperedTrials)"
if (( tampered_total > 0 )); then
  echo "Tampered    : $tampered_total trial(s) changed a protected file and were failed without running verifyCommand"
fi
echo "Total cost  : \$$(echo "$summary" | jq -r .totalCostUsd)"
echo "Stop reason : $stop_reason"
echo "----------------------------------------"

[[ "$stop_reason" == complete ]]

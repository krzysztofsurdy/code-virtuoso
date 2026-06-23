#!/bin/bash
# Mode B: unattended batch engine.
#   ./scripts/run-batch.sh path/to/.delivery-loop/backlog.json
#
# Owns the loop itself: a fresh `claude -p` per iteration (no -c/--resume), then
# the shared verify-gate verdict applied via lib/backlog.sh. The backlog file is
# the only state carried between iterations.
#
# Exit code is the CI contract: 0 if the backlog finished (complete/blocked_out),
# 1 on a guardrail stop (max_iterations/stalled/violation_limit/
# total_budget_exceeded/invocation_failed).
#
# total_cost_usd is reported on both API billing and a Claude subscription (a
# real notional figure even with no separate charge), so total_budget_exceeded
# works either way. What a subscription's usage/rate limit can't express as
# cost is a hard stop -- that surfaces as invocation_failed instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/backlog.sh
source "$SCRIPT_DIR/lib/backlog.sh"
# shellcheck source=./lib/verify-gate.sh
source "$SCRIPT_DIR/lib/verify-gate.sh"
# shellcheck source=./lib/cost.sh
source "$SCRIPT_DIR/lib/cost.sh"
# shellcheck source=./lib/teams.sh
source "$SCRIPT_DIR/lib/teams.sh"

backlog_file="${1:-}"
if [[ -z "$backlog_file" ]]; then
  echo "usage: run-batch.sh <path-to-.delivery-loop/backlog.json>" >&2
  exit 1
fi
if [[ ! -f "$backlog_file" ]]; then
  echo "error: backlog file not found: $backlog_file" >&2
  exit 1
fi
backlog_file="$(cd "$(dirname "$backlog_file")" && pwd)/$(basename "$backlog_file")"

# Backlog lives at <repo>/.delivery-loop/backlog.json; repo root is two levels up.
loop_dir="$(dirname "$backlog_file")"
repo_dir="$(dirname "$loop_dir")"
progress_log="$loop_dir/progress.log"

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Append to progress.log and echo, so a long run can be watched via tail -f.
log_line() {
  local msg="$1"
  printf '%s %s\n' "$(now)" "$msg" | tee -a "$progress_log"
}

# Optional siblings; tolerate them missing.
[[ -x "$SCRIPT_DIR/archive-run.sh" ]] && "$SCRIPT_DIR/archive-run.sh" "$backlog_file" || true
[[ -x "$SCRIPT_DIR/validate-backlog.sh" ]] && "$SCRIPT_DIR/validate-backlog.sh" "$backlog_file" || true

# Commit pre-existing cruft before the first start_sha, so iteration 1 can't get
# a false violation from something that predates the run.
verify_gate_initial_checkpoint "$backlog_file"
events_emit "$backlog_file" "run_started" '{}'

max_iterations="$(backlog_get_config "$backlog_file" maxIterations)"
max_attempts="$(backlog_get_config "$backlog_file" maxAttemptsPerItem)"
max_stall="$(backlog_get_config "$backlog_file" maxStallIterations)"
max_violations="$(backlog_get_config "$backlog_file" maxViolations)"
total_budget="$(backlog_get_config "$backlog_file" totalBudgetUsd)"
per_iter_budget="$(backlog_get_config "$backlog_file" perIterationBudgetUsd)"
per_iter_turns="$(backlog_get_config "$backlog_file" perIterationMaxTurns)"
permission_mode="$(backlog_get_config "$backlog_file" permissionMode)"

# allowedTools is an array -- expand each pattern as its own CLI argument.
allowed_tools=()
allowed_tools_json="$(backlog_get_config_json "$backlog_file" allowedTools)"
if [[ -n "$allowed_tools_json" && "$allowed_tools_json" != "null" ]]; then
  while IFS= read -r tool; do
    [[ -z "$tool" ]] && continue
    allowed_tools+=("$tool")
  done < <(echo "$allowed_tools_json" | jq -r '.[]')
fi

cumulative_cost=0
stall_count=0
violation_count=0
iteration=0
iterations_run=0
stop_reason=""

log_line "run-start project=$(jq -r '.project // empty' "$backlog_file" 2>/dev/null || true) backlog=$backlog_file repo=$repo_dir"

while true; do
  iteration=$((iteration + 1))

  if (( iteration > max_iterations )); then
    stop_reason="max_iterations"
    log_line "stop reason=max_iterations iterations=$((iteration - 1))/$max_iterations"
    break
  fi

  # Mode-B-only stop reason beyond the shared six: cumulative cost hit the total budget.
  if cost_budget_exceeded "$cumulative_cost" "$total_budget"; then
    stop_reason="total_budget_exceeded"
    log_line "stop reason=total_budget_exceeded cost=$cumulative_cost budget=$total_budget"
    break
  fi

  next_step="$(backlog_next_pending_step "$backlog_file")"
  if [[ -z "$next_step" ]]; then
    counts="$(backlog_counts "$backlog_file")"
    blocked="$(echo "$counts" | jq -r '.blocked')"
    if (( blocked > 0 )); then
      stop_reason="blocked_out"
      log_line "stop reason=blocked_out blocked=$(backlog_blocked_items_report "$backlog_file")"
    else
      stop_reason="complete"
      log_line "stop reason=complete counts=$counts"
    fi
    break
  fi

  item_id="$(echo "$next_step" | jq -r '.itemId')"
  step_json="$(echo "$next_step" | jq -c '.step')"
  step_id="$(echo "$step_json" | jq -r '.id')"
  item_json="$(backlog_get_item "$backlog_file" "$item_id")"
  participant_id="$(echo "$step_json" | jq -r '.participant // empty')"
  participant_json="$(teams_get_participant "$(teams_path_for "$backlog_file")" "$participant_id")"
  participant_kind="$(echo "$participant_json" | jq -r '.kind // empty')"
  prompt="$(backlog_build_step_prompt "$item_json" "$step_json" "$participant_json")"
  start_sha="$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "4b825dc642cb6eb9a060e54bf8d69288fbee4904")"

  # Real role switch (stronger than Mode A's prompt framing): a fresh process
  # can BE the participant via CLI flags. Default to the backlog tool list and
  # no role flags; a participant may override one or both.
  step_tools=()
  (( ${#allowed_tools[@]} > 0 )) && step_tools=("${allowed_tools[@]}")
  role_args=()
  case "$participant_kind" in
    agent)
      # Run the call AS an installed subagent. The target project owning that
      # agent is its responsibility, not validated here.
      role_args=(--agent "$(echo "$participant_json" | jq -r '.agent')")
      ;;
    persona)
      role_args=(--append-system-prompt "$(echo "$participant_json" | jq -r '.systemPrompt')")
      # A persona may narrow tools for just this call (e.g. read-only reviewer),
      # overriding the backlog default so it can't inherit writes.
      if echo "$participant_json" | jq -e 'has("allowedTools")' >/dev/null 2>&1; then
        persona_tools_json="$(echo "$participant_json" | jq -c '.allowedTools')"
        step_tools=()
        while IFS= read -r tool; do
          [[ -z "$tool" ]] && continue
          step_tools+=("$tool")
        done < <(echo "$persona_tools_json" | jq -r '.[]')
        # An explicit [] means "nothing beyond reads", not "fall through to
        # the backlog default" -- dropping --allowedTools entirely would let
        # acceptEdits auto-approve writes regardless, the opposite of what a
        # read-only persona is for.
        if [[ ${#step_tools[@]} -eq 0 ]]; then
          step_tools=(Read Grep Glob)
        fi
      fi
      ;;
  esac

  iterations_run=$((iterations_run + 1))
  log_line "iteration=$iterations_run item=$item_id step=$step_id participant=${participant_id:-none} kind=${participant_kind:-none} status=running"

  # Snapshot right before the worker sees the prompt -- verify_gate_run below
  # compares against this to detect (and undo) any edit to the backlog's own
  # content during the step, regardless of which tool made it.
  verify_gate_snapshot_all "$backlog_file"

  claude_args=(-p "$prompt" --output-format json --permission-mode "$permission_mode")
  if (( ${#step_tools[@]} > 0 )); then
    claude_args+=(--allowedTools "${step_tools[@]}")
  fi
  if (( ${#role_args[@]} > 0 )); then
    claude_args+=("${role_args[@]}")
  fi
  if [[ -n "$per_iter_turns" && "$per_iter_turns" != "null" ]]; then
    claude_args+=(--max-turns "$per_iter_turns")
  fi
  if [[ -n "$per_iter_budget" && "$per_iter_budget" != "null" ]]; then
    claude_args+=(--max-budget-usd "$per_iter_budget")
  fi

  # A max-turns/max-budget cutoff still returns a valid JSON envelope and exits
  # non-zero -- that stops the agent, not the loop, so we swallow the exit code
  # and verify whatever diff exists. An invocation that returns no parseable
  # JSON at all is a different problem: auth failure, network error, or (most
  # common under a Claude subscription rather than API billing) the plan's
  # usage/rate limit. That gets its own stop reason instead of silently
  # counting as a stall or burning through retries against an active limit.
  claude_stderr_file="$(mktemp)"
  claude_json="$( (cd "$repo_dir" && claude "${claude_args[@]}") 2>"$claude_stderr_file" )" || true
  claude_stderr="$(cat "$claude_stderr_file")"
  rm -f "$claude_stderr_file"

  if ! echo "$claude_json" | jq -e '.result // empty' >/dev/null 2>&1; then
    stop_reason="invocation_failed"
    hint="other (see detail)"
    echo "$claude_stderr" | grep -qiE 'usage limit|rate limit|quota|too many requests|overloaded|billing' \
      && hint="likely a usage/rate limit"
    detail="$(echo "$claude_stderr" | tr '\n' ' ' | cut -c1-200)"
    log_line "stop reason=invocation_failed hint=\"$hint\" detail=\"$detail\""
    break
  fi

  iter_cost="$(cost_extract "$claude_json")"
  cumulative_cost="$(awk -v a="$cumulative_cost" -v b="$iter_cost" 'BEGIN { printf "%.6f", a + b }')"

  verdict_json="$(verify_gate_run "$backlog_file" "$item_id" "$step_id" "$start_sha")"
  # step_apply_verdict is the single write+event point; branch on its action.
  action="$(step_apply_verdict "$backlog_file" "$item_id" "$step_id" "$verdict_json" "$max_attempts" | jq -r '.action')"

  case "$action" in
    verified|failed|blocked)
      # Real diff (pass, or fail that may have hit the cap): not a stall.
      stall_count=0
      ;;
    violation)
      # Always has a diff (gate checks stall first), so reset the stall streak.
      violation_count=$((violation_count + 1))
      stall_count=0
      ;;
    stall)
      stall_count=$((stall_count + 1))
      ;;
  esac

  log_line "iteration=$iterations_run item=$item_id step=$step_id action=$action cost=$cumulative_cost stalls=$stall_count violations=$violation_count"

  if (( violation_count >= max_violations )); then
    stop_reason="violation_limit"
    log_line "stop reason=violation_limit violations=$violation_count/$max_violations"
    break
  fi
  if (( stall_count >= max_stall )); then
    stop_reason="stalled"
    log_line "stop reason=stalled stalls=$stall_count/$max_stall"
    break
  fi
done

final_counts="$(backlog_counts "$backlog_file")"
verified="$(echo "$final_counts" | jq -r '.verified')"
pending="$(echo "$final_counts" | jq -r '.pending')"
blocked="$(echo "$final_counts" | jq -r '.blocked')"

log_line "run-end reason=$stop_reason iterations=$iterations_run verified=$verified pending=$pending blocked=$blocked cost=$cumulative_cost"
events_emit "$backlog_file" "run_stopped" "$(jq -nc --arg reason "$stop_reason" '{reason: $reason}')"

echo "----------------------------------------"
echo "Stop reason : $stop_reason"
echo "Iterations  : $iterations_run"
echo "Verified    : $verified"
echo "Pending     : $pending"
echo "Blocked     : $blocked"
echo "Total cost  : \$$cumulative_cost"
echo "----------------------------------------"

case "$stop_reason" in
  complete|blocked_out) exit 0 ;;
  *) exit 1 ;;
esac

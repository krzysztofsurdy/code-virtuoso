#!/bin/bash
# Structured, append-only event log: <backlog-dir>/events.jsonl, one JSON
# object per line. backlog.sh's mutators call this so nothing changes state
# without being recorded. This is what "full visibility" means here: tail
# or jq the file directly, don't rely on a summary.
#
# progress.log is the human-readable twin: one line per run-level or
# iteration-level transition, written by both run modes through
# progress_append so the two modes produce the same shape.

events_path_for() {
  local backlog_file="$1"
  echo "$(dirname "$backlog_file")/events.jsonl"
}

# events_emit <backlog_file> <event_type> [extra_fields_json_object]
# extra_fields_json_object is a JSON object string, e.g. '{"itemId":"ITEM-001"}'.
events_emit() {
  local backlog_file="$1" event_type="$2" extra_json="${3:-}"
  [[ -n "$extra_json" ]] || extra_json='{}'
  local events_file
  events_file=$(events_path_for "$backlog_file")
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg event "$event_type" --argjson extra "$extra_json" \
    '{ts: $ts, event: $event} + $extra' >> "$events_file"
}

progress_path_for() {
  local backlog_file="$1"
  echo "$(dirname "$backlog_file")/progress.log"
}

# progress_append <backlog_file> <message>
# Appends "<utc timestamp> <message>" to progress.log. Prints nothing.
progress_append() {
  local backlog_file="$1" msg="$2"
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$msg" >> "$(progress_path_for "$backlog_file")"
}

# The helpers below give Mode A (stop-hook.sh) and Mode B (run-batch.sh) the
# same progress.log lines. They call backlog_counts, so the caller must have
# sourced backlog.sh.

# progress_iteration_started <backlog_file> <n> <item_id> <step_id> <participant_id> <participant_kind>
progress_iteration_started() {
  progress_append "$1" "iteration=$2 item=$3 step=$4 participant=${5:-none} kind=${6:-none} status=running"
}

# progress_iteration_result <backlog_file> <n> <item_id> <step_id> <action> <stalls> <violations> [cumulative_cost]
progress_iteration_result() {
  local cost=""
  [[ -n "${8:-}" ]] && cost=" cost=$8"
  progress_append "$1" "iteration=$2 item=$3 step=$4 action=$5${cost} stalls=$6 violations=$7"
}

# progress_run_end <backlog_file> <reason> <iterations> [cumulative_cost]
progress_run_end() {
  local counts cost=""
  counts="$(backlog_counts "$1")"
  [[ -n "${4:-}" ]] && cost=" cost=$4"
  progress_append "$1" "run-end reason=$2 iterations=$3 verified=$(echo "$counts" | jq -r '.verified') pending=$(echo "$counts" | jq -r '.pending') blocked=$(echo "$counts" | jq -r '.blocked')${cost}"
}

# progress_run_start <backlog_file> <repo_dir>
progress_run_start() {
  progress_append "$1" "run-start project=$(jq -r '.project // empty' "$1" 2>/dev/null || true) backlog=$1 repo=$2"
}

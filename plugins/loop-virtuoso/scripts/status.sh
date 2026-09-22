#!/bin/bash
# Read-only progress report for a delivery loop. Never writes any file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/backlog.sh
source "${SCRIPT_DIR}/lib/backlog.sh"
# shellcheck source=lib/teams.sh
source "${SCRIPT_DIR}/lib/teams.sh"

file="${1:-.delivery-loop/backlog.json}"

if [[ ! -f "$file" ]]; then
  echo "No backlog found at: $file" >&2
  echo "Nothing to report -- this project has no delivery loop." >&2
  exit 1
fi

if ! jq empty "$file" >/dev/null 2>&1; then
  echo "Backlog at $file is not valid JSON." >&2
  exit 1
fi

dir="$(cd "$(dirname "$file")" && pwd)"
session_file="${dir}/session.local.json"
progress_log="${dir}/progress.log"
teams_file="$(teams_path_for "$file")"
global_teams_file="$(teams_global_path)"
events_file="$(events_path_for "$file")"

project="$(jq -r '.project // "(unnamed)"' "$file")"
branch="$(jq -r '.branch // "(no branch)"' "$file")"
description="$(jq -r '.description // ""' "$file")"

echo "================================================================"
echo "  Delivery Loop Status"
echo "================================================================"
echo "  Project:     $project"
echo "  Branch:      $branch"
[[ -n "$description" ]] && echo "  Description: $description"
echo

# --- Item counts ---------------------------------------------------------
counts="$(backlog_counts "$file")"
total="$(echo "$counts" | jq -r '.total')"
pending="$(echo "$counts" | jq -r '.pending')"
verified="$(echo "$counts" | jq -r '.verified')"
blocked="$(echo "$counts" | jq -r '.blocked')"

echo "  Items: $total total | $pending pending | $verified verified | $blocked blocked"

step_counts="$(backlog_step_counts "$file")"
s_total="$(echo "$step_counts" | jq -r '.total')"
s_pending="$(echo "$step_counts" | jq -r '.pending')"
s_verified="$(echo "$step_counts" | jq -r '.verified')"
s_blocked="$(echo "$step_counts" | jq -r '.blocked')"
echo "  Steps: $s_total total | $s_pending pending | $s_verified verified | $s_blocked blocked"

if [[ -f "$teams_file" || -f "$global_teams_file" ]]; then
  n_participants="$(teams_list_participants "$file" | jq -r 'length')"
  n_teams="$(teams_list_teams "$file" | jq -r 'length')"
  source_note="project"
  [[ -f "$global_teams_file" ]] && source_note="project + global"
  [[ ! -f "$teams_file" && -f "$global_teams_file" ]] && source_note="global"
  echo "  Teams: $n_participants participant(s), $n_teams team(s) defined ($source_note)"
fi
echo

# --- Step breakdown for items not yet fully verified ---------------------
if [[ "$verified" -lt "$total" ]]; then
  echo "  In-flight items (step status):"
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    iid="$(echo "$item" | jq -r '.id')"
    [[ "$(backlog_item_status "$file" "$iid")" == "verified" ]] && continue
    ititle="$(echo "$item" | jq -r '.title')"
    steps="$(echo "$item" | jq -r '[.steps[] | .id + ":" + .status] | join(", ")')"
    echo "    - [$iid] $ititle -- ${steps:-(no steps)}"
  done < <(jq -c '.items[]' "$file")
  echo
fi

# --- Blocked items -------------------------------------------------------
if [[ "$blocked" -gt 0 ]]; then
  echo "  Blocked items:"
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    iid="$(echo "$entry" | jq -r '.itemId')"
    title="$(echo "$entry" | jq -r '.itemTitle')"
    step_id="$(echo "$entry" | jq -r '.stepId')"
    notes="$(echo "$entry" | jq -r '.notes // ""')"
    echo "    - [$iid] $title (step: $step_id)"
    [[ -n "$notes" ]] && echo "        last failure: $notes"
  done < <(backlog_blocked_items_report "$file" | jq -c '.[]')
  echo
fi

# --- Session (Mode A) ----------------------------------------------------
if [[ -f "$session_file" ]] && jq empty "$session_file" >/dev/null 2>&1; then
  active="$(jq -r '.active // false' "$session_file")"
  if [[ "$active" == "true" ]]; then
    iteration="$(jq -r '.iteration // 0' "$session_file")"
    stall="$(jq -r '.stallCount // 0' "$session_file")"
    violation="$(jq -r '.violationCount // 0' "$session_file")"
    max_iter="$(backlog_get_config "$file" maxIterations)"
    max_stall="$(backlog_get_config "$file" maxStallIterations)"
    max_viol="$(backlog_get_config "$file" maxViolations)"
    current_item="$(jq -r '.currentItemId // ""' "$session_file")"

    echo "  Mode A loop: ACTIVE"
    echo "    Iteration:  ${iteration} / ${max_iter:-?}"
    echo "    Stalls:     ${stall} / ${max_stall:-?}"
    echo "    Violations: ${violation} / ${max_viol:-?}"
    [[ -n "$current_item" ]] && echo "    Current item: $current_item"
    echo
  fi
fi

# --- Recent activity -----------------------------------------------------
if [[ -f "$progress_log" ]]; then
  echo "  Recent activity (last 10 lines of progress.log):"
  tail -n 10 "$progress_log" | while IFS= read -r line; do
    echo "    | $line"
  done
  echo
fi

# --- Recent events -------------------------------------------------------
if [[ -f "$events_file" ]]; then
  echo "  Recent events (last 10 lines of events.jsonl):"
  tail -n 10 "$events_file" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Compact one-line form; fall back to the raw line if it won't parse.
    echo "    | $(echo "$line" | jq -c . 2>/dev/null || echo "$line")"
  done
  echo
fi

# --- Overall status ------------------------------------------------------
session_active=false
if [[ -f "$session_file" ]] && jq empty "$session_file" >/dev/null 2>&1; then
  [[ "$(jq -r '.active // false' "$session_file")" == "true" ]] && session_active=true
fi

if [[ "$blocked" -eq 0 && "$pending" -eq 0 && "$session_active" == "false" && "$total" -gt 0 ]]; then
  echo "  Status: COMPLETE -- all $total item(s) verified."
elif [[ "$session_active" == "true" ]]; then
  echo "  Status: IN PROGRESS -- loop is running."
elif [[ "$blocked" -gt 0 && "$pending" -eq 0 ]]; then
  echo "  Status: STOPPED -- $blocked item(s) blocked, no pending work left."
elif [[ "$pending" -gt 0 ]]; then
  echo "  Status: IDLE -- $pending item(s) pending, loop not currently running."
else
  echo "  Status: empty backlog."
fi
echo "================================================================"

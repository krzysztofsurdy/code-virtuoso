#!/bin/bash
# Named participants (delegate to an existing Claude Code subagent, or an
# inline custom persona) and named teams (an ordered group of participants
# used as a template when compiling a backlog). The engine only ever
# executes participants -- "teams" are a backlog-compiler-time convenience
# for composing steps, not something the engine itself needs at run time.
#
# Two layers, project over global: a project's own .delivery-loop/teams.json
# is checked first; anything not defined there falls back to the shared
# library at teams_global_path, so participants/teams defined once are
# usable across every project without copy-pasting the same definitions.
# Missing files at either layer are not an error -- a backlog with no
# participant references still runs fine, it just has no role framing.

teams_path_for() {
  local backlog_file="$1"
  echo "$(dirname "$backlog_file")/teams.json"
}

teams_global_path() {
  echo "${HOME}/.claude/loop-virtuoso/teams.json"
}

# teams_get_participant <backlog_file> <participant_id>
# Echoes the participant's definition, project layer first, then global.
# "null" if not found in either or the id is empty.
teams_get_participant() {
  local backlog_file="$1" participant_id="$2"
  [[ -n "$participant_id" ]] || { echo "null"; return 0; }
  local local_file global_file result
  local_file="$(teams_path_for "$backlog_file")"
  if [[ -f "$local_file" ]]; then
    result=$(jq -c --arg id "$participant_id" '.participants[$id] // null' "$local_file")
    [[ "$result" != "null" ]] && { echo "$result"; return 0; }
  fi
  global_file="$(teams_global_path)"
  if [[ -f "$global_file" ]]; then
    jq -c --arg id "$participant_id" '.participants[$id] // null' "$global_file"
    return 0
  fi
  echo "null"
}

# teams_get_team <backlog_file> <team_id>
# Echoes {"description":...,"members":[...]}, project layer first, then
# global. "null" if not found in either.
teams_get_team() {
  local backlog_file="$1" team_id="$2"
  [[ -n "$team_id" ]] || { echo "null"; return 0; }
  local local_file global_file result
  local_file="$(teams_path_for "$backlog_file")"
  if [[ -f "$local_file" ]]; then
    result=$(jq -c --arg id "$team_id" '.teams[$id] // null' "$local_file")
    [[ "$result" != "null" ]] && { echo "$result"; return 0; }
  fi
  global_file="$(teams_global_path)"
  if [[ -f "$global_file" ]]; then
    jq -c --arg id "$team_id" '.teams[$id] // null' "$global_file"
    return 0
  fi
  echo "null"
}

# teams_list_participants <backlog_file>
# Union of participant ids from both layers, deduplicated.
teams_list_participants() {
  local backlog_file="$1"
  _teams_union_keys "$(teams_path_for "$backlog_file")" "$(teams_global_path)" participants
}

# teams_list_teams <backlog_file>
# Union of team ids from both layers, deduplicated.
teams_list_teams() {
  local backlog_file="$1"
  _teams_union_keys "$(teams_path_for "$backlog_file")" "$(teams_global_path)" teams
}

# _teams_union_keys <local_file> <global_file> <object_key>
_teams_union_keys() {
  local local_file="$1" global_file="$2" object_key="$3"
  local local_keys="[]" global_keys="[]"
  [[ -f "$local_file" ]] && local_keys=$(jq -c --arg k "$object_key" '.[$k] // {} | keys' "$local_file" 2>/dev/null || echo "[]")
  [[ -f "$global_file" ]] && global_keys=$(jq -c --arg k "$object_key" '.[$k] // {} | keys' "$global_file" 2>/dev/null || echo "[]")
  jq -nc --argjson a "$local_keys" --argjson b "$global_keys" '($a + $b) | unique'
}

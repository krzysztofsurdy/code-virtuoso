#!/bin/bash
# Reads .delivery-loop/teams.json: named participants (delegate to an
# existing Claude Code subagent, or an inline custom persona) and named
# teams (an ordered group of participants used as a template when compiling
# a backlog). The engine only ever executes participants -- "teams" are a
# backlog-compiler-time convenience for composing steps, not something the
# engine itself needs to know about at run time.
#
# Missing teams.json is not an error: a backlog with no participant
# references on its steps still runs fine, it just has no role framing.

teams_path_for() {
  local backlog_file="$1"
  echo "$(dirname "$backlog_file")/teams.json"
}

# teams_get_participant <teams_file> <participant_id>
# Echoes the participant's definition, or "null" if not found / file missing.
teams_get_participant() {
  local teams_file="$1" participant_id="$2"
  [[ -n "$participant_id" && -f "$teams_file" ]] || { echo "null"; return 0; }
  jq -c --arg id "$participant_id" '.participants[$id] // null' "$teams_file"
}

# teams_get_team <teams_file> <team_id>
# Echoes {"description":...,"members":[...]}, or "null" if not found.
teams_get_team() {
  local teams_file="$1" team_id="$2"
  [[ -n "$team_id" && -f "$teams_file" ]] || { echo "null"; return 0; }
  jq -c --arg id "$team_id" '.teams[$id] // null' "$teams_file"
}

teams_list_participants() {
  local teams_file="$1"
  [[ -f "$teams_file" ]] || { echo "[]"; return 0; }
  jq -c '.participants // {} | keys' "$teams_file"
}

teams_list_teams() {
  local teams_file="$1"
  [[ -f "$teams_file" ]] || { echo "[]"; return 0; }
  jq -c '.teams // {} | keys' "$teams_file"
}

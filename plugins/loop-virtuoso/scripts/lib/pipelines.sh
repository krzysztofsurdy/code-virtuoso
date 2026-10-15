#!/bin/bash
# Named participants (delegate to an existing Claude Code subagent, or an
# inline custom persona) and named pipelines (an ordered group of participants
# used as a template when compiling a backlog). The engine only ever executes
# participants - "pipelines" are a backlog-compiler-time convenience for
# composing steps, not something the engine itself needs at run time.
#
# Two layers, project over user. The project file,
# <root>/.code-virtuoso/loop/pipelines.json (committed), is checked first;
# anything not defined there falls back to the user file,
# ${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json,
# so participants defined once are usable across every project. Missing files
# at either layer are not an error - a backlog with no participant references
# still runs fine, it just has no role framing.
#
# Agent participants name a Claude Code subagent. A bare name resolves to the
# scoped name agents-virtuoso:<name> when that plugin is installed and ships an
# agent with that name; a name that already has a scope is used as written.

PIPELINES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$PIPELINES_LIB_DIR/config.sh"

pipelines_path_for() {
  echo "$(dirname "$1")/pipelines.json"
}

pipelines_user_path() {
  echo "$(cv_config_home)/loop/pipelines.json"
}

# pipelines_resolve_agent <name>
# Echoes the agent name to use: <name> unchanged when it has a scope or no
# installed agents-virtuoso plugin ships it, else agents-virtuoso:<name>.
pipelines_resolve_agent() {
  local name="$1" registry install_path
  case "$name" in
    ""|*:*) echo "$name"; return 0 ;;
  esac
  registry="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
  if [[ -f "$registry" ]]; then
    while IFS= read -r install_path; do
      if [[ -n "$install_path" && -f "$install_path/agents/$name.md" ]]; then
        echo "agents-virtuoso:$name"
        return 0
      fi
    done < <(jq -r '.plugins | to_entries[] | select(.key | startswith("agents-virtuoso@")) | .value[]?.installPath // empty' "$registry" 2>/dev/null)
  fi
  echo "$name"
}

# pipelines_get_participant <backlog_file> <participant_id>
# Echoes the participant's definition, project layer first, then user, with an
# agent participant's name resolved. "null" if not found in either or the id is
# empty.
pipelines_get_participant() {
  local backlog_file="$1" participant_id="$2"
  [[ -n "$participant_id" ]] || { echo "null"; return 0; }
  local result="null" file agent resolved
  for file in "$(pipelines_path_for "$backlog_file")" "$(pipelines_user_path)"; do
    [[ -f "$file" ]] || continue
    result=$(jq -c --arg id "$participant_id" '.participants[$id] // null' "$file")
    [[ "$result" != "null" ]] && break
  done
  if [[ "$result" != "null" && "$(echo "$result" | jq -r '.kind // empty')" == "agent" ]]; then
    agent="$(echo "$result" | jq -r '.agent // empty')"
    resolved="$(pipelines_resolve_agent "$agent")"
    result=$(echo "$result" | jq -c --arg a "$resolved" 'if has("agent") then .agent = $a else . end')
  fi
  echo "$result"
}

# pipelines_get_pipeline <backlog_file> <pipeline_id>
# Echoes {"description":...,"members":[...]}, project layer first, then user.
# "null" if not found in either.
pipelines_get_pipeline() {
  local backlog_file="$1" pipeline_id="$2"
  [[ -n "$pipeline_id" ]] || { echo "null"; return 0; }
  local result="null" file
  for file in "$(pipelines_path_for "$backlog_file")" "$(pipelines_user_path)"; do
    [[ -f "$file" ]] || continue
    result=$(jq -c --arg id "$pipeline_id" '.pipelines[$id] // null' "$file")
    [[ "$result" != "null" ]] && break
  done
  echo "$result"
}

# pipelines_list_participants <backlog_file>
# Union of participant ids from both layers, deduplicated.
pipelines_list_participants() {
  _pipelines_union_keys "$(pipelines_path_for "$1")" "$(pipelines_user_path)" participants
}

# pipelines_list_pipelines <backlog_file>
# Union of pipeline ids from both layers, deduplicated.
pipelines_list_pipelines() {
  _pipelines_union_keys "$(pipelines_path_for "$1")" "$(pipelines_user_path)" pipelines
}

# _pipelines_union_keys <project_file> <user_file> <object_key>
_pipelines_union_keys() {
  local project_file="$1" user_file="$2" object_key="$3"
  local project_keys="[]" user_keys="[]"
  [[ -f "$project_file" ]] && project_keys=$(jq -c --arg k "$object_key" '.[$k] // {} | keys' "$project_file" 2>/dev/null || echo "[]")
  [[ -f "$user_file" ]] && user_keys=$(jq -c --arg k "$object_key" '.[$k] // {} | keys' "$user_file" 2>/dev/null || echo "[]")
  jq -nc --argjson a "$project_keys" --argjson b "$user_keys" '($a + $b) | unique'
}

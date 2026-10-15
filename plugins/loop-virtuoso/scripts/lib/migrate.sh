#!/bin/bash
# One-time migration from the earlier storage layout, run when a loop starts.
#
#   <root>/.delivery-loop/             -> <root>/.code-virtuoso/loop/
#     backlog.json (plan + state)       -> loop/backlog.json (plan), loop/state/state.json
#     teams.json                        -> loop/pipelines.json ("teams" key becomes "pipelines")
#     progress.log, events.jsonl        -> loop/state/
#     archive/                          -> loop/archive/
#     session.local.json                -> dropped (a stale session is never resumed)
#   ~/.claude/loop-virtuoso/teams.json -> <user config home>/loop/pipelines.json (copied)
#
# Nothing reads the old locations after this runs. Output goes to stdout so the
# start command relays it to the user.

MIGRATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$MIGRATE_LIB_DIR/config.sh"
# shellcheck source=./pipelines.sh
source "$MIGRATE_LIB_DIR/pipelines.sh"

_LEGACY_DIR_NAME=".delivery-loop"

_MIGRATE_SPLIT_STATE='{
  version: 1,
  items: (reduce .items[] as $it ({}; .[$it.id] = (reduce ($it.steps // [])[] as $st ({};
    .[$st.id] = {status: ($st.status // "pending"), attempts: ($st.attempts // 0), notes: ($st.notes // "")}))))
}'

_MIGRATE_STRIP_PLAN='.items |= map(.steps |= map(del(.status, .attempts, .notes)))'

# loop_remap_legacy_path <root> <path>
# A backlog path inside .delivery-loop maps to the same file name in the new loop directory.
loop_remap_legacy_path() {
  local root="$1" path="$2"
  case "$path" in
    "${_LEGACY_DIR_NAME}"/*|*/"${_LEGACY_DIR_NAME}"/*) echo "${root}/${CV_DIR_NAME}/loop/$(basename "$path")" ;;
    *) echo "$path" ;;
  esac
}

# _migrate_move <src> <dest> <label>: move unless dest exists; report either way.
_migrate_move() {
  local src="$1" dest="$2" label="$3"
  [[ -e "$src" ]] || return 0
  if [[ -e "$dest" ]]; then
    echo "loop-virtuoso: kept existing ${dest}; left ${src} in place"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$src" "$dest"
  echo "loop-virtuoso: moved ${label} -> ${dest}"
}

# loop_migrate_legacy <root>
# Returns 1 (with a message on stderr) when both layouts hold a backlog.
loop_migrate_legacy() {
  local root="$1" old new
  old="${root}/${_LEGACY_DIR_NAME}"
  new="${root}/${CV_DIR_NAME}/loop"
  [[ -d "$old" ]] || return 0

  if [[ -f "$old/backlog.json" && -f "$new/backlog.json" ]]; then
    echo "Error: both ${old}/backlog.json and ${new}/backlog.json exist. Remove or archive the one you do not want, then start again." >&2
    return 1
  fi

  echo "loop-virtuoso: migrating ${old} to ${new}"
  mkdir -p "$new/state"
  cv_ensure_gitignore "$root"

  if [[ -f "$old/backlog.json" ]]; then
    if ! jq empty "$old/backlog.json" >/dev/null 2>&1; then
      echo "Error: ${old}/backlog.json is not valid JSON; fix or remove it, then start again." >&2
      return 1
    fi
    [[ -f "$new/state/state.json" ]] || jq "$_MIGRATE_SPLIT_STATE" "$old/backlog.json" > "$new/state/state.json"
    jq "$_MIGRATE_STRIP_PLAN" "$old/backlog.json" > "$new/backlog.json"
    rm -f "$old/backlog.json"
    echo "loop-virtuoso: split backlog.json into the plan (${new}/backlog.json) and run state (${new}/state/state.json)"
  fi

  if [[ -f "$old/teams.json" ]]; then
    if [[ -f "$new/pipelines.json" ]]; then
      echo "loop-virtuoso: kept existing ${new}/pipelines.json; left ${old}/teams.json in place"
    else
      jq '.pipelines = (.teams // .pipelines // {}) | del(.teams)' "$old/teams.json" > "$new/pipelines.json"
      rm -f "$old/teams.json"
      echo "loop-virtuoso: moved teams.json -> ${new}/pipelines.json (\"teams\" is now \"pipelines\")"
    fi
  fi

  _migrate_move "$old/progress.log" "$new/state/progress.log" "progress.log"
  _migrate_move "$old/events.jsonl" "$new/state/events.jsonl" "events.jsonl"

  if [[ -f "$old/session.local.json" ]]; then
    rm -f "$old/session.local.json"
    echo "loop-virtuoso: dropped the old session file (a stale session is not resumed)"
  fi

  if [[ -d "$old/archive" ]]; then
    local entry
    for entry in "$old"/archive/*; do
      [[ -e "$entry" ]] && _migrate_move "$entry" "$new/archive/$(basename "$entry")" "archive/$(basename "$entry")"
    done
    rmdir "$old/archive" 2>/dev/null || true
  fi

  if rmdir "$old" 2>/dev/null; then
    echo "loop-virtuoso: removed the empty ${old}"
  else
    echo "loop-virtuoso: ${old} still holds files that were not migrated; review and delete it by hand"
  fi

  local exclude
  exclude="$(git -C "$root" rev-parse --git-path info/exclude 2>/dev/null || true)"
  [[ -n "$exclude" && "$exclude" != /* ]] && exclude="${root}/${exclude}"
  if [[ -n "$exclude" && -f "$exclude" ]] && grep -qE '^/?\.delivery-loop/?$' "$exclude"; then
    echo "loop-virtuoso: remove the .delivery-loop line from ${exclude}. The plan and archive under ${CV_DIR_NAME}/loop are meant to be committed; ${CV_DIR_NAME}/.gitignore keeps loop/state/ out of git."
  fi
}

# loop_migrate_user_pipelines
# Copies the old global teams file to the user pipelines path when the new one
# does not exist yet. The old file is left in place.
loop_migrate_user_pipelines() {
  local legacy="${HOME}/.claude/loop-virtuoso/teams.json" dest
  dest="$(pipelines_user_path)"
  [[ -f "$legacy" && ! -f "$dest" ]] || return 0
  if ! jq empty "$legacy" >/dev/null 2>&1; then
    echo "loop-virtuoso: ${legacy} is not valid JSON; not copied to ${dest}"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  jq '.pipelines = (.teams // .pipelines // {}) | del(.teams)' "$legacy" > "$dest"
  echo "loop-virtuoso: copied ${legacy} to ${dest} (\"teams\" is now \"pipelines\"). The old file can be deleted."
}

# loop_migrate_start <backlog-arg-or-empty>
# Runs both migrations for the repository the start command targets. Sets
# LOOP_BACKLOG_ARG to the argument with a legacy .delivery-loop path remapped.
# Returns 1 when the project migration cannot proceed.
loop_migrate_start() {
  local arg="${1:-}" probe="." root
  [[ -n "$arg" && -d "$(dirname "$arg")" ]] && probe="$(dirname "$arg")"
  root="$(git -C "$probe" rev-parse --show-toplevel 2>/dev/null || true)"
  LOOP_BACKLOG_ARG="$arg"
  if [[ -n "$root" ]]; then
    root="$(cd "$root" && pwd -P)"
    loop_migrate_legacy "$root" || return 1
    [[ -n "$arg" ]] && LOOP_BACKLOG_ARG="$(loop_remap_legacy_path "$root" "$arg")"
  fi
  loop_migrate_user_pipelines
}

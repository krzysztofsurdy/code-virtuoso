#!/bin/bash
# Cancel the active Mode A loop.
#   cancel.sh [dir-inside-the-repo]   (default: the current directory)
#
# Finds the session file at the git root, records a run_stopped event with
# reason "cancelled", removes the out-of-tree snapshots, and removes the
# session file. The plan and the run state are left untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/verify-gate.sh
source "${SCRIPT_DIR}/lib/verify-gate.sh"
# shellcheck source=lib/preflight.sh
source "${SCRIPT_DIR}/lib/preflight.sh"

start_dir="${1:-.}"
repo_root="$(loop_repo_root "$start_dir")"
state_file=""
[[ -n "$repo_root" ]] && state_file="$(loop_session_file "$repo_root")"

if [[ -z "$state_file" || ! -f "$state_file" ]]; then
  echo "No active loop."
  exit 0
fi

iteration="$(jq -r '.iteration // "?"' "$state_file" 2>/dev/null || echo "?")"
backlog_file="$(jq -r '.backlogFile // empty' "$state_file" 2>/dev/null || true)"
case "$backlog_file" in
  "") ;;
  /*) ;;
  *) backlog_file="${repo_root}/${backlog_file}" ;;
esac

if [[ -n "$backlog_file" && -f "$backlog_file" ]]; then
  events_emit "$backlog_file" "run_stopped" '{"reason":"cancelled"}'
  progress_append "$backlog_file" "stop reason=cancelled"
  verify_gate_snapshot_cleanup "$backlog_file"
fi
rm -f "$state_file"

echo "Cancelled at iteration ${iteration}. Run state preserved. Run /loop-virtuoso:start to resume."

#!/bin/bash
# Archive a run so the next backlog starts clean.
#   archive-run.sh <path-to-backlog.json> [new-branch]
#
# Run by the backlog-compiler skill before it writes a new backlog; also safe
# to run by hand. It is NOT called at run start: starting a run never moves
# the backlog it is about to execute.
#
# An archive is made when the run has a progress.log with more than a header's
# worth of lines (so something actually ran) and either:
#   - no item is pending (the run finished), or
#   - [new-branch] is given and differs from the backlog's own branch (the old
#     run is being abandoned for different work).
# Anything else is an in-progress run and is left alone.
#
# backlog.json, progress.log and events.jsonl are run state: they move into
# archive/<date>-<branch-slug>/. teams.json is configuration shared by later
# runs: it is copied, never moved.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/backlog.sh
source "${SCRIPT_DIR}/lib/backlog.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: archive-run.sh <path-to-backlog.json> [new-branch]" >&2
  exit 1
fi

file="$1"
new_branch="${2:-}"

# Fresh project, nothing to archive.
if [[ ! -f "$file" ]]; then
  exit 0
fi

if ! jq empty "$file" >/dev/null 2>&1; then
  echo "archive-run: backlog at $file is not valid JSON; leaving it alone." >&2
  exit 1
fi

dir="$(cd "$(dirname "$file")" && pwd)"
progress_log="${dir}/progress.log"
teams_file="${dir}/teams.json"
events_file="${dir}/events.jsonl"
archive_root="${dir}/archive"

branch="$(jq -r '.branch // "run"' "$file")"
counts="$(backlog_counts "$file")"
pending="$(echo "$counts" | jq -r '.pending')"

finished=0
[[ "$pending" -eq 0 ]] && finished=1
branch_changed=0
[[ -n "$new_branch" && "$new_branch" != "$branch" ]] && branch_changed=1

if [[ "$finished" -eq 0 && "$branch_changed" -eq 0 ]]; then
  echo "archive-run: backlog has $pending pending item(s) and the branch is unchanged; in-progress run left alone."
  exit 0
fi

# A run only counts if progress.log has more than a header's worth of lines.
if [[ ! -f "$progress_log" ]]; then
  echo "archive-run: no progress.log present; nothing to archive."
  exit 0
fi

log_lines="$(grep -c '' "$progress_log" 2>/dev/null || echo 0)"
if [[ "$log_lines" -le 2 ]]; then
  echo "archive-run: progress.log has only a header ($log_lines line(s)); nothing to archive."
  exit 0
fi

date_stamp="$(date -u +%Y-%m-%d)"

# lowercase, non-alphanumerics -> '-', collapse and trim.
slug="$(echo "$branch" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-*//' -e 's/-*$//')"
[[ -z "$slug" ]] && slug="run"

target="${archive_root}/${date_stamp}-${slug}"

# Same branch archived twice in one day: suffix instead of clobbering.
if [[ -e "$target" ]]; then
  n=2
  while [[ -e "${target}-${n}" ]]; do
    n=$((n + 1))
  done
  target="${target}-${n}"
fi

mkdir -p "$target"
mv "$file" "${target}/$(basename "$file")"
mv "$progress_log" "${target}/$(basename "$progress_log")"
[[ -f "$events_file" ]] && mv "$events_file" "${target}/$(basename "$events_file")"
[[ -f "$teams_file" ]] && cp "$teams_file" "${target}/$(basename "$teams_file")"

echo "archive-run: archived run to ${target}/ (teams.json copied, not moved)"

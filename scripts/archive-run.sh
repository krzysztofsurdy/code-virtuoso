#!/bin/bash
# Archive a finished run so the next backlog-compiler starts clean.
# Called at run start by setup-start.sh (Mode A) and run-batch.sh (Mode B);
# runs standalone and no-ops when there's nothing to archive.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/backlog.sh
source "${SCRIPT_DIR}/lib/backlog.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: archive-run.sh <path-to-backlog.json>" >&2
  exit 1
fi

file="$1"

# Fresh project -- nothing to archive.
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

# Pending items remain -- run still in progress, never archive.
counts="$(backlog_counts "$file")"
pending="$(echo "$counts" | jq -r '.pending')"
if [[ "$pending" -gt 0 ]]; then
  echo "archive-run: backlog has $pending pending item(s); in-progress run left alone."
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

branch="$(jq -r '.branch // "run"' "$file")"
date_stamp="$(date -u +%Y-%m-%d)"

# lowercase, non-alphanumerics -> '-', collapse and trim.
slug="$(echo "$branch" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-*//' -e 's/-*$//')"
[[ -z "$slug" ]] && slug="run"

target="${archive_root}/${date_stamp}-${slug}"

# Same branch archived twice in one day -- suffix instead of clobbering.
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
# Companion files are optional -- archive whichever exist.
[[ -f "$teams_file" ]] && mv "$teams_file" "${target}/$(basename "$teams_file")"
[[ -f "$events_file" ]] && mv "$events_file" "${target}/$(basename "$events_file")"

echo "archive-run: archived finished run to ${target}/"

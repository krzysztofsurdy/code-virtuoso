#!/bin/bash
# Structured, append-only event log: <backlog-dir>/events.jsonl, one JSON
# object per line. backlog.sh's mutators call this so nothing changes state
# without being recorded -- this is what "full visibility" means here: tail
# or jq the file directly, don't rely on a summary.

events_path_for() {
  local backlog_file="$1"
  echo "$(dirname "$backlog_file")/events.jsonl"
}

# events_emit <backlog_file> <event_type> [extra_fields_json_object]
# extra_fields_json_object is a JSON object string, e.g. '{"itemId":"ITEM-001"}'.
events_emit() {
  local backlog_file="$1" event_type="$2" extra_json="${3:-{\}}"
  local events_file
  events_file=$(events_path_for "$backlog_file")
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg event "$event_type" --argjson extra "$extra_json" \
    '{ts: $ts, event: $event} + $extra' >> "$events_file"
}

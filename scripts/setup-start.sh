#!/bin/bash
# Mode A (session-supervised) bootstrap.
#
# Called by /loop-virtuoso:start with the backlog path as $1. Validates,
# archives any prior run, seeds session.local.json on the first pending step,
# prints that step's prompt. The Stop hook drives every iteration after this.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKLOG_PATH="${1:-.delivery-loop/backlog.json}"

if [[ ! -f "$BACKLOG_PATH" ]]; then
  echo "Error: backlog file not found: $BACKLOG_PATH" >&2
  exit 1
fi

# Hard gate when present. May not exist yet (parallel work) -- skip + warn.
if [[ -f "${SCRIPT_DIR}/validate-backlog.sh" ]]; then
  bash "${SCRIPT_DIR}/validate-backlog.sh" "$BACKLOG_PATH" || {
    echo "Error: backlog validation failed" >&2
    exit 1
  }
else
  echo "Warning: validate-backlog.sh not found, skipping validation" >&2
fi

# Best-effort: tolerate a missing script or a non-fatal failure.
if [[ -f "${SCRIPT_DIR}/archive-run.sh" ]]; then
  bash "${SCRIPT_DIR}/archive-run.sh" "$BACKLOG_PATH" || \
    echo "Warning: archive-run.sh exited non-zero, continuing" >&2
fi

# shellcheck source=./lib/backlog.sh
source "${SCRIPT_DIR}/lib/backlog.sh"
# shellcheck source=./lib/verify-gate.sh
source "${SCRIPT_DIR}/lib/verify-gate.sh"
# shellcheck source=./lib/teams.sh
source "${SCRIPT_DIR}/lib/teams.sh"

# Commit any pre-existing untracked cruft before the first start_sha, so
# iteration 1's diff is only the worker's work -- closes a false-violation edge.
verify_gate_initial_checkpoint "$BACKLOG_PATH"
events_emit "$BACKLOG_PATH" "run_started" '{}'

FIRST=$(backlog_next_pending_step "$BACKLOG_PATH")
if [[ -z "$FIRST" ]]; then
  echo "Backlog has no runnable steps" >&2
  exit 1
fi

FIRST_ITEM_ID=$(echo "$FIRST" | jq -r '.itemId')
FIRST_STEP=$(echo "$FIRST" | jq -c '.step')
FIRST_STEP_ID=$(echo "$FIRST_STEP" | jq -r '.id')
FIRST_ITEM_JSON=$(backlog_get_item "$BACKLOG_PATH" "$FIRST_ITEM_ID")

PARTICIPANT_ID=$(echo "$FIRST_STEP" | jq -r '.participant // empty')
PARTICIPANT_JSON=$(teams_get_participant "$(teams_path_for "$BACKLOG_PATH")" "$PARTICIPANT_ID")

BACKLOG_DIR=$(dirname "$BACKLOG_PATH")
REPO_DIR=$(git -C "$BACKLOG_DIR" rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "$REPO_DIR" ]] && REPO_DIR=$(cd "$BACKLOG_DIR/.." && pwd)

START_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)
if [[ -z "$START_SHA" ]]; then
  # No commits/not a repo: diff against the empty tree so the gate sees every
  # file as new instead of erroring on a missing ref.
  START_SHA="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
fi

STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

STATE_FILE="${BACKLOG_DIR}/session.local.json"
STATE_TMP="${STATE_FILE}.tmp.$$"

jq -n \
  --arg backlogFile "$BACKLOG_PATH" \
  --arg sessionId "${CLAUDE_CODE_SESSION_ID:-}" \
  --arg currentItemId "$FIRST_ITEM_ID" \
  --arg currentStepId "$FIRST_STEP_ID" \
  --arg startSha "$START_SHA" \
  --arg startedAt "$STARTED_AT" \
  '{
    active: true,
    sessionId: $sessionId,
    backlogFile: $backlogFile,
    iteration: 1,
    currentItemId: $currentItemId,
    currentStepId: $currentStepId,
    startSha: $startSha,
    stallCount: 0,
    violationCount: 0,
    startedAt: $startedAt
  }' > "$STATE_TMP"
mv "$STATE_TMP" "$STATE_FILE"

# Snapshot right before the worker sees the prompt -- verify_gate_run compares
# against this to detect (and undo) any edit to the backlog's own content
# during the step, regardless of which tool made it.
verify_gate_snapshot_all "$BACKLOG_PATH"

backlog_build_step_prompt "$FIRST_ITEM_JSON" "$FIRST_STEP" "$PARTICIPANT_JSON"

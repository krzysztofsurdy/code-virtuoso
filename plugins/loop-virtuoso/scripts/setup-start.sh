#!/bin/bash
# Mode A (session-supervised) bootstrap.
#
# Called by /loop-virtuoso:start with the backlog path as $1. Migrates the old
# .delivery-loop layout if one exists, runs the preflight (validation, clean
# tree, branch guard), seeds the session file on the first pending step, and
# prints that step's prompt. The Stop hook drives every iteration after this.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/backlog.sh
source "${SCRIPT_DIR}/lib/backlog.sh"
# shellcheck source=./lib/verify-gate.sh
source "${SCRIPT_DIR}/lib/verify-gate.sh"
# shellcheck source=./lib/pipelines.sh
source "${SCRIPT_DIR}/lib/pipelines.sh"
# shellcheck source=./lib/preflight.sh
source "${SCRIPT_DIR}/lib/preflight.sh"
# shellcheck source=./lib/migrate.sh
source "${SCRIPT_DIR}/lib/migrate.sh"

if [[ -z "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
  echo "Error: no session id available (CLAUDE_CODE_SESSION_ID is empty); the loop cannot bind to this session" >&2
  exit 1
fi

loop_migrate_start "${1:-}" || exit 1
BACKLOG_PATH="${LOOP_BACKLOG_ARG:-$(loop_default_backlog .)}"

loop_preflight "$BACKLOG_PATH"
BACKLOG_PATH="$LOOP_BACKLOG_ABS"
REPO_DIR="$LOOP_REPO_ROOT"
cv_ensure_gitignore "$REPO_DIR"

FIRST=$(backlog_next_pending_step "$BACKLOG_PATH")
if [[ -z "$FIRST" ]]; then
  echo "Backlog has no runnable steps. If the run is finished, archive it with scripts/archive-run.sh and compile a new backlog." >&2
  exit 1
fi

events_emit "$BACKLOG_PATH" "run_started" '{}'
progress_run_start "$BACKLOG_PATH" "$REPO_DIR"

FIRST_ITEM_ID=$(echo "$FIRST" | jq -r '.itemId')
FIRST_STEP=$(echo "$FIRST" | jq -c '.step')
FIRST_STEP_ID=$(echo "$FIRST_STEP" | jq -r '.id')
FIRST_ITEM_JSON=$(backlog_get_item "$BACKLOG_PATH" "$FIRST_ITEM_ID")

PARTICIPANT_ID=$(echo "$FIRST_STEP" | jq -r '.participant // empty')
PARTICIPANT_JSON=$(pipelines_get_participant "$BACKLOG_PATH" "$PARTICIPANT_ID")
PARTICIPANT_KIND=$(echo "$PARTICIPANT_JSON" | jq -r '.kind // empty')

START_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || true)
if [[ -z "$START_SHA" ]]; then
  # No commits yet: diff against the empty tree so the gate sees every
  # file as new instead of erroring on a missing ref.
  START_SHA="4b825dc642cb6eb9a060e54bf8d69288fbee4904"
fi

STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# The session file always lives at <git root>/.code-virtuoso/loop/state, where
# the hooks look for it regardless of the session's working directory.
STATE_FILE="$(loop_session_file "$REPO_DIR")"
mkdir -p "$(dirname "$STATE_FILE")"
STATE_TMP="${STATE_FILE}.tmp.$$"

jq -n \
  --arg backlogFile "$BACKLOG_PATH" \
  --arg sessionId "$CLAUDE_CODE_SESSION_ID" \
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

progress_iteration_started "$BACKLOG_PATH" 1 "$FIRST_ITEM_ID" "$FIRST_STEP_ID" "$PARTICIPANT_ID" "$PARTICIPANT_KIND"

# Snapshot right before the worker sees the prompt. verify_gate_run compares
# against this to detect (and undo) any edit to the backlog's own content
# during the step, regardless of which tool made it.
verify_gate_snapshot_all "$BACKLOG_PATH"

backlog_build_step_prompt "$FIRST_ITEM_JSON" "$FIRST_STEP" "$PARTICIPANT_JSON"

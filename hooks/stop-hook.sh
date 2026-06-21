#!/bin/bash
# Mode A (session-supervised) loop engine -- the Stop hook.
#
# Fires when the session would end. If a loop is active here and owned by this
# session, runs the verify gate on the current step, applies the verdict, then
# either stops with a summary or feeds the next step's prompt back.
#
# Completion is never self-reported: only verify-gate.sh decides pass/fail,
# only lib/backlog.sh writes the backlog.
set -euo pipefail

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')

STATE_FILE="$CWD/.delivery-loop/session.local.json"

# No active loop in this project -> zero effect on a normal session.
[[ -f "$STATE_FILE" ]] || exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/verify-gate.sh
source "$HOOK_DIR/../scripts/lib/verify-gate.sh"
# shellcheck source=../scripts/lib/teams.sh
source "$HOOK_DIR/../scripts/lib/teams.sh"

SESSION_ID=$(jq -r '.sessionId // ""' "$STATE_FILE" 2>/dev/null || echo "")
ITERATION=$(jq -r '.iteration // ""' "$STATE_FILE" 2>/dev/null || echo "")
BACKLOG_FILE=$(jq -r '.backlogFile // ""' "$STATE_FILE" 2>/dev/null || echo "")
CURRENT_ITEM_ID=$(jq -r '.currentItemId // ""' "$STATE_FILE" 2>/dev/null || echo "")
CURRENT_STEP_ID=$(jq -r '.currentStepId // ""' "$STATE_FILE" 2>/dev/null || echo "")
START_SHA=$(jq -r '.startSha // ""' "$STATE_FILE" 2>/dev/null || echo "")
STALL_COUNT=$(jq -r '.stallCount // 0' "$STATE_FILE" 2>/dev/null || echo "0")
VIOLATION_COUNT=$(jq -r '.violationCount // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# State is project-scoped but the Stop hook fires in every session here.
# Bound + non-matching session: skip. Empty sessionId: claim it.
if [[ -n "$SESSION_ID" && "$SESSION_ID" != "$HOOK_SESSION" ]]; then
  exit 0
fi
[[ -z "$SESSION_ID" ]] && SESSION_ID="$HOOK_SESSION"

# Missing/insane core field: can't drive the loop. Drop state, end session.
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]] || [[ -z "$BACKLOG_FILE" ]] || \
   [[ -z "$CURRENT_ITEM_ID" ]] || [[ -z "$CURRENT_STEP_ID" ]] || [[ -z "$START_SHA" ]]; then
  echo "loop-virtuoso: session state corrupted (stop reason: corrupted) -- removing $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi
[[ "$STALL_COUNT" =~ ^[0-9]+$ ]] || STALL_COUNT=0
[[ "$VIOLATION_COUNT" =~ ^[0-9]+$ ]] || VIOLATION_COUNT=0

# Resolve a relative backlog path against cwd so helpers work regardless of
# process cwd.
case "$BACKLOG_FILE" in
  /*) BACKLOG_ABS="$BACKLOG_FILE" ;;
  *)  BACKLOG_ABS="$CWD/$BACKLOG_FILE" ;;
esac
if [[ ! -f "$BACKLOG_ABS" ]]; then
  echo "loop-virtuoso: backlog file missing (stop reason: corrupted) -- removing $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Loop bounds; fall back to defaults if a config key is unset.
MAX_ITERATIONS=$(backlog_get_config "$BACKLOG_ABS" "maxIterations"); MAX_ITERATIONS=${MAX_ITERATIONS:-30}
MAX_ATTEMPTS=$(backlog_get_config "$BACKLOG_ABS" "maxAttemptsPerItem"); MAX_ATTEMPTS=${MAX_ATTEMPTS:-3}
MAX_STALL=$(backlog_get_config "$BACKLOG_ABS" "maxStallIterations"); MAX_STALL=${MAX_STALL:-3}
MAX_VIOLATIONS=$(backlog_get_config "$BACKLOG_ABS" "maxViolations"); MAX_VIOLATIONS=${MAX_VIOLATIONS:-3}

# Gate the current step, then apply the verdict through the single write point.
# step_apply_verdict echoes the resolved action; the loop branches on that.
VERDICT_JSON=$(verify_gate_run "$BACKLOG_ABS" "$CURRENT_ITEM_ID" "$CURRENT_STEP_ID" "$START_SHA")
ACTION=$(step_apply_verdict "$BACKLOG_ABS" "$CURRENT_ITEM_ID" "$CURRENT_STEP_ID" "$VERDICT_JSON" "$MAX_ATTEMPTS" | jq -r '.action')

case "$ACTION" in
  verified|failed|blocked)
    # Real diff (pass, or fail that may have hit the attempt cap): not a stall.
    STALL_COUNT=0
    ;;
  violation)
    # Not a legitimate attempt; status/attempts untouched by step_apply_verdict.
    # Always has a diff (gate checks stall first), so reset the stall streak.
    VIOLATION_COUNT=$(( VIOLATION_COUNT + 1 ))
    STALL_COUNT=0
    ;;
  stall)
    STALL_COUNT=$(( STALL_COUNT + 1 ))
    ;;
  *)
    echo "loop-virtuoso: unexpected verdict action '$ACTION' (stop reason: corrupted) -- removing $STATE_FILE" >&2
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac

NEXT=$(backlog_next_pending_step "$BACKLOG_ABS")
COUNTS=$(backlog_counts "$BACKLOG_ABS")
BLOCKED=$(echo "$COUNTS" | jq -r '.blocked')

stop_loop() {
  # $1 = stop reason. Caller already printed the human summary; record the
  # run-level transition (step/item events come from step_apply_verdict).
  events_emit "$BACKLOG_ABS" "run_stopped" "$(jq -nc --arg reason "$1" '{reason: $reason}')"
  rm -f "$STATE_FILE"
  exit 0
}

# Stop conditions, in priority order. First match ends the loop.
if (( VIOLATION_COUNT >= MAX_VIOLATIONS )); then
  echo "loop-virtuoso stopped (reason: violation_limit). Hit $VIOLATION_COUNT protected-path violations (limit $MAX_VIOLATIONS). The worker repeatedly tried to change off-limits files; nothing further was applied."
  stop_loop violation_limit
fi

if (( STALL_COUNT >= MAX_STALL )); then
  echo "loop-virtuoso stopped (reason: stalled). $STALL_COUNT consecutive iterations produced no diff (limit $MAX_STALL). Step $CURRENT_ITEM_ID/$CURRENT_STEP_ID was not advanced."
  stop_loop stalled
fi

if [[ -z "$NEXT" ]] && (( BLOCKED > 0 )); then
  echo "loop-virtuoso stopped (reason: blocked_out). No runnable steps remain and $BLOCKED item(s) are blocked:"
  backlog_blocked_items_report "$BACKLOG_ABS" | jq -r '.[] | "  - \(.itemId)/\(.stepId) (\(.itemTitle))\n      \(.notes)"'
  echo "Summary: $(echo "$COUNTS" | jq -r '"\(.verified)/\(.total) items verified, \(.blocked) blocked, \(.pending) pending"')"
  stop_loop blocked_out
fi

if [[ -z "$NEXT" ]]; then
  echo "loop-virtuoso stopped (reason: complete). All items verified: $(echo "$COUNTS" | jq -r '"\(.verified)/\(.total)"')."
  stop_loop complete
fi

if (( ITERATION + 1 > MAX_ITERATIONS )); then
  echo "loop-virtuoso stopped (reason: max_iterations). Reached the $MAX_ITERATIONS-iteration cap with work still pending."
  echo "Summary: $(echo "$COUNTS" | jq -r '"\(.verified)/\(.total) items verified, \(.blocked) blocked, \(.pending) pending"')"
  stop_loop max_iterations
fi

# Continue: advance to the next pending step and feed its prompt back.
NEXT_ITEM_ID=$(echo "$NEXT" | jq -r '.itemId')
NEXT_STEP=$(echo "$NEXT" | jq -c '.step')
NEXT_STEP_ID=$(echo "$NEXT_STEP" | jq -r '.id')
NEXT_ITEM_JSON=$(backlog_get_item "$BACKLOG_ABS" "$NEXT_ITEM_ID")

# Resolve the step's participant (if any) from teams.json for role framing.
PARTICIPANT_ID=$(echo "$NEXT_STEP" | jq -r '.participant // empty')
PARTICIPANT_JSON=$(teams_get_participant "$(teams_path_for "$BACKLOG_ABS")" "$PARTICIPANT_ID")

NEXT_ITERATION=$(( ITERATION + 1 ))
NEXT_START_SHA=$(git -C "$CWD" rev-parse HEAD 2>/dev/null || true)
[[ -z "$NEXT_START_SHA" ]] && NEXT_START_SHA="4b825dc642cb6eb9a060e54bf8d69288fbee4904"

STATE_TMP="${STATE_FILE}.tmp.$$"
jq -n \
  --arg sessionId "$SESSION_ID" \
  --arg backlogFile "$BACKLOG_FILE" \
  --argjson iteration "$NEXT_ITERATION" \
  --arg currentItemId "$NEXT_ITEM_ID" \
  --arg currentStepId "$NEXT_STEP_ID" \
  --arg startSha "$NEXT_START_SHA" \
  --argjson stallCount "$STALL_COUNT" \
  --argjson violationCount "$VIOLATION_COUNT" \
  --arg startedAt "$(jq -r '.startedAt // ""' "$STATE_FILE")" \
  '{
    active: true,
    sessionId: $sessionId,
    backlogFile: $backlogFile,
    iteration: $iteration,
    currentItemId: $currentItemId,
    currentStepId: $currentStepId,
    startSha: $startSha,
    stallCount: $stallCount,
    violationCount: $violationCount,
    startedAt: $startedAt
  }' > "$STATE_TMP"
mv "$STATE_TMP" "$STATE_FILE"

# Snapshot right before the worker sees the next prompt -- taken after
# step_apply_verdict's own write above, so that legitimate update is part of
# the trusted baseline the next verify_gate_run call compares against.
verify_gate_snapshot_all "$BACKLOG_ABS"

PROMPT=$(backlog_build_step_prompt "$NEXT_ITEM_JSON" "$NEXT_STEP" "$PARTICIPANT_JSON")

jq -n \
  --arg reason "$PROMPT" \
  --arg msg "Iteration $NEXT_ITERATION -- $NEXT_ITEM_ID/$NEXT_STEP_ID" \
  '{decision: "block", reason: $reason, systemMessage: $msg}'

exit 0

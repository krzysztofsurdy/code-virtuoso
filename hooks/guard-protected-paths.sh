#!/bin/bash
# PreToolUse hook -- layer 1 of the write-boundary guard.
#
# Denies Edit/Write calls aimed at a protected path before the edit happens.
# No-ops if no loop session is active, so it has zero effect otherwise.
set -euo pipefail

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')
STATE_FILE="$CWD/.delivery-loop/session.local.json"

[[ -f "$STATE_FILE" ]] || exit 0

# BACKLOG_FILE in state is typically relative -- resolve it against $CWD
# before testing it, not the hook process's own (unrelated) cwd.
BACKLOG_FILE_RAW=$(jq -r '.backlogFile // empty' "$STATE_FILE" 2>/dev/null || echo "")
[[ -n "$BACKLOG_FILE_RAW" ]] || exit 0
case "$BACKLOG_FILE_RAW" in
  /*) BACKLOG_FILE="$BACKLOG_FILE_RAW" ;;
  *)  BACKLOG_FILE="$CWD/$BACKLOG_FILE_RAW" ;;
esac
[[ -f "$BACKLOG_FILE" ]] || exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/backlog.sh
source "$HOOK_DIR/../scripts/lib/backlog.sh"

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" ]] || exit 0

FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
[[ -n "$FILE_PATH" ]] || exit 0

# Resolve both sides through the same physical-path normalization before
# comparing. Comparing raw strings broke whenever Claude Code resolved one of
# cwd/file_path through a symlink (e.g. macOS /tmp -> /private/tmp) and not
# the other -- it doesn't matter which one, both land on the same form here.
CWD_RESOLVED="$(cd "$CWD" 2>/dev/null && pwd -P || echo "$CWD")"
FILE_DIR_RESOLVED="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd -P || dirname "$FILE_PATH")"
FILE_PATH_RESOLVED="$FILE_DIR_RESOLVED/$(basename "$FILE_PATH")"

REL_PATH="$FILE_PATH_RESOLVED"
case "$FILE_PATH_RESOLVED" in
  "$CWD_RESOLVED"/*) REL_PATH="${FILE_PATH_RESOLVED#"$CWD_RESOLVED"/}" ;;
esac

PROTECTED_JSON=$(backlog_protected_paths "$BACKLOG_FILE")

if backlog_path_is_protected "$REL_PATH" "$PROTECTED_JSON"; then
  jq -n --arg reason "Protected verification path for the active loop: $REL_PATH. The worker may not modify test, CI, or grading files -- this is enforced structurally, not by instruction." '
    {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }
  '
fi

exit 0

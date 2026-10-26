#!/bin/bash
# PreToolUse hook - layer 1 of the write-boundary guard.
#
# Denies Edit/Write/NotebookEdit calls aimed at a protected path before the edit happens.
# No-ops if no loop session is active, so it has zero effect otherwise.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/preflight.sh
source "$HOOK_DIR/../scripts/lib/preflight.sh"
# shellcheck source=../scripts/lib/backlog.sh
source "$HOOK_DIR/../scripts/lib/backlog.sh"

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')

# The session file lives at the git root, whatever directory the session is in.
REPO_ROOT="$(loop_repo_root "$CWD")"
[[ -n "$REPO_ROOT" ]] || exit 0
STATE_FILE="$(loop_session_file "$REPO_ROOT")"
[[ -f "$STATE_FILE" ]] || exit 0

# BACKLOG_FILE in state is absolute; resolve a relative one against the git root.
BACKLOG_FILE_RAW=$(jq -r '.backlogFile // empty' "$STATE_FILE" 2>/dev/null || echo "")
[[ -n "$BACKLOG_FILE_RAW" ]] || exit 0
case "$BACKLOG_FILE_RAW" in
  /*) BACKLOG_FILE="$BACKLOG_FILE_RAW" ;;
  *)  BACKLOG_FILE="$REPO_ROOT/$BACKLOG_FILE_RAW" ;;
esac
[[ -f "$BACKLOG_FILE" ]] || exit 0

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
[[ "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "NotebookEdit" ]] || exit 0

# NotebookEdit carries notebook_path instead of file_path.
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[[ -n "$FILE_PATH" ]] || exit 0

# protectedPaths globs are relative to the project root (the git root that holds
# .code-virtuoso).
REL_PATH="$(paths_relative_to "$(cv_root_for "$BACKLOG_FILE")" "$FILE_PATH")"

PROTECTED_JSON=$(backlog_protected_paths "$BACKLOG_FILE")

if paths_match_any "$REL_PATH" "$PROTECTED_JSON"; then
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

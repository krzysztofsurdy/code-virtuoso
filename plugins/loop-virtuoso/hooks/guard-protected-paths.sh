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

# _guard_resolve_path <path>
# Resolves the longest EXISTING prefix of <path> via `pwd -P`, re-appending
# whatever trailing segments don't exist yet unresolved - a path that isn't
# there yet can't itself be a symlink, so there's nothing to resolve in it.
# A brand-new file inside a not-yet-created directory (e.g. Write creating
# the first file under a fresh tests/ dir) used to fall straight back to the
# fully-unresolved path when `cd` failed outright, which broke the
# comparison below whenever an ancestor ABOVE the missing directory was
# itself a symlink (macOS's /tmp -> /private/tmp, the same case already
# handled for existing paths) - walking up to the nearest real ancestor
# closes that gap for missing paths too.
_guard_resolve_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" 2>/dev/null && pwd -P) || echo "$path"
    return
  fi
  local dir base suffix=""
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  while [[ ! -d "$dir" && "$dir" != "/" ]]; do
    suffix="$(basename "$dir")/${suffix}"
    dir="$(dirname "$dir")"
  done
  local resolved_dir
  resolved_dir="$(cd "$dir" 2>/dev/null && pwd -P || echo "$dir")"
  echo "${resolved_dir}/${suffix}${base}"
}

# protectedPaths globs are relative to the project directory, the parent of
# the loop directory. Resolve both sides through the same normalization before
# comparing: comparing raw strings broke whenever Claude Code resolved one of
# them through a symlink and not the other.
PROJECT_RESOLVED="$(_guard_resolve_path "$(dirname "$(dirname "$BACKLOG_FILE")")")"
FILE_PATH_RESOLVED="$(_guard_resolve_path "$FILE_PATH")"

REL_PATH="$FILE_PATH_RESOLVED"
case "$FILE_PATH_RESOLVED" in
  "$PROJECT_RESOLVED"/*) REL_PATH="${FILE_PATH_RESOLVED#"$PROJECT_RESOLVED"/}" ;;
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

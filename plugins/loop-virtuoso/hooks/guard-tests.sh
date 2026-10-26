#!/bin/bash
# PreToolUse hook - opt-in test-file guard outside a loop (loop.guard.protectTests).
#
# Asks for confirmation ("ask") or refuses ("deny") an Edit/Write/MultiEdit/
# NotebookEdit call on a file that matches loop.guard.testGlobs and already
# exists in HEAD. New test files are always allowed. Exits 0 silently when
# protectTests is unset or false, outside a git repository, and while a loop
# session is active: guard-protected-paths.sh and verify-gate.sh own that case.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/preflight.sh
source "$HOOK_DIR/../scripts/lib/preflight.sh"
# shellcheck source=../scripts/lib/paths.sh
source "$HOOK_DIR/../scripts/lib/paths.sh"

DEFAULT_TEST_GLOBS='["tests/**","**/*Test.php","**/*_test.*","**/*.spec.*","**/test_*.py"]'

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')

TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
case "$TOOL_NAME" in
  Edit | Write | MultiEdit | NotebookEdit) ;;
  *) exit 0 ;;
esac

REPO_ROOT="$(loop_repo_root "$CWD")"
[[ -n "$REPO_ROOT" ]] || exit 0
if [[ -f "$(loop_session_file "$REPO_ROOT")" ]]; then exit 0; fi

MODE=$(cv_guard_setting "$REPO_ROOT" protectTests | jq -r '. // empty')
[[ "$MODE" == "ask" || "$MODE" == "deny" ]] || exit 0

FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
[[ -n "$FILE_PATH" ]] || exit 0
case "$FILE_PATH" in
  /*) ;;
  *) FILE_PATH="$CWD/$FILE_PATH" ;;
esac

REL_PATH="$(paths_relative_to "$REPO_ROOT" "$FILE_PATH")"
[[ "$REL_PATH" != /* ]] || exit 0

# A leading "**/" also matches at the root, so "**/*Test.php" covers FooTest.php.
GLOBS=$(cv_guard_setting "$REPO_ROOT" testGlobs)
[[ "$(echo "${GLOBS:-null}" | jq -r 'type')" == "array" ]] || GLOBS="$DEFAULT_TEST_GLOBS"
GLOBS=$(echo "$GLOBS" | jq -c '. + [.[] | strings | select(startswith("**/")) | ltrimstr("**/")]')

paths_match_any "$REL_PATH" "$GLOBS" || exit 0
git -C "$REPO_ROOT" cat-file -e "HEAD:$REL_PATH" 2>/dev/null || exit 0

jq -n --arg decision "$MODE" --arg reason "$REL_PATH is a committed test file (loop.guard.protectTests). Fix the code under test instead of the test; change the test only if the user agrees the test itself is wrong." '
  {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $decision,
      permissionDecisionReason: $reason
    }
  }
'

exit 0

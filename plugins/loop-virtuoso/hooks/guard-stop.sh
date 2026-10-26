#!/bin/bash
# Stop hook - opt-in quality gate outside a loop (loop.guard.stopGate).
#
# When the session would end with uncommitted changes, runs the project's
# ticket-delivery.commands lint, staticAnalysis and test (those that are set,
# in that order) from the git root. The first failure blocks the stop with the
# command and the last 40 lines of its output; all passing prints nothing.
#
# Exits 0 silently when stopGate is not true, outside a git repository, on a
# clean working tree, with no commands configured, and while a loop session
# is active: stop-hook.sh owns that case. Claude Code caps consecutive Stop
# hook continuations, so a command that can never pass does not loop forever.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/preflight.sh
source "$HOOK_DIR/../scripts/lib/preflight.sh"

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')

REPO_ROOT="$(loop_repo_root "$CWD")"
[[ -n "$REPO_ROOT" ]] || exit 0
if [[ -f "$(loop_session_file "$REPO_ROOT")" ]]; then exit 0; fi
[[ "$(cv_guard_setting "$REPO_ROOT" stopGate)" == "true" ]] || exit 0
[[ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]] || exit 0

COMMANDS=$(cv_merged_config "$REPO_ROOT" | jq -c '.["ticket-delivery"].commands? // {} | if type == "object" then . else {} end')

for KEY in lint staticAnalysis test; do
  CMD=$(echo "$COMMANDS" | jq -r --arg key "$KEY" '.[$key] // empty | strings')
  [[ -n "$CMD" ]] || continue
  STATUS=0
  OUTPUT=$(cd "$REPO_ROOT" && bash -c "$CMD" 2>&1) || STATUS=$?
  (( STATUS == 0 )) && continue
  jq -nc --arg key "$KEY" --arg cmd "$CMD" --arg status "$STATUS" --arg out "$(printf '%s' "$OUTPUT" | tail -n 40)" '
    {
      decision: "block",
      reason: ("The " + $key + " command failed (exit " + $status + "): " + $cmd + "\nFix the failures, then finish. Last output:\n" + $out)
    }
  '
  exit 0
done

exit 0

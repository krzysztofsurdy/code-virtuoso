#!/bin/bash
# Stop hook - opt-in quality gate outside a loop (loop.guard.stopGate).
#
# When the session would end with uncommitted changes, runs the project's
# ticket-delivery.commands lint, staticAnalysis and test (those that are set,
# in that order) from the git root. The first failure blocks the stop with the
# command and the last 40 lines of its output; all passing prints nothing.
#
# stopGate is read only from the user layer and an untracked
# .code-virtuoso/config.local.json, never from the committed project config,
# so a cloned repository cannot make the hook run its commands.
#
# Exits 0 silently when stopGate is not true, outside a git repository, on a
# clean working tree, with no commands configured, on a continued stop
# (stop_hook_active), while a loop session is active (stop-hook.sh owns that
# case), and within 10 seconds of the loop's last run_stopped event.
set -euo pipefail
command -v jq >/dev/null 2>&1 || exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/preflight.sh
source "$HOOK_DIR/../scripts/lib/preflight.sh"

# trusted_stop_gate <root>: loop.guard.stopGate from the user and untracked local layers.
trusted_stop_gate() {
  local root="$1" f files=()
  f="$(cv_config_home)/config.json"
  [[ -f "$f" ]] && jq empty "$f" >/dev/null 2>&1 && files+=("$f")
  f="$root/$CV_DIR_NAME/config.local.json"
  if [[ -f "$f" ]] && ! git -C "$root" ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
    && jq empty "$f" >/dev/null 2>&1; then
    files+=("$f")
  fi
  [[ ${#files[@]} -gt 0 ]] || return 0
  jq -sc 'reduce .[] as $x ({}; . * $x) | (.loop.guard.stopGate)? // empty' "${files[@]}"
}

# loop_just_stopped <root>: the loop's events.jsonl has a run_stopped event from the last 10 seconds.
loop_just_stopped() {
  local events
  events="$(dirname "$(loop_session_file "$1")")/events.jsonl"
  [[ -f "$events" ]] || return 1
  tail -n 20 "$events" | jq -s -e 'any(.[]; .event == "run_stopped" and (now - (.ts | fromdateiso8601? // 0)) < 10)' >/dev/null 2>&1
}

HOOK_INPUT=$(cat)
CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // "."')
[[ "$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')" != "true" ]] || exit 0

REPO_ROOT="$(loop_repo_root "$CWD")"
[[ -n "$REPO_ROOT" ]] || exit 0
if [[ -f "$(loop_session_file "$REPO_ROOT")" ]]; then exit 0; fi
[[ "$(trusted_stop_gate "$REPO_ROOT")" == "true" ]] || exit 0
if loop_just_stopped "$REPO_ROOT"; then exit 0; fi
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

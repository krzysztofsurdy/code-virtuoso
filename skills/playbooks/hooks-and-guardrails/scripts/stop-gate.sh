#!/usr/bin/env bash
# Stop hook: do not let the agent finish while the project's test command fails.
# Usage in hook config: stop-gate.sh "<test command>"
# Skips the gate when the working tree has no changes, so questions and
# read-only turns are not slowed down. Emits a JSON block decision (valid for
# Claude Code and Codex); prints nothing when tests pass.
#
# Claude Code stops continuing after 8 consecutive stop-hook continuations
# (CLAUDE_CODE_STOP_HOOK_BLOCK_CAP raises it), so a test that can never pass
# does not loop forever.
set -u

test_cmd="${1:-}"
if [ -z "$test_cmd" ]; then
  echo "stop-gate.sh: pass the test command as the first argument" >&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || exit 0

cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
cd "${cwd:-.}" 2>/dev/null || exit 0

if git rev-parse --git-dir >/dev/null 2>&1 && [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

output="$(bash -c "$test_cmd" 2>&1)"
status=$?
[ "$status" -eq 0 ] && exit 0

tail_lines="$(printf '%s' "$output" | tail -n 40)"
jq -nc --arg cmd "$test_cmd" --arg out "$tail_lines" \
  '{decision: "block", reason: ("The test command failed: " + $cmd + "\nFix the failures, then finish. Last output:\n" + $out)}'
exit 0

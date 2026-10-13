#!/usr/bin/env bash
# SessionStart hook (matcher: compact): restore the facts that compaction tends
# to lose. Prints a SessionStart additionalContext JSON, or nothing when there
# is nothing to say. Context file: .claude/key-context.md (or set KEY_CONTEXT_FILE).
# State facts, do not give commands: phrasing that looks like out-of-band
# instructions can trip the agent's injection defenses.
set -u

CAP=2000
command -v jq >/dev/null 2>&1 || exit 0

cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
cd "${cwd:-.}" 2>/dev/null || exit 0

parts=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch="$(git branch --show-current 2>/dev/null)"
  changed="$(git status --short 2>/dev/null | head -n 15)"
  parts="Current branch: ${branch:-detached HEAD}"
  [ -n "$changed" ] && parts="${parts}"$'\n'"Uncommitted changes:"$'\n'"${changed}"
fi

file="${KEY_CONTEXT_FILE:-.claude/key-context.md}"
if [ -f "$file" ]; then
  note="$(head -c "$CAP" "$file")"
  parts="${parts:+${parts}$'\n\n'}${note}"
fi

[ -n "$parts" ] || exit 0
jq -nc --arg ctx "$parts" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'

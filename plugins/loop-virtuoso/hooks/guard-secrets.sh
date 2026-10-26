#!/bin/bash
# PreToolUse hook - opt-in secret-file guard (loop.guard.blockSecrets).
#
# Blocks tool calls that read or edit secret files (.env, keys, ~/.ssh, ...)
# and Bash commands that dump the environment, by exiting 2 with the reason on
# stderr. Exits 0 silently unless loop.guard.blockSecrets is true. Works in
# and out of a loop session.
#
# The matching is a port of the hooks-and-guardrails playbook's
# block-secret-reads.sh; tests/test_guard.sh keeps the two in parity. Best
# effort only: a hook cannot see what a script reads internally.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib/config.sh
source "$HOOK_DIR/../scripts/lib/config.sh"

HOOK_INPUT=$(cat)
CWD=$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // "."' 2>/dev/null || echo ".")
[[ "$(cv_guard_setting "$(cv_root_for "$CWD")" blockSecrets)" == "true" ]] || exit 0

# secrets_block <reason>: refuses the tool call. Fails closed on bad input.
secrets_block() {
  printf 'Blocked: %s. Ask the user to provide the needed value another way.\n' "$1" >&2
  exit 2
}

TOOL=$(printf '%s' "$HOOK_INPUT" | jq -er '.tool_name' 2>/dev/null) || secrets_block "hook input is not valid JSON"

case "$TOOL" in
  Read | Edit | Write | MultiEdit) FIELDS='.tool_input.file_path // empty' ;;
  NotebookEdit) FIELDS='.tool_input.notebook_path // empty' ;;
  Grep) FIELDS='.tool_input.path // empty, .tool_input.glob // empty' ;;
  Glob) FIELDS='.tool_input.path // empty, .tool_input.pattern // empty' ;;
  Bash) FIELDS='.tool_input.command // empty' ;;
  *) exit 0 ;;
esac

TARGETS=$(printf '%s' "$HOOK_INPUT" | jq -r "$FIELDS") || secrets_block "hook input is not valid JSON"
[[ -n "$TARGETS" ]] || exit 0

# Template files are meant to be read.
TARGETS=$(printf '%s' "$TARGETS" | sed -E 's/\.env\.(example|sample|template|dist)//Ig')

# Token boundaries: start, slash, whitespace, quote, = < > : or a glob character before; end or separator after.
PRE='(^|[/[:space:]"'"'"'=<>:*{,])'
POST='([[:space:]"'"'"';|&)<>*,}]|$)'

SECRET_PATTERNS=(
  "${PRE}\\.env(\\.[A-Za-z0-9_.-]+)?${POST}"
  "\\.(pem|key|p12|pfx)${POST}"
  "${PRE}id_(rsa|dsa|ecdsa|ed25519)${POST}"
  "\\.(ssh|aws|gnupg)(/|[[:space:]\"';|&),}]|\$)"
  "${PRE}\\.(netrc|npmrc|pypirc)${POST}"
)

# Here-strings, not pipes: with pipefail, grep -q closing the pipe early would
# turn a match into a SIGPIPE failure and let the call through.
for pattern in "${SECRET_PATTERNS[@]}"; do
  if grep -Eiq -- "$pattern" <<<"$TARGETS"; then
    secrets_block "$TOOL touches a secret file or directory"
  fi
done

# Bare printenv or env dumps every secret in the environment.
if [[ "$TOOL" == "Bash" ]] && grep -Eq '(^|[;&|[:space:]])(printenv|env)[[:space:]]*($|[;&|])' <<<"$TARGETS"; then
  secrets_block "Bash would dump the process environment"
fi

exit 0

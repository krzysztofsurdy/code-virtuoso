#!/usr/bin/env bash
# PreToolUse hook: block tool calls that read or edit secret files.
# Works in Claude Code and Codex: reads hook JSON on stdin, exits 2 with the
# reason on stderr to block. Fails closed (exit 2) if jq is missing or the
# input is not valid JSON.
#
# Best effort only. Pair it with permissions.deny rules and the OS sandbox:
# a hook cannot see what a script reads internally.
set -u

block() {
  printf 'Blocked: %s. Ask the user to provide the needed value another way.\n' "$1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || block "jq is required by this hook"

input="$(cat)"
tool="$(printf '%s' "$input" | jq -er '.tool_name')" || block "hook input is not valid JSON"

case "$tool" in
  Read | Edit | Write | MultiEdit) fields='.tool_input.file_path // empty' ;;
  NotebookEdit) fields='.tool_input.notebook_path // empty' ;;
  Grep) fields='.tool_input.path // empty, .tool_input.glob // empty' ;;
  Glob) fields='.tool_input.path // empty, .tool_input.pattern // empty' ;;
  Bash) fields='.tool_input.command // empty' ;;
  apply_patch) fields='(.tool_input.command // "") | split("\n") | map(select(test("^\\*\\*\\* (Add|Update|Delete) File: "))) | join("\n")' ;;
  *) exit 0 ;;
esac

targets="$(printf '%s' "$input" | jq -r "$fields")" || block "hook input is not valid JSON"
[ -n "$targets" ] || exit 0

# Template files are meant to be read.
targets="$(printf '%s' "$targets" | sed -E 's/\.env\.(example|sample|template|dist)//Ig')"

# Token boundaries: start, slash, whitespace, quote, = < > : or a glob character before; end or separator after.
pre='(^|[/[:space:]"'"'"'=<>:*{,])'
post='([[:space:]"'"'"';|&)<>*,}]|$)'

secret_patterns=(
  "${pre}\\.env(\\.[A-Za-z0-9_.-]+)?${post}"
  "\\.(pem|key|p12|pfx)${post}"
  "${pre}id_(rsa|dsa|ecdsa|ed25519)${post}"
  "\\.(ssh|aws|gnupg)(/|[[:space:]\"';|&),}]|\$)"
  "${pre}\\.(netrc|npmrc|pypirc)${post}"
)

for pattern in "${secret_patterns[@]}"; do
  if printf '%s\n' "$targets" | grep -Eiq -- "$pattern"; then
    block "$tool touches a secret file or directory"
  fi
done

if [ "$tool" = "Bash" ]; then
  # Bare printenv or env dumps every secret in the environment.
  if printf '%s\n' "$targets" | grep -Eq '(^|[;&|[:space:]])(printenv|env)[[:space:]]*($|[;&|])'; then
    block "Bash would dump the process environment"
  fi
fi

exit 0

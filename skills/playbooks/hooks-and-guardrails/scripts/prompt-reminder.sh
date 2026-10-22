#!/usr/bin/env bash
# UserPromptSubmit hook: add a short reminder to every prompt, so rules loaded
# once at session start do not fade in a long session. Prints a
# UserPromptSubmit additionalContext JSON. Never fails the prompt: any problem
# ends in exit 0.
# Text, first match wins: <project>/.code-virtuoso/reminder.txt, then
# ${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/reminder.txt,
# then the default below. An empty file turns the reminder off.
set -u

CAP=600
DEFAULT="Reminder from this setup: the installed skills and the rules in CLAUDE.md and AGENTS.md apply to this request. A skill whose description matches the task should be used."

command -v jq >/dev/null 2>&1 || exit 0

cwd="$(jq -r '.cwd // empty' 2>/dev/null)"
root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)"
root="${root:-${cwd:-.}}"

if [ -n "${CODE_VIRTUOSO_CONFIG_HOME:-}" ]; then
  home="$CODE_VIRTUOSO_CONFIG_HOME"
elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
  home="$XDG_CONFIG_HOME/code-virtuoso"
elif [ -n "${HOME:-}" ]; then
  home="$HOME/.config/code-virtuoso"
else
  home=""
fi

text="$DEFAULT"
for file in "$root/.code-virtuoso/reminder.txt" "${home:+$home/reminder.txt}"; do
  if [ -n "$file" ] && [ -f "$file" ] && [ -r "$file" ]; then
    text="$(cat "$file" 2>/dev/null)"
    break
  fi
done

jq -nc --arg t "$text" --argjson cap "$CAP" '
  ($t | .[0:$cap] | sub("\\s+$"; "")) as $r
  | if ($r | test("\\S")) then
      {hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $r}}
    else empty end' 2>/dev/null
exit 0

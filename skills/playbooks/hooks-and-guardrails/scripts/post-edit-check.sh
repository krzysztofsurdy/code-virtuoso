#!/usr/bin/env bash
# PostToolUse hook: run a fast check on the file the agent just edited and
# feed failures back to it (exit 2 sends stderr to the agent). Silent on success.
# Edit the case table to match your project's formatter, linter, or type checker.
set -u

command -v jq >/dev/null 2>&1 || exit 0
file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)" || exit 0
[ -n "$file" ] && [ -f "$file" ] || exit 0

dir="$(dirname "$file")"
run=()
case "$file" in
  *.sh | *.bash) run=(bash -n "$file") ;;
  *.json) run=(jq empty "$file") ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      run=(ruff check --quiet "$file")
    else
      run=(python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$file")
    fi
    ;;
  *.php) command -v php >/dev/null 2>&1 && run=(php -l "$file") ;;
  *.js | *.jsx | *.ts | *.tsx)
    root="$(cd "$dir" && git rev-parse --show-toplevel 2>/dev/null)"
    [ -n "$root" ] && [ -x "$root/node_modules/.bin/eslint" ] && run=("$root/node_modules/.bin/eslint" --quiet "$file")
    ;;
  *.go) command -v gofmt >/dev/null 2>&1 && run=(gofmt -l "$file") ;;
esac
[ "${#run[@]}" -gt 0 ] || exit 0

output="$("${run[@]}" 2>&1)"
status=$?
# gofmt -l exits 0 and prints the file name when formatting is off.
if [ "${run[0]}" = "gofmt" ] && [ -n "$output" ]; then
  status=1
  output="gofmt: $file is not formatted. Run gofmt -w $file"
fi
if [ "$status" -ne 0 ]; then
  printf 'Check failed for %s:\n%s\n' "$file" "$(printf '%s' "$output" | head -n 30)" >&2
  exit 2
fi
exit 0

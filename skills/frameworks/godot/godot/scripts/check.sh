#!/usr/bin/env bash
# Headless import, then a parse check of every .gd file. Exits 1 on any error.
# Usage: check.sh [project_dir]      Binary: GODOT=/path/to/godot (default: godot)
#
# Godot returns exit code 0 for both steps even when a script is broken, so
# this script reads the output instead of trusting the exit code.
# The import runs first: it registers class_name globals, and without it a
# parse check reports false "Identifier not declared" errors.
# It writes .godot/ and .uid files into the project. Commit the .uid files, not .godot/.
set -uo pipefail

GODOT="${GODOT:-godot}"
DIR="${1:-.}"
PATTERN='SCRIPT ERROR|Parse Error|^ERROR:'

cd "$DIR" || exit 1
[ -f project.godot ] || { echo "check.sh: no project.godot in $(pwd)"; exit 1; }
command -v "$GODOT" >/dev/null 2>&1 || [ -x "$GODOT" ] || { echo "check.sh: Godot binary not found (set GODOT)"; exit 1; }

STATUS=0

OUT="$("$GODOT" --headless --path . --import 2>&1)"
if printf '%s\n' "$OUT" | grep -qE "$PATTERN"; then
  echo "--- import"
  printf '%s\n' "$OUT" | grep -E "$PATTERN|^ +at: "
  STATUS=1
fi

while IFS= read -r -d '' f; do
  OUT="$("$GODOT" --headless --path . --check-only --script "res://${f#./}" 2>&1)"
  if printf '%s\n' "$OUT" | grep -qE "$PATTERN"; then
    echo "--- $f"
    printf '%s\n' "$OUT" | grep -E "$PATTERN|^ +at: "
    STATUS=1
  fi
done < <(find . -name '*.gd' -not -path './.godot/*' -not -path './addons/*' -print0)

if [ "$STATUS" -eq 0 ]; then echo "check.sh: OK"; else echo "check.sh: FAILED"; fi
exit "$STATUS"

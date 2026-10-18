#!/usr/bin/env bash
# Tests for evals/stage.sh and the shape of every case under evals/cases.
# Run: bash evals/tests/test-stage.sh
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
repo=$(dirname "$here")
dest=$(mktemp -d)
trap 'rm -rf "$dest"' EXIT

fail=0
check() {
  if ! "$@"; then
    echo "FAIL: $*" >&2
    fail=1
  fi
}

"$here/stage.sh" "$dest" > /dev/null

check jq -e '.name == "code-virtuoso-evals"' "$dest/.claude-plugin/plugin.json" > /dev/null

while IFS= read -r skill; do
  check test -f "$dest/skills/$(basename "$skill")/SKILL.md"
done < <(jq -r '.plugins[] | select(.source != null) | .source as $s | (.skills // [])[] | "\($s)/\(.)"' "$repo/.claude-plugin/marketplace.json")

check test -f "$dest/agents/reviewer.md"
check test -d "$dest/evals/triggers"
check test ! -e "$dest/evals/README.md"

if "$here/stage.sh" "$dest" > /dev/null 2>&1; then
  echo "FAIL: stage.sh must refuse a non-empty destination" >&2
  fail=1
fi

names=$(find "$dest/evals" -name prompt.md -exec dirname {} \; | xargs -n1 basename | sort)
dupes=$(echo "$names" | uniq -d)
check test -z "$dupes"

while IFS= read -r prompt; do
  dir=$(dirname "$prompt")
  case_name=$(basename "$dir")
  check grep -q '^tags:' "$prompt"
  check test -n "$(ls "$dir/graders" 2> /dev/null)"
  if [ -f "$dir/case.yaml" ]; then
    check grep -q "^name: $case_name\$" "$dir/case.yaml"
    script=$(sed -n 's/^  scaffold_script: //p' "$dir/case.yaml")
    check test -f "$dir/$script"
  fi
done < <(find "$dest/evals" -name prompt.md)

dry=$(EVAL_DRY_RUN=1 "$here/run.sh" all)
check grep -q -- '--tag trigger demotion' <<< "$dry"
check grep -q -- '--tag outcome' <<< "$dry"
check grep -q -- '--allow-tools Write Edit Bash(python3 \*)' <<< "$dry"
check test "$(grep -c 'claude plugin eval' <<< "$dry")" -eq 2
check grep -q -- '--tag __none__' <<< "$(EVAL_DRY_RUN=1 "$here/run.sh" check)"
if EVAL_DRY_RUN=1 "$here/run.sh" bogus > /dev/null 2>&1; then
  echo "FAIL: run.sh must reject an unknown mode" >&2
  fail=1
fi

[ "$fail" -eq 0 ] && echo "ok"
exit "$fail"

#!/bin/bash
# Test runner: bash tests/run.sh [test-file-glob-fragment]
# Each tests/test_*.sh defines functions named test_*. Every function runs in
# its own subshell against throwaway git repos under a temp directory.
set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PLUGIN_ROOT="$(cd "$TESTS_DIR/.." && pwd)"
filter="${1:-}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export WORK

export HOME="$WORK/home"
export TMPDIR="$WORK/tmp"
unset CODE_VIRTUOSO_CONFIG_HOME CLAUDE_CONFIG_DIR
mkdir -p "$HOME" "$TMPDIR"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$WORK/gitconfig"
git config --file "$GIT_CONFIG_GLOBAL" user.name "Loop Test"
git config --file "$GIT_CONFIG_GLOBAL" user.email "loop@test.invalid"
git config --file "$GIT_CONFIG_GLOBAL" init.defaultBranch main
export CLAUDE_CODE_SESSION_ID="sess-test"

pass=0
fail=0
failed_names=()

for file in "$TESTS_DIR"/test_*.sh; do
  [[ -n "$filter" && "$file" != *"$filter"* ]] && continue
  names="$(grep -o '^test_[A-Za-z0-9_]*()' "$file" | tr -d '()')"
  for name in $names; do
    out="$WORK/out.$$"
    # Every test gets its own HOME, so user-layer files never leak between tests.
    test_home="$(mktemp -d "$WORK/home.XXXXXX")"
    (
      export HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" XDG_STATE_HOME="$test_home/.local/state"
      set -e; source "$TESTS_DIR/helpers.sh"; source "$file"; "$name"
    ) >"$out" 2>&1
    rc=$?
    if (( rc == 0 )); then
      pass=$((pass + 1))
      printf 'PASS %s::%s\n' "$(basename "$file")" "$name"
    else
      fail=$((fail + 1))
      failed_names+=("$(basename "$file")::$name")
      printf 'FAIL %s::%s\n' "$(basename "$file")" "$name"
      sed 's/^/     | /' "$out" | tail -n 25
    fi
  done
done

echo "----------------------------------------"
echo "passed: $pass  failed: $fail"
if (( fail > 0 )); then
  printf '  failed: %s\n' "${failed_names[@]}"
  exit 1
fi

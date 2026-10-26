#!/bin/bash
# Shared helpers for the plain-bash regression tests.

SCRIPTS="$PLUGIN_ROOT/scripts"
HOOKS="$PLUGIN_ROOT/hooks"

die() { echo "ASSERT FAILED: $*" >&2; exit 1; }

assert_eq() { [[ "$1" == "$2" ]] || die "${3:-values differ}: expected [$2] got [$1]"; }
assert_contains() { [[ "$1" == *"$2"* ]] || die "${3:-missing text}: [$2] not in [$1]"; }
assert_not_contains() { [[ "$1" != *"$2"* ]] || die "${3:-unexpected text}: [$2] found in [$1]"; }
assert_file() { [[ -e "$1" ]] || die "missing file: $1"; }
assert_no_file() { [[ ! -e "$1" ]] || die "unexpected file: $1"; }

# new_tmp_dir <label>: a fresh directory under the runner's WORK dir.
new_tmp_dir() { mktemp -d "$WORK/$1.XXXXXX"; }

# mk_repo: echo the path of a fresh git repo on branch main with one commit.
# .code-virtuoso is not committed (it is untracked, as in real use).
mk_repo() {
  local repo
  repo="$(cd "$(new_tmp_dir repo)" && pwd -P)"
  git -C "$repo" init -q -b main
  mkdir -p "$repo/src" "$repo/tests"
  echo "seed" > "$repo/src/seed.txt"
  echo "t" > "$repo/tests/t.txt"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "seed"
  echo "$repo"
}

# loop_dir <repo>: the loop directory inside a repo.
loop_dir() { echo "$1/.code-virtuoso/loop"; }

# write_backlog <repo> <branch> [verify_command] [extra_config_json]
# Writes a plan only: no step status, attempts or notes (those are run state).
write_backlog() {
  local repo="$1" branch="$2" verify="${3:-true}" extra="${4:-}"
  [[ -n "$extra" ]] || extra='{}'
  mkdir -p "$repo/.code-virtuoso/loop"
  jq -n --arg branch "$branch" --arg verify "$verify" --argjson extra "$extra" '{
    project: "t", branch: $branch, description: "d",
    config: ({
      maxIterations: 10, maxAttemptsPerItem: 3, maxStallIterations: 3,
      maxViolations: 3, permissionMode: "acceptEdits",
      protectedPaths: ["tests/**"], allowedTools: ["Read"]
    } + $extra),
    items: [
      {id: "ITEM-001", title: "one", description: "d", acceptanceCriteria: ["a"], priority: 1,
       steps: [{id: "s1", instructions: "do it", verifyCommand: $verify}]},
      {id: "ITEM-002", title: "two", description: "d", acceptanceCriteria: ["a"], priority: 2,
       steps: [{id: "s1", instructions: "do it", verifyCommand: $verify}]}
    ]
  }' > "$repo/.code-virtuoso/loop/backlog.json"
}

# start_loop <repo> [args...]: run setup-start.sh from the repo root.
start_loop() {
  local repo="$1"; shift
  (cd "$repo" && bash "$SCRIPTS/setup-start.sh" "$@")
}

# stop_hook <cwd> [session_id]: run the Stop hook; prints its stdout.
stop_hook() {
  local cwd="$1" sid="${2:-$CLAUDE_CODE_SESSION_ID}"
  jq -nc --arg cwd "$cwd" --arg sid "$sid" '{cwd: $cwd, session_id: $sid}' | bash "$HOOKS/stop-hook.sh"
}

# guard_hook <cwd> <tool_name> <path_field> <path>
guard_hook() {
  jq -nc --arg cwd "$1" --arg tool "$2" --arg field "$3" --arg path "$4" \
    '{cwd: $cwd, tool_name: $tool, tool_input: {($field): $path}}' | bash "$HOOKS/guard-protected-paths.sh"
}

# install_fake_claude: puts a stub `claude` first on PATH. The stub appends its
# argv to $FAKE_CLAUDE_LOG, optionally runs $FAKE_CLAUDE_ACTION, and prints an
# envelope that satisfies run-batch.sh. $FAKE_CLAUDE_JSON replaces that envelope
# and $FAKE_CLAUDE_RC sets the exit code.
install_fake_claude() {
  local bin
  bin="$(new_tmp_dir bin)"
  cat > "$bin/claude" <<'STUB'
#!/bin/bash
printf 'CALL %s\n' "$*" >> "${FAKE_CLAUDE_LOG:-/dev/null}"
[[ -n "${FAKE_CLAUDE_ACTION:-}" ]] && eval "$FAKE_CLAUDE_ACTION"
default_json='{"result":"ok","total_cost_usd":0.01}'
echo "${FAKE_CLAUDE_JSON:-$default_json}"
exit "${FAKE_CLAUDE_RC:-0}"
STUB
  chmod +x "$bin/claude"
  export PATH="$bin:$PATH"
  export FAKE_CLAUDE_LOG="$bin/calls.log"
  : > "$FAKE_CLAUDE_LOG"
}

all_commit_files() { git -C "$1" log --all --name-only --pretty=format: | sort -u; }

# capture <cmd...>: run a command that may fail; sets OUT (stdout+stderr) and RC.
capture() { RC=0; OUT="$("$@" 2>&1)" || RC=$?; }

# on_feature <repo> [branch]: switch the repo to the backlog branch (default feat/x).
on_feature() { git -C "$1" checkout -q -b "${2:-feat/x}"; }

step_actions() { jq -r 'select(.event == "step_verdict") | .action' "$1/.code-virtuoso/loop/state/events.jsonl"; }

# decision_of <hook_output_json>: the Stop hook decision, or empty.
decision_of() { echo "$1" | jq -r '.decision // empty'; }
# deny_of <hook_output_json>: the PreToolUse permission decision, or empty.
deny_of() { echo "$1" | jq -r '.hookSpecificOutput.permissionDecision // empty'; }

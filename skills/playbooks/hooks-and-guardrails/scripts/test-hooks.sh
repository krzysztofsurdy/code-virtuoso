#!/usr/bin/env bash
# Self-test for the example hook scripts. Feeds sample hook JSON on stdin and
# checks exit codes and output. Run from anywhere: bash scripts/test-hooks.sh
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

# expect_exit <name> <expected-exit> <script> <json> [script args...]
expect_exit() {
  local name="$1" want="$2" script="$3" json="$4"
  shift 4
  local out got
  out="$(printf '%s' "$json" | "$script" "$@" 2>&1)"
  got=$?
  if [ "$got" -eq "$want" ]; then
    PASS=$((PASS + 1))
    printf 'ok   %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$name" "$got" "$want" "$out"
  fi
  LAST_OUT="$out"
}

expect_contains() {
  local name="$1" needle="$2"
  if printf '%s' "$LAST_OUT" | grep -qF -- "$needle"; then
    PASS=$((PASS + 1))
    printf 'ok   %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s (output lacks %s)\n%s\n' "$name" "$needle" "$LAST_OUT"
  fi
}

expect_empty() {
  local name="$1"
  if [ -z "$LAST_OUT" ]; then
    PASS=$((PASS + 1))
    printf 'ok   %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s (expected no output)\n%s\n' "$name" "$LAST_OUT"
  fi
}

pre() { printf '{"hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' "$1" "$2"; }

# --- block-secret-reads.sh (PreToolUse) ---
S="$DIR/block-secret-reads.sh"
expect_exit "read .env is blocked" 2 "$S" "$(pre Read '{"file_path":"/proj/.env"}')"
expect_contains "block message names the reason" "Blocked"
expect_exit "read .env.local is blocked" 2 "$S" "$(pre Read '{"file_path":"/proj/.env.local"}')"
expect_exit "read .ENV is blocked (case-insensitive)" 2 "$S" "$(pre Read '{"file_path":"/proj/.ENV"}')"
expect_exit "read .env.example is allowed" 0 "$S" "$(pre Read '{"file_path":"/proj/.env.example"}')"
expect_exit "read source file is allowed" 0 "$S" "$(pre Read '{"file_path":"/proj/src/app.php"}')"
expect_exit "read .environment-notes.md is allowed" 0 "$S" "$(pre Read '{"file_path":"/proj/docs/.environment-notes.md"}')"
expect_exit "read pem key is blocked" 2 "$S" "$(pre Read '{"file_path":"/proj/certs/server.pem"}')"
expect_exit "read ssh private key is blocked" 2 "$S" "$(pre Read '{"file_path":"/home/u/.ssh/id_ed25519"}')"
expect_exit "read aws credentials is blocked" 2 "$S" "$(pre Read '{"file_path":"/home/u/.aws/credentials"}')"
expect_exit "edit .env is blocked" 2 "$S" "$(pre Edit '{"file_path":"/proj/.env","old_string":"a","new_string":"b"}')"
expect_exit "write README mentioning .env in content is allowed" 0 "$S" "$(pre Write '{"file_path":"/proj/README.md","content":"copy .env.example to .env"}')"
expect_exit "grep with .env glob is blocked" 2 "$S" "$(pre Grep '{"pattern":"KEY","path":"/proj","glob":".env*"}')"
expect_exit "grep for process.env.FOO is allowed" 0 "$S" "$(pre Grep '{"pattern":"process.env.FOO","path":"/proj/src"}')"
expect_exit "bash cat .env is blocked" 2 "$S" "$(pre Bash '{"command":"cat .env"}')"
expect_exit "bash cat nested .env.production is blocked" 2 "$S" "$(pre Bash '{"command":"cat ./config/.env.production | head"}')"
expect_exit "bash source .env is blocked" 2 "$S" "$(pre Bash '{"command":"set -a; source .env; set +a"}')"
expect_exit "bash ls ~/.ssh is blocked" 2 "$S" "$(pre Bash '{"command":"ls ~/.ssh"}')"
expect_exit "bash printenv is blocked" 2 "$S" "$(pre Bash '{"command":"printenv"}')"
expect_exit "bash env pipe is blocked" 2 "$S" "$(pre Bash '{"command":"env | sort"}')"
expect_exit "bash env with a command is allowed" 0 "$S" "$(pre Bash '{"command":"env FOO=1 npm test"}')"
expect_exit "bash git diff .env.example is allowed" 0 "$S" "$(pre Bash '{"command":"git diff -- .env.example"}')"
expect_exit "bash echo APP_ENV is allowed" 0 "$S" "$(pre Bash '{"command":"echo $APP_ENV"}')"
expect_exit "bash npm test is allowed" 0 "$S" "$(pre Bash '{"command":"npm test"}')"
PATCH_ENV='*** Begin Patch\n*** Update File: config/.env\n@@\n-A=1\n+A=2\n*** End Patch'
PATCH_OK='*** Begin Patch\n*** Update File: README.md\n@@\n-x\n+copy .env.example to .env\n*** End Patch'
expect_exit "codex apply_patch on .env is blocked" 2 "$S" "$(pre apply_patch "{\"command\":\"$PATCH_ENV\"}")"
expect_exit "codex apply_patch mentioning .env in text is allowed" 0 "$S" "$(pre apply_patch "{\"command\":\"$PATCH_OK\"}")"
expect_exit "other tools are ignored" 0 "$S" "$(pre WebFetch '{"url":"https://example.com/.env"}')"
expect_exit "invalid JSON fails closed" 2 "$S" "not json"

# --- post-edit-check.sh (PostToolUse) ---
S="$DIR/post-edit-check.sh"
post() { printf '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1"; }
printf 'echo ok\n' > "$WORK/good.sh"
printf 'if then fi (\n' > "$WORK/bad.sh"
printf '{"a": 1}\n' > "$WORK/good.json"
printf '{"a": }\n' > "$WORK/bad.json"
printf 'x = 1\n' > "$WORK/good.py"
printf 'def f(:\n' > "$WORK/bad.py"
printf 'hello\n' > "$WORK/note.txt"
expect_exit "valid shell passes" 0 "$S" "$(post "$WORK/good.sh")"
expect_exit "invalid shell reports to the agent" 2 "$S" "$(post "$WORK/bad.sh")"
expect_contains "feedback names the file" "bad.sh"
expect_exit "valid json passes" 0 "$S" "$(post "$WORK/good.json")"
expect_exit "invalid json reports to the agent" 2 "$S" "$(post "$WORK/bad.json")"
expect_exit "valid python passes" 0 "$S" "$(post "$WORK/good.py")"
expect_exit "invalid python reports to the agent" 2 "$S" "$(post "$WORK/bad.py")"
expect_exit "unknown extension is skipped" 0 "$S" "$(post "$WORK/note.txt")"
expect_exit "missing file is skipped" 0 "$S" "$(post "$WORK/gone.sh")"

# --- stop-gate.sh (Stop) ---
S="$DIR/stop-gate.sh"
REPO="$WORK/repo"
mkdir -p "$REPO" && git -C "$REPO" init -q && git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
stop() { printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":%s}' "$REPO" "$1"; }
expect_exit "clean tree skips the gate" 0 "$S" "$(stop false)" "false"
expect_empty "clean tree prints nothing"
echo change > "$REPO/file.txt"
expect_exit "failing tests block the stop" 0 "$S" "$(stop false)" "echo 'FAILED: 1 test'; exit 1"
expect_contains "block decision is emitted" '"decision":"block"'
expect_contains "test output is included in the reason" "FAILED: 1 test"
expect_exit "passing tests allow the stop" 0 "$S" "$(stop false)" "true"
expect_empty "passing tests print nothing"
expect_exit "failing tests still block on a continued stop" 0 "$S" "$(stop true)" "exit 1"
expect_contains "continued stop is still blocked" '"decision":"block"'
expect_exit "missing test command is a usage error" 1 "$S" "$(stop false)"

# --- reinject-context.sh (SessionStart, matcher compact) ---
S="$DIR/reinject-context.sh"
ctx() { printf '{"hook_event_name":"SessionStart","source":"compact","cwd":"%s"}' "$1"; }
git -C "$REPO" checkout -q -b feat/PROJ-1_demo
expect_exit "git state is injected without a context file" 0 "$S" "$(ctx "$REPO")"
expect_contains "branch is reported" "feat/PROJ-1_demo"
printf '%s' "$LAST_OUT" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null \
  && { PASS=$((PASS + 1)); echo "ok   output is valid SessionStart JSON"; } \
  || { FAIL=$((FAIL + 1)); echo "FAIL output is not valid SessionStart JSON"; }
mkdir -p "$REPO/.claude" && printf 'Run tests with make test. Never edit generated/.\n' > "$REPO/.claude/key-context.md"
expect_exit "context file is injected" 0 "$S" "$(ctx "$REPO")"
expect_contains "context file content present" "Run tests with make test"
head -c 5000 /dev/zero | tr '\0' 'x' > "$REPO/.claude/key-context.md"
expect_exit "oversized context file is capped" 0 "$S" "$(ctx "$REPO")"
LEN="$(printf '%s' "$LAST_OUT" | jq -r '.hookSpecificOutput.additionalContext | length')"
[ "$LEN" -lt 3000 ] && { PASS=$((PASS + 1)); echo "ok   injected context stays under cap ($LEN chars)"; } \
  || { FAIL=$((FAIL + 1)); echo "FAIL injected context too long ($LEN chars)"; }
mkdir -p "$WORK/plain"
expect_exit "no git and no file injects nothing" 0 "$S" "$(ctx "$WORK/plain")"
expect_empty "nothing printed"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

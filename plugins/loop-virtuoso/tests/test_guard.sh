#!/bin/bash
# Opt-in guard hooks: guard-secrets.sh, guard-tests.sh, guard-stop.sh.
# Every guard is off unless the loop.guard namespace turns it on. Config goes
# in the user layer so the repo's working tree stays clean.

SKILL_SECRETS="$PLUGIN_ROOT/../../skills/playbooks/hooks-and-guardrails/scripts/block-secret-reads.sh"

# guard_config <json>: writes the user-layer config.json.
guard_config() {
  mkdir -p "$XDG_CONFIG_HOME/code-virtuoso"
  echo "$1" > "$XDG_CONFIG_HOME/code-virtuoso/config.json"
}

# fake_session <repo>: marks a loop session as active.
fake_session() {
  mkdir -p "$1/.code-virtuoso/loop/state"
  echo '{"active":true}' > "$1/.code-virtuoso/loop/state/session.local.json"
}

# tool_input_json <cwd> <tool> <tool_input_json>
tool_input_json() {
  jq -nc --arg cwd "$1" --arg tool "$2" --argjson input "$3" '{cwd: $cwd, tool_name: $tool, tool_input: $input}'
}

# secrets_rc <hook_script> <hook_input_json>: echoes the hook's exit code.
secrets_rc() {
  local rc=0
  printf '%s' "$2" | bash "$1" >/dev/null 2>&1 || rc=$?
  echo "$rc"
}

# tests_hook <cwd> <tool> <path>: runs guard-tests.sh; prints its stdout.
tests_hook() {
  tool_input_json "$1" "$2" "$(jq -nc --arg p "$3" '{file_path: $p}')" | bash "$HOOKS/guard-tests.sh"
}

# gate_hook <cwd>: runs guard-stop.sh; prints its stdout.
gate_hook() {
  jq -nc --arg cwd "$1" '{cwd: $cwd, session_id: "s", stop_hook_active: false}' | bash "$HOOKS/guard-stop.sh"
}

# assert_silent <cmd...>: the command exits 0 and prints nothing on stdout.
assert_silent() {
  local out
  out="$("$@")" || die "$* exited non-zero"
  assert_eq "$out" "" "$*"
}

# secrets_cases <dir>: one hook input per line, mixing blocked and allowed calls.
secrets_cases() {
  local d="$1" t
  for t in "$d/.env" "$d/.env.local" "$d/config/.env.production" "$d/.env.example" "$d/.env.sample" \
           "$d/certs/server.pem" "$d/id_rsa" "$d/.ssh/config" "$d/.aws/credentials" "$d/.npmrc" \
           "$d/src/app.php" "$d/environment.ts" "$d/README.md"; do
    tool_input_json "$d" Read "$(jq -nc --arg p "$t" '{file_path: $p}')"
    tool_input_json "$d" Write "$(jq -nc --arg p "$t" '{file_path: $p, content: "x"}')"
  done
  tool_input_json "$d" NotebookEdit "$(jq -nc --arg p "$d/.env" '{notebook_path: $p}')"
  tool_input_json "$d" NotebookEdit "$(jq -nc --arg p "$d/a.ipynb" '{notebook_path: $p}')"
  tool_input_json "$d" Grep '{"pattern":"KEY","path":".env"}'
  tool_input_json "$d" Grep '{"pattern":"KEY","path":"src"}'
  tool_input_json "$d" Glob '{"pattern":"*","glob":"**/*.pem"}'
  tool_input_json "$d" Glob '{"pattern":"*.ts"}'
  for t in 'cat .env' 'cat .env.example' 'grep -r KEY ~/.ssh' 'printenv' 'env | sort' 'env FOO=1 make test' \
           'ls -la' 'make test' 'source .env && run' 'cat ~/.aws/credentials' 'echo ok; printenv' 'cat src/key.txt'; do
    tool_input_json "$d" Bash "$(jq -nc --arg c "$t" '{command: $c}')"
  done
  tool_input_json "$d" Unknown '{"file_path":".env"}'
  echo 'not json'
}

test_guards_are_noops_without_config() {
  local repo; repo="$(mk_repo)"
  echo "changed" >> "$repo/src/seed.txt"
  assert_eq "$(secrets_rc "$HOOKS/guard-secrets.sh" "$(tool_input_json "$repo" Read "{\"file_path\":\"$repo/.env\"}")")" "0"
  assert_silent tests_hook "$repo" Edit "$repo/tests/t.txt"
  assert_silent gate_hook "$repo"
}

test_guards_are_noops_when_config_turns_them_off() {
  local repo; repo="$(mk_repo)"
  echo "changed" >> "$repo/src/seed.txt"
  guard_config '{"loop":{"guard":{"blockSecrets":false,"protectTests":false,"stopGate":false}},"ticket-delivery":{"commands":{"test":"exit 1"}}}'
  assert_eq "$(secrets_rc "$HOOKS/guard-secrets.sh" "$(tool_input_json "$repo" Read "{\"file_path\":\"$repo/.env\"}")")" "0"
  assert_silent tests_hook "$repo" Edit "$repo/tests/t.txt"
  assert_silent gate_hook "$repo"
}

test_secrets_blocks_secret_files_and_allows_templates() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"blockSecrets":true}}}'
  local out rc=0
  out="$(tool_input_json "$repo" Read "{\"file_path\":\"$repo/.env\"}" | bash "$HOOKS/guard-secrets.sh" 2>&1)" || rc=$?
  assert_eq "$rc" "2"
  assert_contains "$out" "Blocked"
  assert_eq "$(secrets_rc "$HOOKS/guard-secrets.sh" "$(tool_input_json "$repo" Read "{\"file_path\":\"$repo/.env.example\"}")")" "0"
  assert_eq "$(secrets_rc "$HOOKS/guard-secrets.sh" "$(tool_input_json "$repo" Bash '{"command":"printenv"}')")" "2"
  assert_eq "$(secrets_rc "$HOOKS/guard-secrets.sh" "$(tool_input_json "$repo" Bash '{"command":"make test"}')")" "0"
}

test_secrets_matches_the_playbook_script() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"blockSecrets":true}}}'
  assert_file "$SKILL_SECRETS"
  local input ours theirs blocked=0 allowed=0
  while IFS= read -r input; do
    ours="$(secrets_rc "$HOOKS/guard-secrets.sh" "$input")"
    theirs="$(secrets_rc "$SKILL_SECRETS" "$input")"
    assert_eq "$ours" "$theirs" "parity for $input"
    if [[ "$ours" == "2" ]]; then blocked=$((blocked + 1)); else allowed=$((allowed + 1)); fi
  done < <(secrets_cases "$repo")
  (( blocked >= 10 )) || die "parity set blocks too little: $blocked"
  (( allowed >= 10 )) || die "parity set allows too little: $allowed"
}

test_tests_guard_asks_for_committed_test_file() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"protectTests":"ask"}}}'
  local out; out="$(tests_hook "$repo/src" Edit "$repo/tests/t.txt")"
  assert_eq "$(deny_of "$out")" "ask"
  assert_eq "$(echo "$out" | jq -r '.hookSpecificOutput.hookEventName')" "PreToolUse"
  assert_contains "$(echo "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason')" "tests/t.txt"
}

test_tests_guard_denies_with_custom_globs() {
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/spec"
  echo "s" > "$repo/spec/a_spec.rb"
  echo "x" > "$repo/FooTest.php"
  git -C "$repo" add spec FooTest.php && git -C "$repo" commit -q -m spec
  guard_config '{"loop":{"guard":{"protectTests":"deny","testGlobs":["spec/**"]}}}'
  assert_eq "$(deny_of "$(tests_hook "$repo" Write "$repo/spec/a_spec.rb")")" "deny"
  assert_eq "$(deny_of "$(tests_hook "$repo" MultiEdit "spec/a_spec.rb")")" "deny"
  assert_silent tests_hook "$repo" Edit "$repo/tests/t.txt"
  guard_config '{"loop":{"guard":{"protectTests":"deny"}}}'
  assert_eq "$(deny_of "$(tests_hook "$repo" Edit "$repo/FooTest.php")")" "deny"
}

test_tests_guard_allows_new_and_non_test_files() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"protectTests":"deny"}}}'
  assert_silent tests_hook "$repo" Write "$repo/tests/new_case.txt"
  assert_silent tests_hook "$repo" Write "$repo/tests/brand/new/dir/x.txt"
  assert_silent tests_hook "$repo" Edit "$repo/src/seed.txt"
  assert_silent tests_hook "$repo" Read "$repo/tests/t.txt"
}

test_tests_guard_steps_aside_for_loop_and_non_repo() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"protectTests":"deny"}}}'
  fake_session "$repo"
  assert_silent tests_hook "$repo" Edit "$repo/tests/t.txt"
  local dir; dir="$(new_tmp_dir plain)"
  mkdir -p "$dir/tests" && echo t > "$dir/tests/t.txt"
  assert_silent tests_hook "$dir" Edit "$dir/tests/t.txt"
}

test_stop_gate_skips_clean_tree_and_loop_session() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"stopGate":true}},"ticket-delivery":{"commands":{"test":"exit 1"}}}'
  assert_silent gate_hook "$repo"
  echo "changed" >> "$repo/src/seed.txt"
  fake_session "$repo"
  assert_silent gate_hook "$repo"
  local dir; dir="$(new_tmp_dir plain)"
  assert_silent gate_hook "$dir"
}

test_stop_gate_without_commands_is_noop() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"stopGate":true}}}'
  echo "changed" >> "$repo/src/seed.txt"
  assert_silent gate_hook "$repo"
}

test_stop_gate_passes_when_commands_pass() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"stopGate":true}},"ticket-delivery":{"commands":{"lint":"echo lint >> ran.log","staticAnalysis":"echo sa >> ran.log","test":"test -f src/seed.txt && echo test >> ran.log"}}}'
  echo "changed" >> "$repo/src/seed.txt"
  assert_silent gate_hook "$repo/src"
  assert_eq "$(tr '\n' ' ' < "$repo/ran.log")" "lint sa test "
}

test_stop_gate_blocks_on_first_failure_with_output() {
  local repo; repo="$(mk_repo)"
  guard_config '{"loop":{"guard":{"stopGate":true}},"ticket-delivery":{"commands":{"lint":"echo lint >> ran.log","staticAnalysis":"seq 1 60; echo sa-broke; exit 3","test":"echo test >> ran.log"}}}'
  echo "changed" >> "$repo/src/seed.txt"
  local out reason; out="$(gate_hook "$repo")"
  assert_eq "$(decision_of "$out")" "block"
  reason="$(echo "$out" | jq -r '.reason')"
  assert_contains "$reason" "staticAnalysis"
  assert_contains "$reason" "sa-broke"
  assert_contains "$reason" "seq 1 60"
  assert_not_contains "$reason" $'\n21\n'
  assert_contains "$reason" $'\n22\n'
  assert_eq "$(tr '\n' ' ' < "$repo/ran.log")" "lint "
}

test_guards_are_registered_in_hooks_json() {
  local json="$HOOKS/hooks.json" matcher_of
  matcher_of='[.hooks[$event][] | select(any(.hooks[]; .command | endswith("/hooks/" + $script + "\""))) | .matcher // ""] | first // "missing"'
  assert_eq "$(jq -r --arg event PreToolUse --arg script guard-secrets.sh "$matcher_of" "$json")" "Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit|Bash"
  assert_eq "$(jq -r --arg event PreToolUse --arg script guard-tests.sh "$matcher_of" "$json")" "Edit|Write|MultiEdit|NotebookEdit"
  assert_eq "$(jq -r --arg event Stop --arg script guard-stop.sh "$matcher_of" "$json")" ""
  assert_eq "$(jq -r --arg event PreToolUse --arg script guard-protected-paths.sh "$matcher_of" "$json")" "Edit|Write|NotebookEdit"
  assert_eq "$(jq -r --arg event Stop --arg script stop-hook.sh "$matcher_of" "$json")" ""
}

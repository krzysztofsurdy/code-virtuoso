#!/bin/bash
# eval-setup.sh: the user's setup against a vanilla Claude Code on a fixed suite.

# install_eval_claude: a stub `claude` that tells the arms apart by
# $FAKE_VANILLA_MARK (default --safe-mode) in its argv. Each arm consumes its
# own pass sequence, FAKE_SEQ_setup / FAKE_SEQ_vanilla ("1" = write done.txt,
# "0" = do nothing; exhausted or unset = 1). FAKE_EMPTY=1 prints no JSON.
install_eval_claude() {
  local bin
  bin="$(new_tmp_dir bin)"
  cat > "$bin/claude" <<'STUB'
#!/bin/bash
arm=setup
for a in "$@"; do [[ "$a" == "${FAKE_VANILLA_MARK:---safe-mode}" ]] && arm=vanilla; done
printf 'CALL arm=%s pwd=%s %s\n' "$arm" "$PWD" "$*" >> "$FAKE_CLAUDE_LOG"
count_file="$FAKE_DIR/count.$arm"
n=$(( $(cat "$count_file" 2>/dev/null || echo 0) + 1 ))
echo "$n" > "$count_file"
if [[ "$arm" == vanilla ]]; then seq="${FAKE_SEQ_vanilla:-}"; else seq="${FAKE_SEQ_setup:-}"; fi
bit="${seq:$((n - 1)):1}"
[[ "${bit:-1}" == 1 ]] && echo done > done.txt
[[ "${FAKE_EMPTY:-}" == 1 ]] && { echo "usage limit reached" >&2; exit 1; }
echo "{\"type\":\"result\",\"result\":\"ok\",\"total_cost_usd\":${FAKE_COST:-0.01},\"num_turns\":2}"
STUB
  chmod +x "$bin/claude"
  export PATH="$bin:$PATH"
  export FAKE_DIR="$bin"
  export FAKE_CLAUDE_LOG="$bin/calls.log"
  : > "$FAKE_CLAUDE_LOG"
}

# write_suite <repo> [extra_config_json] [tasks_json]
write_suite() {
  local repo="$1" extra="${2:-}" tasks="${3:-}"
  [[ -n "$extra" ]] || extra='{}'
  [[ -n "$tasks" ]] || tasks='[
    {"id": "T1", "prompt": "make done.txt", "verifyCommand": "test -f done.txt"},
    {"id": "T2", "prompt": "make done.txt again", "verifyCommand": "test -f done.txt"}
  ]'
  mkdir -p "$repo/.code-virtuoso/loop/evals"
  jq -n --argjson extra "$extra" --argjson tasks "$tasks" \
    '{version: 1, tasks: $tasks, config: ({k: 3, allowedTools: ["Read", "Edit"], permissionMode: "acceptEdits"} + $extra)}' \
    > "$repo/.code-virtuoso/loop/evals/suite.json"
}

history_of() { cat "$1/.code-virtuoso/loop/evals/history.jsonl"; }
calls_for() { grep -c "^CALL arm=$1 " "$FAKE_CLAUDE_LOG" || true; }
eval_setup() { local repo="$1"; shift; (cd "$repo" && bash "$SCRIPTS/eval-setup.sh" "$@"); }

test_eval_computes_pass_at_k_pass_hat_k_and_delta() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo"
  export FAKE_SEQ_setup="111111" FAKE_SEQ_vanilla="100000"
  capture eval_setup "$repo"
  assert_eq "$RC" "0" "complete run exits 0: $OUT"
  local h; h="$(history_of "$repo")"
  assert_eq "$(echo "$h" | jq -c '[.tasks[] | select(.arm == "setup") | [.task, .passes, .trials, .passAtK, .passHatK]]')" \
    '[["T1",3,3,true,true],["T2",3,3,true,true]]'
  assert_eq "$(echo "$h" | jq -c '[.tasks[] | select(.arm == "vanilla") | [.task, .passes, .trials, .passAtK, .passHatK]]')" \
    '[["T1",1,3,true,false],["T2",0,3,false,false]]'
  assert_eq "$(echo "$h" | jq -c '.arms.setup | [.tasks, .passAtK, .passHatK, .passes, .trials]')" '[2,2,2,6,6]'
  assert_eq "$(echo "$h" | jq -c '.arms.vanilla | [.tasks, .passAtK, .passHatK, .passes, .trials]')" '[2,1,0,1,6]'
  assert_eq "$(echo "$h" | jq -c '.delta | [.passAtK, .passHatK]')" '[1,2]'
  assert_eq "$(echo "$h" | jq -r '.totalCostUsd')" "0.12"
  assert_contains "$OUT" "T1"
  assert_contains "$OUT" "1/3"
  assert_contains "$OUT" "Delta"
}

test_eval_appends_one_history_line_per_run() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo"
  eval_setup "$repo" -k 1 >/dev/null
  eval_setup "$repo" -k 1 >/dev/null
  assert_eq "$(history_of "$repo" | wc -l | tr -d ' ')" "2"
  local h; h="$(history_of "$repo" | tail -n 1)"
  assert_eq "$(echo "$h" | jq -r .gitSha)" "$(git -C "$repo" rev-parse HEAD)"
  assert_eq "$(echo "$h" | jq -r .k)" "1"
  assert_eq "$(echo "$h" | jq -r .stopReason)" "complete"
  [[ "$(echo "$h" | jq -r .suiteHash)" =~ ^[0-9a-f]{64}$ ]] || die "suiteHash is not a sha256: $h"
  [[ -n "$(echo "$h" | jq -r '.ts // empty')" ]] || die "missing ts"
}

test_eval_runs_each_trial_in_a_fresh_worktree_and_removes_it() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 2}'
  eval_setup "$repo" >/dev/null
  assert_eq "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" "1" "only the main worktree remains"
  assert_no_file "$repo/done.txt"
  local dirs; dirs="$(sed -n 's/.* pwd=\([^ ]*\) .*/\1/p' "$FAKE_CLAUDE_LOG" | sort -u)"
  assert_eq "$(echo "$dirs" | wc -l | tr -d ' ')" "8" "every trial gets its own worktree"
  while IFS= read -r d; do
    [[ "$d" != "$repo" ]] || die "agent ran in the main checkout"
    assert_no_file "$d"
  done <<< "$dirs"
}

test_eval_setup_command_runs_in_the_worktree_before_the_agent() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 1}' '[{"id": "T1", "prompt": "p", "setup": "echo ready > ready.txt", "verifyCommand": "test -f ready.txt && test -f done.txt"}]'
  capture eval_setup "$repo"
  assert_eq "$RC" "0" "$OUT"
  assert_eq "$(history_of "$repo" | jq -r '.arms.setup.passes')" "1"
  assert_no_file "$repo/ready.txt"
}

test_eval_failing_setup_command_stops_the_run() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 1}' '[{"id": "T1", "prompt": "p", "setup": "exit 3", "verifyCommand": "true"}]'
  capture eval_setup "$repo"
  [[ $RC -ne 0 ]] || die "a failing setup must stop the run"
  assert_contains "$OUT" "setup_failed"
  assert_eq "$(calls_for setup)" "0"
  assert_eq "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" "1"
}

test_eval_dry_run_invokes_nothing() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo"
  capture eval_setup "$repo" --dry-run
  assert_eq "$RC" "0" "$OUT"
  assert_eq "$(wc -c < "$FAKE_CLAUDE_LOG" | tr -d ' ')" "0" "claude must not be called"
  assert_no_file "$repo/.code-virtuoso/loop/evals/history.jsonl"
  assert_contains "$OUT" "12 trials"
  assert_contains "$OUT" "--safe-mode"
  assert_eq "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" "1"
}

test_eval_cost_cap_stops_the_run() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"maxCostUsd": 0.025}'
  capture eval_setup "$repo"
  [[ $RC -ne 0 ]] || die "a cost-capped run exits non-zero"
  assert_eq "$(grep -c '^CALL' "$FAKE_CLAUDE_LOG")" "3"
  assert_eq "$(history_of "$repo" | jq -r .stopReason)" "cost_cap"
  assert_contains "$OUT" "cost_cap"
}

test_eval_max_cost_flag_overrides_suite_config() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"maxCostUsd": 100}'
  capture eval_setup "$repo" --max-cost-usd 0.015
  [[ $RC -ne 0 ]] || die "a cost-capped run exits non-zero"
  assert_eq "$(grep -c '^CALL' "$FAKE_CLAUDE_LOG")" "2"
}

test_eval_rejects_an_invalid_suite() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 0}' '[{"id": "T1", "prompt": "p"}, {"id": "T1", "prompt": "p", "verifyCommand": "true"}]'
  capture eval_setup "$repo"
  [[ $RC -ne 0 ]] || die "an invalid suite must be rejected"
  assert_contains "$OUT" "verifyCommand"
  assert_contains "$OUT" "duplicate task id: T1"
  assert_contains "$OUT" "config.k"
  assert_eq "$(wc -c < "$FAKE_CLAUDE_LOG" | tr -d ' ')" "0" "claude must not be called"
}

test_eval_rejects_a_missing_suite_and_bad_arms() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  capture eval_setup "$repo"
  [[ $RC -ne 0 ]] || die "a missing suite must be rejected"
  assert_contains "$OUT" "suite.json"
  write_suite "$repo"
  capture eval_setup "$repo" --arms setup,other
  [[ $RC -ne 0 ]] || die "an unknown arm must be rejected"
  assert_contains "$OUT" "other"
}

test_eval_vanilla_args_apply_to_the_vanilla_arm_only() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 1}'
  eval_setup "$repo" >/dev/null
  assert_eq "$(calls_for setup)" "2"
  assert_eq "$(calls_for vanilla)" "2"
  assert_not_contains "$(grep '^CALL arm=setup ' "$FAKE_CLAUDE_LOG")" "--safe-mode"
}

test_eval_vanilla_args_come_from_config() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"k": 1}'
  echo '{"loop": {"evalSetup": {"vanillaArgs": ["--strict-mcp-config", "--setting-sources", "project"]}}}' \
    > "$repo/.code-virtuoso/config.json"
  export FAKE_VANILLA_MARK="--strict-mcp-config"
  eval_setup "$repo" >/dev/null
  assert_eq "$(calls_for vanilla)" "2"
  assert_contains "$(grep '^CALL arm=vanilla ' "$FAKE_CLAUDE_LOG")" "--setting-sources project"
  assert_not_contains "$(cat "$FAKE_CLAUDE_LOG")" "--safe-mode"
  assert_eq "$(history_of "$repo" | jq -c .vanillaArgs)" '["--strict-mcp-config","--setting-sources","project"]'
}

test_eval_passes_suite_config_to_claude() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{"maxTurns": 12, "permissionMode": "plan"}'
  eval_setup "$repo" -k 1 --arms setup >/dev/null
  assert_eq "$(calls_for setup)" "2"
  assert_eq "$(calls_for vanilla)" "0"
  local log; log="$(cat "$FAKE_CLAUDE_LOG")"
  assert_contains "$log" "--output-format json"
  assert_contains "$log" "--max-turns 12"
  assert_contains "$log" "--permission-mode plan"
  assert_contains "$log" "--allowedTools Read Edit"
  assert_eq "$(history_of "$repo" | jq -c '[.arms | keys, .delta]')" '[["setup"],null]'
}

test_eval_defaults_max_turns_and_k() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo" '{}' '[{"id": "T1", "prompt": "p", "verifyCommand": "true"}]'
  local f="$repo/.code-virtuoso/loop/evals/suite.json"
  jq 'del(.config)' "$f" > "$f.new" && mv "$f.new" "$f"
  eval_setup "$repo" >/dev/null
  assert_eq "$(calls_for setup)" "3"
  assert_contains "$(cat "$FAKE_CLAUDE_LOG")" "--max-turns 40"
}

test_eval_invocation_failure_stops_the_run() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  write_suite "$repo"
  export FAKE_EMPTY=1
  capture eval_setup "$repo"
  [[ $RC -ne 0 ]] || die "an invocation failure exits non-zero"
  assert_contains "$OUT" "invocation_failed"
  assert_contains "$OUT" "usage/rate limit"
  assert_eq "$(grep -c '^CALL' "$FAKE_CLAUDE_LOG")" "1"
  assert_eq "$(history_of "$repo" | jq -r .stopReason)" "invocation_failed"
  assert_eq "$(git -C "$repo" worktree list | wc -l | tr -d ' ')" "1"
}

test_batch_invocation_failure_still_reports_hint_via_shared_invoke() {
  local repo; repo="$(mk_repo)"
  install_eval_claude
  export FAKE_EMPTY=1
  write_backlog "$repo" feat/x
  capture bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json"
  [[ $RC -ne 0 ]] || die "invocation failure stops the batch"
  local log; log="$(cat "$repo/.code-virtuoso/loop/state/progress.log")"
  assert_contains "$log" 'stop reason=invocation_failed hint="likely a usage/rate limit" detail="usage limit reached'
}

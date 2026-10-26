#!/bin/bash
# Bug 5: Mode B validates as a hard gate and applies config defaults.

test_batch_validation_is_a_hard_gate() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  local f="$repo/.code-virtuoso/loop/backlog.json"
  jq 'del(.items[0].steps[0].verifyCommand)' "$f" > "$f.new" && mv "$f.new" "$f"
  capture bash "$SCRIPTS/run-batch.sh" "$f"
  [[ $RC -ne 0 ]] || die "invalid backlog must stop the batch"
  assert_contains "$OUT" "validation failed"
  assert_eq "$(wc -c < "$FAKE_CLAUDE_LOG" | tr -d ' ')" "0" "claude must not be called"
}

test_batch_applies_config_defaults() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  local f="$repo/.code-virtuoso/loop/backlog.json"
  jq '.config.maxIterations = null | .config.permissionMode = null
      | .config.maxAttemptsPerItem = null | .config.maxStallIterations = null
      | .config.maxViolations = null' "$f" > "$f.new" && mv "$f.new" "$f"
  bash "$SCRIPTS/run-batch.sh" "$f" >/dev/null
  assert_eq "$(grep -c '^CALL' "$FAKE_CLAUDE_LOG")" "2" "both items run"
  assert_contains "$(cat "$FAKE_CLAUDE_LOG")" "--permission-mode acceptEdits"
  assert_contains "$(cat "$repo/.code-virtuoso/loop/state/progress.log")" "stop reason=complete"
}

max_turns_json() {
  echo '{"type":"result","subtype":"error_max_turns","is_error":true,"num_turns":5,"total_cost_usd":0.02,"errors":[]}'
}

test_batch_max_turns_cutoff_still_runs_the_verify_gate() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  export FAKE_CLAUDE_JSON="$(max_turns_json)" FAKE_CLAUDE_RC=1
  write_backlog "$repo" feat/x
  capture bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json"
  [[ $RC -eq 0 ]] || die "a max-turns cutoff is not a stop: $OUT"
  local log; log="$(cat "$repo/.code-virtuoso/loop/state/progress.log")"
  assert_not_contains "$log" "invocation_failed"
  assert_contains "$log" "iteration=1 subtype=error_max_turns"
  assert_contains "$log" "stop reason=complete"
  assert_contains "$log" "run-end reason=complete iterations=2 verified=2 pending=0 blocked=0 cost=0.040000"
  assert_eq "$(step_actions "$repo" | paste -sd, -)" "verified,verified"
}

test_batch_max_turns_cutoff_with_failing_verify_counts_as_failed_attempt() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  export FAKE_CLAUDE_JSON="$(max_turns_json)" FAKE_CLAUDE_RC=1
  export FAKE_CLAUDE_ACTION='echo partial >> src/partial.txt'
  write_backlog "$repo" feat/x false '{"maxIterations": 1}'
  capture bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json"
  local log; log="$(cat "$repo/.code-virtuoso/loop/state/progress.log")"
  assert_not_contains "$log" "invocation_failed"
  assert_contains "$log" "action=failed cost=0.020000"
  assert_eq "$(step_actions "$repo")" "failed"
}

test_batch_failed_invocation_without_result_json_stops_the_run() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  export FAKE_CLAUDE_JSON='Error: usage limit reached' FAKE_CLAUDE_RC=1
  write_backlog "$repo" feat/x
  capture bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json"
  [[ $RC -ne 0 ]] || die "a failed invocation stops the batch"
  local log; log="$(cat "$repo/.code-virtuoso/loop/state/progress.log")"
  assert_contains "$log" "stop reason=invocation_failed"
  assert_eq "$(step_actions "$repo" | wc -l | tr -d ' ')" "0" "no verdict without a result"
  assert_eq "$(grep -c '^CALL' "$FAKE_CLAUDE_LOG")" "1"
}

test_invoke_result_ok_accepts_result_envelopes_only() {
  source "$SCRIPTS/lib/invoke.sh"
  invoke_result_ok '{"type":"result","subtype":"success","result":"ok"}' || die "success envelope"
  invoke_result_ok "$(max_turns_json)" || die "max-turns envelope"
  invoke_result_ok '{"result":"ok"}' || die "legacy envelope with .result"
  ! invoke_result_ok '' || die "empty output"
  ! invoke_result_ok 'usage limit reached' || die "plain text"
  ! invoke_result_ok '{"error":"boom"}' || die "object without type or result"
  ! invoke_result_ok '["result"]' || die "non-object"
}

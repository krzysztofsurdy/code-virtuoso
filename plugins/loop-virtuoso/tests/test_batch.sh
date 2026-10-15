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

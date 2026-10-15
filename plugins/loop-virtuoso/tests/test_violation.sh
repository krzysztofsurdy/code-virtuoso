#!/bin/bash
# Bug 7: a violation is recorded once; the offending paths are reverted so
# later iterations do not see the same violation again.

setup_gate() {
  REPO="$(mk_repo)"
  on_feature "$REPO"
  write_backlog "$REPO" feat/x
  BACKLOG="$REPO/.code-virtuoso/loop/backlog.json"
  source "$SCRIPTS/lib/verify-gate.sh"
  verify_gate_snapshot_all "$BACKLOG"
  START="$(git -C "$REPO" rev-parse HEAD)"
}

test_violation_reverts_only_offending_paths() {
  setup_gate
  echo "cheat" > "$REPO/tests/t.txt"
  echo "ok" > "$REPO/src/ok.txt"
  local v; v="$(verify_gate_run "$BACKLOG" ITEM-001 s1 "$START")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "violation"
  assert_eq "$(cat "$REPO/tests/t.txt")" "t"
  assert_file "$REPO/src/ok.txt"
  local next; next="$(git -C "$REPO" rev-parse HEAD)"
  v="$(verify_gate_run "$BACKLOG" ITEM-001 s1 "$next")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "pass"
  assert_contains "$(all_commit_files "$REPO")" "src/ok.txt"
}

test_committed_violation_is_reverted_and_committed() {
  setup_gate
  echo "cheat" > "$REPO/tests/t.txt"
  git -C "$REPO" commit -q -am "worker commit"
  local v; v="$(verify_gate_run "$BACKLOG" ITEM-001 s1 "$START")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "violation"
  assert_eq "$(git -C "$REPO" show HEAD:tests/t.txt)" "t"
  assert_eq "$(git -C "$REPO" status --porcelain -- tests)" ""
  local next; next="$(git -C "$REPO" rev-parse HEAD)"
  v="$(verify_gate_run "$BACKLOG" ITEM-001 s1 "$next")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "pass"
}

test_new_protected_file_is_removed_on_violation() {
  setup_gate
  echo "x" > "$REPO/tests/new.txt"
  local v; v="$(verify_gate_run "$BACKLOG" ITEM-001 s1 "$START")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "violation"
  assert_no_file "$REPO/tests/new.txt"
}

test_one_violation_does_not_burn_the_budget_in_mode_a() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x true '{"maxViolations":2}'
  start_loop "$repo" >/dev/null
  echo "cheat" > "$repo/tests/t.txt"
  stop_hook "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  assert_eq "$(step_actions "$repo" | tr '\n' ' ')" "violation verified " "second iteration is clean"
  assert_not_contains "$(cat "$repo/.code-virtuoso/loop/state/events.jsonl")" "violation_limit"
  assert_eq "$(jq -r .violationCount "$repo/.code-virtuoso/loop/state/session.local.json")" "1"
}

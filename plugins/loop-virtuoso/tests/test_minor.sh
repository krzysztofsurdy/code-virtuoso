#!/bin/bash
# Bug 8: NotebookEdit guard, session ownership, cancel event, snapshot cleanup.

test_hooks_json_matches_notebook_edit() {
  local matcher; matcher="$(jq -r '.hooks.PreToolUse[0].matcher' "$PLUGIN_ROOT/hooks/hooks.json")"
  assert_contains "$matcher" "NotebookEdit"
}

test_guard_denies_protected_notebook_edit() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  jq '.config.protectedPaths += ["notebooks/**"]' "$repo/.delivery-loop/backlog.json" > "$repo/b.new"
  mv "$repo/b.new" "$repo/.delivery-loop/backlog.json"
  start_loop "$repo" >/dev/null
  local out; out="$(guard_hook "$repo" NotebookEdit notebook_path "$repo/notebooks/a.ipynb")"
  assert_eq "$(deny_of "$out")" "deny"
}

test_start_refuses_without_a_session_id() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  capture env -u CLAUDE_CODE_SESSION_ID bash -c "cd '$repo' && bash '$SCRIPTS/setup-start.sh'"
  [[ $RC -ne 0 ]] || die "must refuse without a session id"
  assert_contains "$OUT" "session"
  assert_no_file "$repo/.delivery-loop/session.local.json"
}

test_empty_session_id_is_not_claimed_by_another_session() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  local s="$repo/.delivery-loop/session.local.json"
  jq '.sessionId = ""' "$s" > "$s.new" && mv "$s.new" "$s"
  local out; out="$(stop_hook "$repo" other-session)"
  assert_eq "$out" ""
  assert_file "$s"
  assert_eq "$(jq -r .sessionId "$s")" ""
  assert_eq "$(jq -r .iteration "$s")" "1"
}

test_cancel_emits_run_stopped_and_cleans_snapshots() {
  export TMPDIR; TMPDIR="$(new_tmp_dir tmp)"
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  assert_file "$TMPDIR/loop-virtuoso-snapshots"
  (cd "$repo/src" && bash "$PLUGIN_ROOT/scripts/cancel.sh" >/dev/null)
  assert_no_file "$repo/.delivery-loop/session.local.json"
  local last; last="$(tail -n 1 "$repo/.delivery-loop/events.jsonl")"
  assert_eq "$(echo "$last" | jq -r .event)" "run_stopped"
  assert_eq "$(echo "$last" | jq -r .reason)" "cancelled"
  assert_eq "$(ls "$TMPDIR/loop-virtuoso-snapshots" 2>/dev/null | wc -l | tr -d ' ')" "0"
}

test_cancel_without_a_loop_reports_nothing_active() {
  local repo; repo="$(mk_repo)"
  capture bash "$SCRIPTS/cancel.sh" "$repo"
  assert_eq "$RC" "0"
  assert_contains "$OUT" "No active loop"
}

test_snapshots_are_cleaned_after_mode_a_run() {
  export TMPDIR; TMPDIR="$(new_tmp_dir tmp)"
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  assert_eq "$(ls "$TMPDIR/loop-virtuoso-snapshots" 2>/dev/null | wc -l | tr -d ' ')" "0"
}

test_snapshots_are_cleaned_after_mode_b_run() {
  export TMPDIR; TMPDIR="$(new_tmp_dir tmp)"
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  bash "$SCRIPTS/run-batch.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  assert_eq "$(ls "$TMPDIR/loop-virtuoso-snapshots" 2>/dev/null | wc -l | tr -d ' ')" "0"
}

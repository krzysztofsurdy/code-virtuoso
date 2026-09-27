#!/bin/bash
# Bugs 3 and 6: both modes write progress.log; archiving copies config files
# and follows the documented triggers.

finish_mode_a_run() {
  local repo="$1"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
}

test_mode_a_writes_progress_log() {
  local repo; repo="$(mk_repo)"
  finish_mode_a_run "$repo"
  local log="$repo/.delivery-loop/progress.log"
  assert_file "$log"
  local text; text="$(cat "$log")"
  assert_contains "$text" "run-start"
  assert_contains "$text" "iteration=1"
  assert_contains "$text" "stop reason=complete"
  assert_contains "$text" "run-end reason=complete"
}

test_completed_mode_a_run_gets_archived() {
  local repo; repo="$(mk_repo)"
  finish_mode_a_run "$repo"
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  local archived; archived="$(ls -d "$repo"/.delivery-loop/archive/*-feat-x)"
  assert_file "$archived/backlog.json"
  assert_file "$archived/progress.log"
  assert_file "$archived/events.jsonl"
  assert_no_file "$repo/.delivery-loop/backlog.json"
}

test_mode_b_progress_log_has_same_shape() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  bash "$SCRIPTS/run-batch.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  local text; text="$(cat "$repo/.delivery-loop/progress.log")"
  assert_contains "$text" "run-start"
  assert_contains "$text" "stop reason=complete"
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  ls -d "$repo"/.delivery-loop/archive/*-feat-x >/dev/null
}

test_archive_copies_teams_json() {
  local repo; repo="$(mk_repo)"
  finish_mode_a_run "$repo"
  echo '{"participants":{},"teams":{}}' > "$repo/.delivery-loop/teams.json"
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  local archived; archived="$(ls -d "$repo"/.delivery-loop/archive/*-feat-x)"
  assert_file "$archived/teams.json"
  assert_file "$repo/.delivery-loop/teams.json"
}

pending_run_with_progress() {
  local repo="$1"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  printf 'l1\nl2\nl3\nl4\n' > "$repo/.delivery-loop/progress.log"
}

test_archive_leaves_pending_run_alone_without_branch_change() {
  local repo; repo="$(mk_repo)"
  pending_run_with_progress "$repo"
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" >/dev/null
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" feat/x >/dev/null
  assert_file "$repo/.delivery-loop/backlog.json"
  assert_no_file "$repo/.delivery-loop/archive"
}

test_archive_on_branch_change_with_pending_items() {
  local repo; repo="$(mk_repo)"
  pending_run_with_progress "$repo"
  echo '{"participants":{},"teams":{}}' > "$repo/.delivery-loop/teams.json"
  bash "$SCRIPTS/archive-run.sh" "$repo/.delivery-loop/backlog.json" feat/other >/dev/null
  local archived; archived="$(ls -d "$repo"/.delivery-loop/archive/*-feat-x)"
  assert_file "$archived/backlog.json"
  assert_file "$archived/teams.json"
  assert_file "$repo/.delivery-loop/teams.json"
  assert_no_file "$repo/.delivery-loop/backlog.json"
}

test_start_does_not_archive_or_lose_a_finished_backlog() {
  local repo; repo="$(mk_repo)"
  finish_mode_a_run "$repo"
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "a finished backlog has nothing to run"
  assert_contains "$OUT" "no runnable steps"
  assert_file "$repo/.delivery-loop/backlog.json"
}

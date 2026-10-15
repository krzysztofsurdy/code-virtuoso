#!/bin/bash
# Bug 4: hooks and scripts resolve the loop directory from the git root.

test_start_from_subdirectory_arms_hooks_at_git_root() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  (cd "$repo/src" && bash "$SCRIPTS/setup-start.sh" >/dev/null)
  assert_file "$repo/.code-virtuoso/loop/state/session.local.json"
  assert_no_file "$repo/src/.code-virtuoso"
  local out; out="$(stop_hook "$repo/src")"
  assert_eq "$(decision_of "$out")" "block"
  assert_contains "$out" "ITEM-002"
}

test_start_with_relative_backlog_from_subdirectory() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  (cd "$repo/src" && bash "$SCRIPTS/setup-start.sh" ../.code-virtuoso/loop/backlog.json >/dev/null)
  local out; out="$(stop_hook "$repo/src")"
  assert_contains "$out" "ITEM-002"
}

test_guard_hook_finds_loop_from_subdirectory() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  local out; out="$(guard_hook "$repo/src" Edit file_path "$repo/tests/t.txt")"
  assert_eq "$(deny_of "$out")" "deny"
  out="$(guard_hook "$repo/src" Edit file_path "$repo/src/seed.txt")"
  assert_eq "$out" ""
}

test_hooks_are_noops_outside_a_git_repo() {
  local dir; dir="$(new_tmp_dir plain)"
  assert_eq "$(stop_hook "$dir")" ""
  assert_eq "$(guard_hook "$dir" Edit file_path "$dir/x")" ""
}

test_status_default_path_from_subdirectory() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  local out; out="$(cd "$repo/src" && bash "$SCRIPTS/status.sh")"
  assert_contains "$out" "Mode A loop: ACTIVE"
}

test_backlog_outside_loop_dir_is_refused() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  mkdir -p "$repo/elsewhere"
  cp "$repo/.code-virtuoso/loop/backlog.json" "$repo/elsewhere/backlog.json"
  capture start_loop "$repo" elsewhere/backlog.json
  [[ $RC -ne 0 ]] || die "backlog must live in <git root>/.code-virtuoso/loop"
  assert_contains "$OUT" ".code-virtuoso/loop"
}

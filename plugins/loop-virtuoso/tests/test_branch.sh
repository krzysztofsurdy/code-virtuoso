#!/bin/bash
# Bug 2: the loop must run on backlog.branch and never on the default branch.

test_setup_refuses_when_backlog_branch_is_default() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" main
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "must refuse to run on main"
  assert_contains "$OUT" "default branch"
  assert_no_file "$repo/.code-virtuoso/loop/state/session.local.json"
}

test_setup_switches_to_backlog_branch_when_clean() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" "feat/x"
  assert_file "$repo/.code-virtuoso/loop/state/session.local.json"
}

test_setup_switches_to_existing_branch() {
  local repo; repo="$(mk_repo)"
  git -C "$repo" branch feat/x
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" "feat/x"
}

test_setup_accepts_already_on_branch() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" "feat/x"
}

test_setup_refuses_to_switch_with_dirty_tree() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  echo "edit" >> "$repo/src/seed.txt"
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "must refuse"
  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" "main"
}

test_setup_refuses_origin_default_branch_name() {
  local repo; repo="$(mk_repo)"
  git -C "$repo" branch -m main trunk
  git -C "$repo" update-ref refs/remotes/origin/trunk HEAD
  git -C "$repo" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
  write_backlog "$repo" trunk
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "must refuse the origin default branch"
}

test_batch_refuses_default_branch() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" main
  capture bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json"
  [[ $RC -ne 0 ]] || die "batch must refuse main"
  assert_contains "$OUT" "default branch"
  assert_eq "$(wc -c < "$FAKE_CLAUDE_LOG" | tr -d ' ')" "0" "claude must not be called"
}

test_batch_switches_to_backlog_branch() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  bash "$SCRIPTS/run-batch.sh" "$repo/.code-virtuoso/loop/backlog.json" >/dev/null
  assert_eq "$(git -C "$repo" symbolic-ref --short HEAD)" "feat/x"
}

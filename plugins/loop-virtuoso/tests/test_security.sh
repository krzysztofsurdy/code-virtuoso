#!/bin/bash
# Bug 1: the loop must never commit files it was not allowed to touch, and
# must not bypass commit hooks.

test_untracked_env_blocks_start_and_is_never_committed() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  echo "SECRET=1" > "$repo/.env"
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "start must refuse a tree with untracked files"
  assert_contains "$OUT" "commit or stash"
  assert_contains "$OUT" ".env"
  assert_not_contains "$(all_commit_files "$repo")" ".env"
  assert_file "$repo/.env"
  assert_no_file "$repo/.delivery-loop/session.local.json"
}

test_modified_tracked_file_blocks_start() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  echo "edit" >> "$repo/src/seed.txt"
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "start must refuse a tree with modified files"
  assert_contains "$OUT" "commit or stash"
  assert_eq "$(git -C "$repo" log --oneline | wc -l | tr -d ' ')" "1" "no extra commit"
}

test_worker_created_env_is_never_committed() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  echo "SECRET=1" > "$repo/.env"
  echo "hi" > "$repo/src/new.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(step_actions "$repo" | head -1)" "violation"
  assert_not_contains "$(all_commit_files "$repo")" ".env"
  assert_no_file "$repo/.env"
}

test_new_files_outside_allowed_paths_are_never_committed() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x true '{"allowedPaths":["src/**"]}'
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  echo "b" > "$repo/docs-b.md"
  stop_hook "$repo" >/dev/null
  assert_eq "$(step_actions "$repo" | head -1)" "violation"
  assert_no_file "$repo/docs-b.md"
  stop_hook "$repo" >/dev/null
  assert_eq "$(step_actions "$repo" | sed -n 2p)" "verified"
  local files; files="$(all_commit_files "$repo")"
  assert_contains "$files" "src/a.txt"
  assert_not_contains "$files" "docs-b.md"
}

test_checkpoint_runs_commit_hooks() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  export MARK="$WORK/hook-marker.$$"
  printf '#!/bin/sh\necho ran >> "%s"\n' "$MARK" > "$repo/.git/hooks/pre-commit"
  chmod +x "$repo/.git/hooks/pre-commit"
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_file "$MARK"
  assert_contains "$(all_commit_files "$repo")" "src/a.txt"
}

test_rejecting_commit_hook_is_respected() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  printf '#!/bin/sh\nexit 1\n' > "$repo/.git/hooks/pre-commit"
  chmod +x "$repo/.git/hooks/pre-commit"
  start_loop "$repo" >/dev/null
  local before; before="$(git -C "$repo" rev-parse HEAD)"
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(git -C "$repo" rev-parse HEAD)" "$before" "a rejected commit must not be forced"
}

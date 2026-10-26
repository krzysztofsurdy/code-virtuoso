#!/bin/bash
# statusline.sh: one line from the Claude Code statusline JSON, never an error.

statusline() { RC=0; OUT="$(printf '%s' "$1" | bash "$SCRIPTS/statusline.sh" 2>&1)" || RC=$?; }

full_input() {
  jq -nc --arg dir "$1" '{
    cwd: $dir, session_id: "s1",
    model: {id: "claude-opus-5-5", display_name: "Opus"},
    workspace: {current_dir: $dir, project_dir: $dir},
    cost: {total_cost_usd: 1.5},
    context_window: {used_percentage: 8.7}
  }'
}

test_statusline_full_input_outside_a_repo() {
  local dir; dir="$(new_tmp_dir plain)"
  statusline "$(full_input "$dir")"
  assert_eq "$RC" "0"
  assert_eq "$OUT" "$(basename "$dir") | Opus | \$1.50 | ctx 8%"
}

test_statusline_shows_the_git_branch() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo" feat/x
  statusline "$(full_input "$repo/src")"
  assert_eq "$OUT" "src | feat/x | Opus | \$1.50 | ctx 8%"
}

test_statusline_omits_missing_fields() {
  statusline '{}'
  assert_eq "$RC" "0"
  assert_eq "$OUT" ""
  statusline '{"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":null}}'
  assert_eq "$OUT" "Sonnet"
  statusline 'not json'
  assert_eq "$RC" "0"
  assert_eq "$OUT" ""
}

test_statusline_shows_loop_progress_when_a_session_is_active() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  mkdir -p "$repo/.code-virtuoso/loop/state"
  jq -n --arg b "$repo/.code-virtuoso/loop/backlog.json" '{active: true, iteration: 3, backlogFile: $b}' \
    > "$repo/.code-virtuoso/loop/state/session.local.json"
  statusline "$(full_input "$repo")"
  assert_contains "$OUT" " | loop 3/10"
  jq '.active = false' "$repo/.code-virtuoso/loop/state/session.local.json" > "$WORK/s.json"
  mv "$WORK/s.json" "$repo/.code-virtuoso/loop/state/session.local.json"
  statusline "$(full_input "$repo")"
  assert_not_contains "$OUT" "loop"
}

test_statusline_loop_max_falls_back_to_config_then_default() {
  local repo backlog; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  backlog="$repo/.code-virtuoso/loop/backlog.json"
  jq 'del(.config.maxIterations)' "$backlog" > "$WORK/b.json" && mv "$WORK/b.json" "$backlog"
  mkdir -p "$repo/.code-virtuoso/loop/state"
  jq -n --arg b "$backlog" '{active: true, iteration: 2, backlogFile: $b}' \
    > "$repo/.code-virtuoso/loop/state/session.local.json"
  statusline "$(full_input "$repo")"
  assert_contains "$OUT" "loop 2/30"
  mkdir -p "$HOME/.config/code-virtuoso"
  echo '{"loop":{"maxIterations":12}}' > "$HOME/.config/code-virtuoso/config.json"
  statusline "$(full_input "$repo")"
  assert_contains "$OUT" "loop 2/12"
  echo '{"loop":{"maxIterations":7}}' > "$repo/.code-virtuoso/config.json"
  statusline "$(full_input "$repo")"
  assert_contains "$OUT" "loop 2/7"
}

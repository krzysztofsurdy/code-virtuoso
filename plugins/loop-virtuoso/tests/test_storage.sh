#!/bin/bash
# Storage convention (spec/config-spec.md): plan under .code-virtuoso/loop,
# run state under loop/state, .gitignore, legacy migration, user layer paths.

run_mode_a_to_completion() {
  local repo="$1"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
}

test_plan_file_is_unchanged_after_a_mode_a_run() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  local plan; plan="$(loop_dir "$repo")/backlog.json"
  cp "$plan" "$WORK/plan.before"
  start_loop "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  stop_hook "$repo" >/dev/null
  cmp -s "$plan" "$WORK/plan.before" || die "backlog.json changed during the run"
}

test_plan_file_is_unchanged_after_a_mode_b_run() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  local plan; plan="$(loop_dir "$repo")/backlog.json"
  cp "$plan" "$WORK/plan.before"
  bash "$SCRIPTS/run-batch.sh" "$plan" >/dev/null
  cmp -s "$plan" "$WORK/plan.before" || die "backlog.json changed during the run"
}

test_run_state_is_written_under_loop_state() {
  local repo; repo="$(mk_repo)"
  run_mode_a_to_completion "$repo"
  local state_dir; state_dir="$(loop_dir "$repo")/state"
  assert_file "$state_dir/state.json"
  assert_file "$state_dir/events.jsonl"
  assert_file "$state_dir/progress.log"
  assert_eq "$(jq -r '.items["ITEM-001"].s1.status' "$state_dir/state.json")" "verified"
  assert_eq "$(jq -r '.items["ITEM-002"].s1.status' "$state_dir/state.json")" "verified"
  assert_no_file "$(loop_dir "$repo")/events.jsonl"
  assert_no_file "$(loop_dir "$repo")/progress.log"
}

test_failed_step_state_carries_attempts_and_notes() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x "echo nope; exit 1"
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  local state="$(loop_dir "$repo")/state/state.json"
  assert_eq "$(jq -r '.items["ITEM-001"].s1.attempts' "$state")" "1"
  assert_contains "$(jq -r '.items["ITEM-001"].s1.notes' "$state")" "nope"
  assert_eq "$(jq -r '.items["ITEM-001"].s1.status // "pending"' "$state")" "pending"
}

test_gitignore_is_created_with_the_spec_lines() {
  local repo; repo="$(mk_repo)"
  run_mode_a_to_completion "$repo"
  local ignore="$repo/.code-virtuoso/.gitignore"
  assert_file "$ignore"
  grep -qxF '*.local.json' "$ignore" || die "missing *.local.json"
  grep -qxF 'loop/state/' "$ignore" || die "missing loop/state/"
  assert_eq "$(git -C "$repo" status --porcelain --untracked-files=all -- .code-virtuoso/loop/state | wc -l | tr -d ' ')" "0" "state must be ignored"
}

test_existing_gitignore_is_appended_not_overwritten() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  printf 'custom-entry\n*.local.json' > "$repo/.code-virtuoso/.gitignore"
  start_loop "$repo" >/dev/null
  local ignore="$repo/.code-virtuoso/.gitignore"
  grep -qxF 'custom-entry' "$ignore" || die "custom entry lost"
  assert_eq "$(grep -cxF '*.local.json' "$ignore")" "1" "no duplicate line"
  assert_eq "$(grep -cxF 'loop/state/' "$ignore")" "1" "missing line appended once"
  stop_hook "$repo" >/dev/null
  assert_eq "$(grep -cxF 'loop/state/' "$ignore")" "1" "idempotent"
}

write_legacy_loop() {
  local repo="$1" d="$1/.delivery-loop"
  mkdir -p "$d/archive/2026-01-01-old"
  jq -n '{
    project: "t", branch: "feat/x", description: "d",
    config: {maxIterations: 10, maxAttemptsPerItem: 3, maxStallIterations: 3, maxViolations: 3,
             permissionMode: "acceptEdits", protectedPaths: ["tests/**"], allowedTools: ["Read"]},
    items: [
      {id: "ITEM-001", title: "one", description: "d", acceptanceCriteria: ["a"], priority: 1,
       steps: [{id: "s1", instructions: "do it", verifyCommand: "true", status: "verified", attempts: 1, notes: "x"}]},
      {id: "ITEM-002", title: "two", description: "d", acceptanceCriteria: ["a"], priority: 2,
       steps: [{id: "s1", instructions: "do it", verifyCommand: "true", status: "pending", attempts: 2, notes: "boom"}]}
    ]}' > "$d/backlog.json"
  echo '{"participants":{"p":{"kind":"persona","systemPrompt":"x"}},"teams":{"t":{"members":["p"]}}}' > "$d/teams.json"
  printf 'l1\nl2\n' > "$d/progress.log"
  echo '{"event":"run_started"}' > "$d/events.jsonl"
  echo '{"active":true}' > "$d/session.local.json"
  echo '{}' > "$d/archive/2026-01-01-old/backlog.json"
  echo '.delivery-loop' >> "$repo/.git/info/exclude"
}

test_migration_moves_delivery_loop_and_splits_plan_from_state() {
  local repo; repo="$(mk_repo)"
  write_legacy_loop "$repo"
  start_loop "$repo" > "$WORK/out.txt"
  local out; out="$(cat "$WORK/out.txt")"
  local l; l="$(loop_dir "$repo")"
  assert_no_file "$repo/.delivery-loop"
  assert_contains "$out" ".delivery-loop"
  assert_contains "$out" ".git/info/exclude"
  assert_file "$l/backlog.json"
  assert_eq "$(jq '[.items[].steps[] | has("status") or has("attempts") or has("notes")] | any' "$l/backlog.json")" "false" "plan has no run state"
  assert_eq "$(jq -r '.items["ITEM-001"].s1.status' "$l/state/state.json")" "verified"
  assert_eq "$(jq -r '.items["ITEM-002"].s1.attempts' "$l/state/state.json")" "2"
  assert_eq "$(jq -r '.items["ITEM-002"].s1.notes' "$l/state/state.json")" "boom"
  assert_file "$l/pipelines.json"
  assert_eq "$(jq -r '.pipelines | keys[0]' "$l/pipelines.json")" "t"
  assert_eq "$(jq -r 'has("teams")' "$l/pipelines.json")" "false"
  assert_file "$l/archive/2026-01-01-old/backlog.json"
  assert_contains "$(cat "$l/state/events.jsonl")" "run_started"
  assert_eq "$(jq -r .currentItemId "$l/state/session.local.json")" "ITEM-002" "resumes after the verified item"
  assert_eq "$(jq -r .active "$l/state/session.local.json")" "true"
}

test_migration_without_exclude_line_prints_no_exclude_hint() {
  local repo; repo="$(mk_repo)"
  write_legacy_loop "$repo"
  : > "$repo/.git/info/exclude"
  capture start_loop "$repo"
  assert_eq "$RC" "0"
  assert_not_contains "$OUT" "info/exclude"
}

test_migration_refuses_when_both_layouts_have_a_backlog() {
  local repo; repo="$(mk_repo)"
  write_legacy_loop "$repo"
  write_backlog "$repo" feat/x
  capture start_loop "$repo"
  [[ $RC -ne 0 ]] || die "must not guess which backlog wins"
  assert_contains "$OUT" ".delivery-loop"
  assert_file "$repo/.delivery-loop/backlog.json"
}

test_migration_accepts_the_old_backlog_path_argument() {
  local repo; repo="$(mk_repo)"
  write_legacy_loop "$repo"
  start_loop "$repo" .delivery-loop/backlog.json >/dev/null
  assert_file "$(loop_dir "$repo")/state/session.local.json"
}

test_migration_is_a_noop_without_a_legacy_dir() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  capture start_loop "$repo"
  assert_eq "$RC" "0"
  assert_not_contains "$OUT" "migrat"
}

test_user_pipelines_migrated_from_legacy_global_teams() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  mkdir -p "$HOME/.claude/loop-virtuoso"
  echo '{"participants":{"g":{"kind":"persona","systemPrompt":"global role"}},"teams":{"gt":{"members":["g"]}}}' \
    > "$HOME/.claude/loop-virtuoso/teams.json"
  capture start_loop "$repo"
  assert_eq "$RC" "0"
  local dest="$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json"
  assert_file "$dest"
  assert_contains "$OUT" "$dest"
  assert_eq "$(jq -r '.pipelines.gt.members[0]' "$dest")" "g"
  assert_eq "$(jq -r 'has("teams")' "$dest")" "false"
  assert_file "$HOME/.claude/loop-virtuoso/teams.json"
}

test_user_pipelines_not_overwritten_by_migration() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  mkdir -p "$HOME/.claude/loop-virtuoso" "$XDG_CONFIG_HOME/code-virtuoso/loop"
  echo '{"participants":{},"teams":{"old":{}}}' > "$HOME/.claude/loop-virtuoso/teams.json"
  echo '{"participants":{},"pipelines":{"mine":{}}}' > "$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json"
  start_loop "$repo" >/dev/null
  assert_eq "$(jq -r '.pipelines | keys[0]' "$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json")" "mine"
}

persona_backlog() {
  local repo="$1" participant="$2"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  local f; f="$(loop_dir "$repo")/backlog.json"
  jq --arg p "$participant" '.items[0].steps[0].participant = $p' "$f" > "$f.new" && mv "$f.new" "$f"
}

test_user_pipelines_path_resolves_participants() {
  local repo; repo="$(mk_repo)"
  persona_backlog "$repo" reviewer-role
  mkdir -p "$XDG_CONFIG_HOME/code-virtuoso/loop"
  echo '{"participants":{"reviewer-role":{"kind":"persona","systemPrompt":"USER LAYER ROLE"}}}' \
    > "$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json"
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" "USER LAYER ROLE"
}

test_code_virtuoso_config_home_overrides_xdg_for_pipelines() {
  local repo; repo="$(mk_repo)"
  persona_backlog "$repo" reviewer-role
  export CODE_VIRTUOSO_CONFIG_HOME; CODE_VIRTUOSO_CONFIG_HOME="$(new_tmp_dir cvhome)"
  mkdir -p "$CODE_VIRTUOSO_CONFIG_HOME/loop" "$XDG_CONFIG_HOME/code-virtuoso/loop"
  echo '{"participants":{"reviewer-role":{"kind":"persona","systemPrompt":"FROM CV HOME"}}}' \
    > "$CODE_VIRTUOSO_CONFIG_HOME/loop/pipelines.json"
  echo '{"participants":{"reviewer-role":{"kind":"persona","systemPrompt":"FROM XDG"}}}' \
    > "$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json"
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" "FROM CV HOME"
  assert_not_contains "$out" "FROM XDG"
}

test_project_pipelines_override_user_pipelines_by_name() {
  local repo; repo="$(mk_repo)"
  persona_backlog "$repo" reviewer-role
  mkdir -p "$XDG_CONFIG_HOME/code-virtuoso/loop"
  echo '{"participants":{"reviewer-role":{"kind":"persona","systemPrompt":"USER VERSION"}}}' \
    > "$XDG_CONFIG_HOME/code-virtuoso/loop/pipelines.json"
  echo '{"participants":{"reviewer-role":{"kind":"persona","systemPrompt":"PROJECT VERSION"}}}' \
    > "$(loop_dir "$repo")/pipelines.json"
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" "PROJECT VERSION"
  assert_not_contains "$out" "USER VERSION"
}

install_fake_agents_plugin() {
  local root="$HOME/.claude/plugins/cache/code-virtuoso/agents-virtuoso/abc123"
  mkdir -p "$root/agents" "$HOME/.claude/plugins"
  : > "$root/agents/reviewer.md"
  jq -n --arg p "$root" '{version: 2, plugins: {"agents-virtuoso@code-virtuoso": [{scope: "user", installPath: $p}]}}' \
    > "$HOME/.claude/plugins/installed_plugins.json"
}

agent_backlog() {
  local repo="$1" agent="$2"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  echo "{\"participants\":{\"w\":{\"kind\":\"agent\",\"agent\":\"$agent\"}}}" > "$(loop_dir "$repo")/pipelines.json"
  local f; f="$(loop_dir "$repo")/backlog.json"
  jq '.items[0].steps[0].participant = "w"' "$f" > "$f.new" && mv "$f.new" "$f"
}

test_bare_agent_name_resolves_to_scoped_agents_virtuoso_name() {
  local repo; repo="$(mk_repo)"
  install_fake_agents_plugin
  agent_backlog "$repo" reviewer
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" 'delegate to the `agents-virtuoso:reviewer` subagent'
}

test_bare_agent_name_resolves_in_mode_b_cli_flag() {
  local repo; repo="$(mk_repo)"
  install_fake_agents_plugin
  install_fake_claude
  agent_backlog "$repo" reviewer
  bash "$SCRIPTS/run-batch.sh" "$(loop_dir "$repo")/backlog.json" >/dev/null
  assert_contains "$(cat "$FAKE_CLAUDE_LOG")" "--agent agents-virtuoso:reviewer"
}

test_unknown_bare_agent_name_is_kept_as_is() {
  local repo; repo="$(mk_repo)"
  install_fake_agents_plugin
  agent_backlog "$repo" ghost
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" 'delegate to the `ghost` subagent'
}

test_scoped_agent_name_is_used_unchanged() {
  local repo; repo="$(mk_repo)"
  install_fake_agents_plugin
  agent_backlog "$repo" other-plugin:reviewer
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" 'delegate to the `other-plugin:reviewer` subagent'
}

test_bare_agent_name_without_installed_plugin_is_kept() {
  local repo; repo="$(mk_repo)"
  agent_backlog "$repo" reviewer
  local out; out="$(start_loop "$repo")"
  assert_contains "$out" 'delegate to the `reviewer` subagent'
}

write_config() { # <repo> <json>
  mkdir -p "$1/.code-virtuoso"
  echo "$2" > "$1/.code-virtuoso/config.json"
}

checkpoint_subject() { git -C "$1" log -1 --pretty=%s; }

test_checkpoint_commit_follows_ticket_delivery_commit_format() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo" feat/PROJ-123_add_x
  write_backlog "$repo" feat/PROJ-123_add_x
  write_config "$repo" '{"version":1,"ticket-delivery":{"ticketIdPattern":"PROJ-\\d+","commitFormat":"{ticket}: {summary}"}}'
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(checkpoint_subject "$repo")" "PROJ-123: one (ITEM-001/s1)"
}

test_checkpoint_commit_falls_back_without_config() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(checkpoint_subject "$repo")" "loop-virtuoso: ITEM-001/s1"
}

test_checkpoint_commit_falls_back_when_ticket_cannot_be_resolved() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1,"ticket-delivery":{"ticketIdPattern":"PROJ-\\d+","commitFormat":"{ticket}: {summary}"}}'
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(checkpoint_subject "$repo")" "loop-virtuoso: ITEM-001/s1"
}

test_checkpoint_commit_format_without_ticket_placeholder() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1,"ticket-delivery":{"commitFormat":"chore: {summary}"}}'
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(checkpoint_subject "$repo")" "chore: one (ITEM-001/s1)"
}

test_local_config_overrides_shared_commit_format() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1,"ticket-delivery":{"commitFormat":"shared: {summary}"}}'
  echo '{"version":1,"ticket-delivery":{"commitFormat":"local: {summary}"}}' > "$repo/.code-virtuoso/config.local.json"
  start_loop "$repo" >/dev/null
  echo "a" > "$repo/src/a.txt"
  stop_hook "$repo" >/dev/null
  assert_eq "$(checkpoint_subject "$repo")" "local: one (ITEM-001/s1)"
}

test_loop_namespace_supplies_defaults_the_backlog_omits() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  local f; f="$(loop_dir "$repo")/backlog.json"
  jq 'del(.config.permissionMode, .config.maxIterations)' "$f" > "$f.new" && mv "$f.new" "$f"
  write_config "$repo" '{"version":1,"loop":{"permissionMode":"plan","maxIterations":10}}'
  echo '{"version":1,"loop":{"permissionMode":"dontAsk"}}' > "$repo/.code-virtuoso/config.local.json"
  bash "$SCRIPTS/run-batch.sh" "$f" >/dev/null
  assert_contains "$(cat "$FAKE_CLAUDE_LOG")" "--permission-mode dontAsk"
}

test_backlog_config_beats_loop_namespace() {
  local repo; repo="$(mk_repo)"
  install_fake_claude
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1,"loop":{"permissionMode":"plan"}}'
  bash "$SCRIPTS/run-batch.sh" "$(loop_dir "$repo")/backlog.json" >/dev/null
  assert_contains "$(cat "$FAKE_CLAUDE_LOG")" "--permission-mode acceptEdits"
}

test_loop_namespace_protected_paths_are_combined_with_the_backlog() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1,"loop":{"protectedPaths":["docs/**"]}}'
  start_loop "$repo" >/dev/null
  assert_eq "$(deny_of "$(guard_hook "$repo" Edit file_path "$repo/docs/a.md")")" "deny"
  assert_eq "$(deny_of "$(guard_hook "$repo" Edit file_path "$repo/tests/t.txt")")" "deny"
  assert_eq "$(guard_hook "$repo" Edit file_path "$repo/src/seed.txt")" ""
}

test_guard_protects_the_code_virtuoso_directory() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  start_loop "$repo" >/dev/null
  assert_eq "$(deny_of "$(guard_hook "$repo" Write file_path "$repo/.code-virtuoso/config.json")")" "deny"
  assert_eq "$(deny_of "$(guard_hook "$repo" Edit file_path "$repo/.code-virtuoso/loop/backlog.json")")" "deny"
  assert_eq "$(deny_of "$(guard_hook "$repo" Edit file_path "$repo/.code-virtuoso/loop/state/state.json")")" "deny"
}

test_tampering_with_shared_config_is_restored_and_flagged() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  write_config "$repo" '{"version":1}'
  source "$SCRIPTS/lib/verify-gate.sh"
  local b; b="$(loop_dir "$repo")/backlog.json"
  verify_gate_snapshot_all "$b"
  echo '{"version":1,"loop":{"maxIterations":999}}' > "$repo/.code-virtuoso/config.json"
  local v; v="$(verify_gate_run "$b" ITEM-001 s1 "$(git -C "$repo" rev-parse HEAD)")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "violation"
  assert_eq "$(jq -c . "$repo/.code-virtuoso/config.json")" '{"version":1}'
}

test_config_file_created_during_a_step_is_removed_and_flagged() {
  local repo; repo="$(mk_repo)"
  on_feature "$repo"
  write_backlog "$repo" feat/x
  source "$SCRIPTS/lib/verify-gate.sh"
  local b; b="$(loop_dir "$repo")/backlog.json"
  verify_gate_snapshot_all "$b"
  echo '{"version":1,"loop":{"maxIterations":999}}' > "$repo/.code-virtuoso/config.local.json"
  local v; v="$(verify_gate_run "$b" ITEM-001 s1 "$(git -C "$repo" rev-parse HEAD)")"
  assert_eq "$(echo "$v" | jq -r .verdict)" "violation"
  assert_no_file "$repo/.code-virtuoso/config.local.json"
}

test_branch_name_follows_ticket_delivery_branch_pattern() {
  local repo; repo="$(mk_repo)"
  write_config "$repo" '{"version":1,"ticket-delivery":{"branchPattern":"feat/{ticket}_{slug}"}}'
  local out; out="$(cd "$repo" && bash "$SCRIPTS/branch-name.sh" --ticket PROJ-123 "Add status column to tasks!")"
  assert_eq "$out" "feat/PROJ-123_add_status_column_to_tasks"
}

test_branch_name_defaults_without_config() {
  local repo; repo="$(mk_repo)"
  local out; out="$(cd "$repo" && bash "$SCRIPTS/branch-name.sh" "Add status column")"
  assert_eq "$out" "feat/add_status_column"
}

test_branch_name_requires_a_ticket_when_the_pattern_uses_one() {
  local repo; repo="$(mk_repo)"
  write_config "$repo" '{"version":1,"ticket-delivery":{"branchPattern":"feat/{ticket}_{slug}"}}'
  capture bash -c "cd '$repo' && bash '$SCRIPTS/branch-name.sh' 'Add status column'"
  [[ $RC -ne 0 ]] || die "a ticket is required"
  assert_contains "$OUT" "ticket"
}

test_validator_accepts_a_plan_without_step_state() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  capture bash "$SCRIPTS/validate-backlog.sh" "$(loop_dir "$repo")/backlog.json"
  assert_eq "$RC" "0"
  assert_not_contains "$OUT" "Warnings"
}

test_validator_warns_about_run_state_inside_the_plan() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  local f; f="$(loop_dir "$repo")/backlog.json"
  jq '.items[0].steps[0].status = "verified"' "$f" > "$f.new" && mv "$f.new" "$f"
  capture bash "$SCRIPTS/validate-backlog.sh" "$f"
  assert_eq "$RC" "0"
  assert_contains "$OUT" "state.json"
}

test_validator_rejects_an_unparseable_config_layer() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  echo '{broken' > "$repo/.code-virtuoso/config.json"
  capture bash "$SCRIPTS/validate-backlog.sh" "$(loop_dir "$repo")/backlog.json"
  [[ $RC -ne 0 ]] || die "unparseable config must fail validation"
  assert_contains "$OUT" "config.json"
}

test_status_points_at_a_legacy_directory() {
  local repo; repo="$(mk_repo)"
  write_legacy_loop "$repo"
  capture bash -c "cd '$repo' && bash '$SCRIPTS/status.sh'"
  [[ $RC -ne 0 ]] || die "nothing at the new path yet"
  assert_contains "$OUT" "/loop-virtuoso:start"
  assert_file "$repo/.delivery-loop/backlog.json"
}

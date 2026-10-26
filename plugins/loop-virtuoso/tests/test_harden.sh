#!/bin/bash
# /loop-virtuoso:harden: dry run by default, additive merge, backups, idempotent apply.

user_settings() { echo "$HOME/.claude/settings.json"; }
user_config() { echo "$HOME/.config/code-virtuoso/config.json"; }
harden() { capture bash "$SCRIPTS/harden.sh" "$@"; }
backups_of() { ls "$1".bak.* 2>/dev/null | wc -l | tr -d ' '; }

test_harden_dry_run_prints_diff_and_writes_nothing() {
  harden
  assert_eq "$RC" "0" "dry run rc"
  assert_contains "$OUT" "+++"
  assert_contains "$OUT" '"attribution"'
  assert_contains "$OUT" '"blockSecrets": true'
  assert_contains "$OUT" "--apply"
  assert_no_file "$(user_settings)"
  assert_no_file "$(user_config)"
}

test_harden_apply_writes_baseline_and_guard_config() {
  harden --apply
  assert_eq "$RC" "0" "apply rc: $OUT"
  local s c
  s="$(user_settings)"; c="$(user_config)"
  assert_eq "$(jq -c '.attribution' "$s")" '{"commit":"","pr":""}'
  assert_eq "$(jq -r '.permissions.deny | index("Read(./.env)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.deny | index("Read(~/.ssh/**)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(git push *)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(git reset --hard *)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(composer update *)") != null' "$s")" "true"
  assert_eq "$(jq -c '.loop.guard' "$c")" '{"blockSecrets":true,"protectTests":"ask"}'
  assert_eq "$(jq -r 'has("statusLine") or has("env") or has("sandbox")' "$s")" "false"
  assert_eq "$(backups_of "$s")" "0" "a new file needs no backup"
}

test_harden_keeps_existing_values_and_unions_arrays() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"model":"opus","attribution":{"commit":"Mine"},"permissions":{"allow":["Bash(make *)"],"deny":["Bash(rm *)","Read(~/.ssh/**)"]}}' > "$s"
  local before; before="$(cat "$s")"
  harden --apply
  assert_eq "$RC" "0" "apply rc: $OUT"
  assert_eq "$(jq -r '.model' "$s")" "opus"
  assert_eq "$(jq -c '.permissions.allow' "$s")" '["Bash(make *)"]'
  assert_eq "$(jq -r '.permissions.deny[0]' "$s")" "Bash(rm *)"
  assert_eq "$(jq -r '.permissions.deny[1]' "$s")" "Read(~/.ssh/**)"
  assert_eq "$(jq -r '[.permissions.deny[] | select(. == "Read(~/.ssh/**)")] | length' "$s")" "1"
  assert_eq "$(jq -r '.permissions.deny | index("Read(./.env)") != null' "$s")" "true"
  assert_eq "$(jq -r '.attribution.commit' "$s")" "Mine"
  assert_eq "$(jq -r '.attribution.pr' "$s")" ""
  assert_contains "$OUT" "attribution.commit"
  assert_eq "$(backups_of "$s")" "1"
  assert_eq "$(cat "$s".bak.*)" "$before"
}

test_harden_keeps_a_user_scalar_where_the_baseline_has_an_object() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"attribution":false}' > "$s"
  harden --apply
  assert_eq "$(jq -c '.attribution' "$s")" "false"
  assert_contains "$OUT" "note:"
}

test_harden_second_apply_is_a_no_op() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"model":"opus"}' > "$s"
  harden --apply
  local after; after="$(cat "$s")"
  harden --apply
  assert_eq "$RC" "0"
  assert_contains "$OUT" "no change"
  assert_eq "$(cat "$s")" "$after"
  assert_eq "$(backups_of "$s")" "1"
  assert_eq "$(backups_of "$(user_config)")" "0"
  harden
  assert_not_contains "$OUT" "+++"
}

test_harden_follows_claude_config_dir() {
  export CLAUDE_CONFIG_DIR="$HOME/alt-claude"
  harden --apply
  assert_file "$HOME/alt-claude/settings.json"
  assert_no_file "$(user_settings)"
}

test_harden_keeps_existing_guard_config() {
  local c; c="$(user_config)"
  mkdir -p "$(dirname "$c")"
  echo '{"loop":{"maxIterations":5,"guard":{"protectTests":"deny"}}}' > "$c"
  harden --apply
  assert_eq "$(jq -c '.loop' "$c")" '{"maxIterations":5,"guard":{"protectTests":"deny","blockSecrets":true}}'
  assert_contains "$OUT" "loop.guard.protectTests"
  assert_eq "$(backups_of "$c")" "1"
}

test_harden_project_scope_writes_into_the_repo() {
  local repo; repo="$(mk_repo)"
  (cd "$repo/src" && bash "$SCRIPTS/harden.sh" --scope project --apply) > /dev/null
  assert_file "$repo/.claude/settings.json"
  assert_eq "$(jq -c '.loop.guard' "$repo/.code-virtuoso/config.json")" '{"blockSecrets":true,"protectTests":"ask"}'
  assert_no_file "$(user_settings)"
  assert_no_file "$(user_config)"
}

test_harden_project_scope_needs_a_repo() {
  local dir; dir="$(new_tmp_dir plain)"
  RC=0; OUT="$(cd "$dir" && bash "$SCRIPTS/harden.sh" --scope project 2>&1)" || RC=$?
  assert_eq "$RC" "1"
  assert_contains "$OUT" "git repository"
}

test_harden_rejects_invalid_settings_json() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{nope' > "$s"
  harden --apply
  assert_eq "$RC" "1"
  assert_contains "$OUT" "$s"
  assert_eq "$(cat "$s")" "{nope"
}

test_harden_rejects_unknown_options() {
  harden --with nonsense
  assert_eq "$RC" "1"
  assert_contains "$OUT" "nonsense"
  harden --scope global
  assert_eq "$RC" "1"
}

test_harden_with_sandbox() {
  harden --apply --with sandbox
  local s; s="$(user_settings)"
  assert_eq "$(jq -r '.sandbox.enabled' "$s")" "true"
  assert_eq "$(jq -r '.sandbox.allowUnsandboxedCommands' "$s")" "false"
  assert_eq "$(jq -c '.sandbox.network.allowedDomains' "$s")" '["github.com"]'
  assert_eq "$(jq -c '.sandbox.filesystem.denyRead' "$s")" '["~/.ssh","~/.aws"]'
}

test_harden_with_telemetry_keeps_existing_env() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"env":{"FOO":"bar","OTEL_METRICS_EXPORTER":"otlp"}}' > "$s"
  harden --apply --with telemetry
  assert_eq "$(jq -r '.env.CLAUDE_CODE_ENABLE_TELEMETRY' "$s")" "1"
  assert_eq "$(jq -r '.env.OTEL_LOGS_EXPORTER' "$s")" "console"
  assert_eq "$(jq -r '.env.OTEL_METRICS_EXPORTER' "$s")" "otlp"
  assert_eq "$(jq -r '.env.FOO' "$s")" "bar"
}

test_harden_user_only_flags_refuse_project_scope() {
  local repo; repo="$(mk_repo)"
  RC=0; OUT="$(cd "$repo" && bash "$SCRIPTS/harden.sh" --scope project --with telemetry 2>&1)" || RC=$?
  assert_eq "$RC" "1"
  assert_contains "$OUT" "--scope user"
  RC=0; OUT="$(cd "$repo" && bash "$SCRIPTS/harden.sh" --scope project --with statusline 2>&1)" || RC=$?
  assert_eq "$RC" "1"
  assert_no_file "$repo/.claude/settings.json"
}

test_harden_with_statusline_installs_a_stable_copy() {
  harden --with statusline,sandbox
  assert_contains "$OUT" "statusline.sh"
  assert_no_file "$HOME/.config/code-virtuoso/statusline.sh"
  harden --apply --with statusline,sandbox
  local copy="$HOME/.config/code-virtuoso/statusline.sh"
  assert_file "$copy"
  [[ -x "$copy" ]] || die "statusline copy not executable"
  cmp -s "$copy" "$SCRIPTS/statusline.sh" || die "statusline copy differs"
  assert_eq "$(jq -c '.statusLine' "$(user_settings)")" "{\"type\":\"command\",\"command\":\"$copy\"}"
  harden --apply --with statusline,sandbox
  assert_contains "$OUT" "no change"
}

test_harden_with_statusline_leaves_an_existing_one() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"statusLine":{"type":"command","command":"/mine.sh"}}' > "$s"
  harden --apply --with statusline
  assert_eq "$(jq -r '.statusLine.command' "$s")" "/mine.sh"
  assert_no_file "$HOME/.config/code-virtuoso/statusline.sh"
  assert_contains "$OUT" "/mine.sh"
}

test_harden_command_doc_gates_apply_on_approval() {
  local doc="$PLUGIN_ROOT/commands/harden.md"
  assert_file "$doc"
  assert_contains "$(cat "$doc")" 'allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/harden.sh:*)"]'
  assert_contains "$(cat "$doc")" "--apply"
}

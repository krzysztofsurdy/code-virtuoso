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
  umask 022
  harden --apply
  assert_eq "$RC" "0" "apply rc: $OUT"
  local s c
  s="$(user_settings)"; c="$(user_config)"
  assert_eq "$(jq -c '.attribution' "$s")" '{"commit":"","pr":""}'
  assert_eq "$(jq -r '.permissions.deny | index("Read(./.env)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.deny | index("Read(~/.ssh/**)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(git push *)") != null' "$s")" "false"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(git reset --hard *)") != null' "$s")" "true"
  assert_eq "$(jq -r '.permissions.ask | index("Bash(composer update *)") != null' "$s")" "true"
  assert_eq "$(jq -c '.loop.guard' "$c")" '{"blockSecrets":true,"protectTests":"ask"}'
  assert_eq "$(jq -r 'has("statusLine") or has("env") or has("sandbox")' "$s")" "false"
  assert_eq "$(backups_of "$s")" "0" "a new file needs no backup"
  assert_eq "$(ls -l "$s" | cut -c1-10)" "-rw-r--r--"
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

# install_failing_jq_empty: `jq empty <file>` fails, every other jq call runs the real jq.
install_failing_jq_empty() {
  local bin real
  bin="$(new_tmp_dir bin)"
  real="$(command -v jq)"
  printf '#!/bin/bash\n[[ "${1:-}" == empty ]] && exit 5\nexec "%s" "$@"\n' "$real" > "$bin/jq"
  chmod +x "$bin/jq"
  export PATH="$bin:$PATH"
}

test_harden_failed_write_leaves_the_original_intact() {
  local s; s="$(user_settings)"
  mkdir -p "$(dirname "$s")"
  echo '{"model":"opus"}' > "$s"
  install_failing_jq_empty
  harden --apply
  [[ $RC -ne 0 ]] || die "a failed validation must fail the run: $OUT"
  assert_eq "$(cat "$s")" '{"model":"opus"}'
  assert_eq "$(ls -A "$(dirname "$s")" | grep -v -e '^settings.json$' -e '^settings.json.bak' || true)" "" "no temp file left"
}

test_harden_apply_keeps_mode_and_symlink() {
  local s target; s="$(user_settings)"
  target="$HOME/dotfiles/claude-settings.json"
  mkdir -p "$(dirname "$s")" "$(dirname "$target")"
  echo '{"model":"opus"}' > "$target"
  chmod 600 "$target"
  ln -s "$target" "$s"
  harden --apply
  assert_eq "$RC" "0" "$OUT"
  [[ -L "$s" ]] || die "settings.json is no longer a symlink"
  assert_eq "$(jq -r '.model' "$target")" "opus"
  assert_eq "$(jq -r '.attribution.pr' "$target")" ""
  assert_eq "$(ls -l "$target" | cut -c1-10)" "-rw-------"
}

# rule_matches <rule> <command>: Claude Code's Bash rule wildcard as documented
# in https://code.claude.com/docs/en/permissions: `*` matches any text, and a
# lone trailing " *" also matches the bare command.
rule_matches() {
  local pattern="${1#Bash(}"
  pattern="${pattern%)}"
  # shellcheck disable=SC2053
  [[ "$2" == $pattern ]] && return 0
  [[ "$pattern" == *" *" && "${pattern% \*}" != *"*"* && "$2" == "${pattern% \*}" ]]
}

asks_for() {
  local rule
  while IFS= read -r rule; do
    rule_matches "$rule" "$1" && return 0
  done < <(jq -r '.permissions.ask[]' "$(user_settings)")
  return 1
}

test_harden_asks_for_force_pushes_only() {
  harden --apply
  assert_eq "$RC" "0" "$OUT"
  local c
  for c in "git push --force" "git push -f" "git push -f origin main" "git push origin main -f" \
    "git push origin -f main" "git push --force-with-lease" "git push origin feat/x --force-with-lease=feat/x" \
    "git push -u origin main --force" "git branch -D x" "git reset --hard" "composer update"; do
    asks_for "$c" || die "no ask rule matches: $c"
  done
  for c in "git push" "git push origin main" "git push -u origin feat/x" "git push origin my-feature-fix"; do
    ! asks_for "$c" || die "an ask rule matches a plain push: $c"
  done
}

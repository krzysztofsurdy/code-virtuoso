#!/bin/bash
# doctor.sh: read-only audit of the user's Claude Code setup.

SECRET_ENV_VALUE="sk-live-doctor-env-0123456789"
SECRET_HEADER_VALUE="Bearer doctor-header-9876543210"

# write_skill <dir> <name> <description> [extra frontmatter line]
write_skill() {
  mkdir -p "$1"
  printf -- '---\nname: %s\ndescription: %s\n%s\n---\n\n# %s\n' "$2" "$3" "${4:-}" "$2" > "$1/SKILL.md"
}

# write_agent <file> <name>
write_agent() {
  mkdir -p "$(dirname "$1")"
  printf -- '---\nname: %s\ndescription: an agent\n---\n\nBody.\n' "$2" > "$1"
}

# clean_fixture: a config dir under $HOME/.claude with nothing to report.
clean_fixture() {
  local cfg="$HOME/.claude"
  mkdir -p "$cfg/plugins/cache/mkt/alpha/1.0.0"
  write_skill "$cfg/skills/solo" solo "A standalone skill."
  write_skill "$cfg/skills/hidden" hidden "Run by name only." "disable-model-invocation: true"
  write_skill "$cfg/plugins/cache/mkt/alpha/1.0.0/skills/alpha-skill" alpha-skill "A plugin skill."
  write_agent "$cfg/agents/local-agent.md" local-agent
  write_agent "$cfg/plugins/cache/mkt/alpha/1.0.0/agents/alpha-agent.md" alpha-agent
  mkdir -p "$cfg/plugins/cache/mkt/alpha/1.0.0/commands"
  echo "Go." > "$cfg/plugins/cache/mkt/alpha/1.0.0/commands/go.md"
  jq -n --arg p "$cfg/plugins/cache/mkt/alpha/1.0.0" \
    '{version: 2, plugins: {"alpha@mkt": [{scope: "user", installPath: $p, version: "1.0.0"}]}}' \
    > "$cfg/plugins/installed_plugins.json"
  jq -n '{
    enabledPlugins: {"alpha@mkt": true},
    attribution: {commit: "", pr: ""},
    permissions: {deny: ["Read(./.env*)"], ask: ["Bash(git push --force*)"]},
    statusLine: {type: "command", command: "statusline.sh"},
    env: {CLAUDE_CODE_ENABLE_TELEMETRY: "1"}
  }' > "$cfg/settings.json"
  printf '# Rules\n\n- When debugging -> use /solo\n- Run `/alpha:go`, `/alpha:alpha-skill` or `/compact`.\n' > "$cfg/CLAUDE.md"
  jq -n '{mcpServers: {svc: {env: {API_TOKEN: "${MY_TOKEN}", LOG_LEVEL: "debug"}}}}' > "$HOME/.claude.json"
  mkdir -p "$XDG_CONFIG_HOME/code-virtuoso"
  echo '{"loop": {"guard": {"blockSecrets": true}}}' > "$XDG_CONFIG_HOME/code-virtuoso/config.json"
}

# dirty_fixture: one instance of every finding.
dirty_fixture() {
  local cfg="$HOME/.claude"
  local alpha="$cfg/plugins/cache/mkt/alpha/1.0.0" beta="$cfg/plugins/cache/mkt2/beta/2.0.0"
  local gamma="$cfg/plugins/cache/mkt/gamma/1.0.0"
  write_skill "$cfg/skills/dup-skill" dup-skill "Standalone copy."
  write_skill "$cfg/skills/solo" solo "A standalone skill."
  write_skill "$cfg/skills/hidden" hidden "Run by name only." "disable-model-invocation: true"
  write_skill "$WORK/external/linked-skill" linked-skill "Reached through a symlink."
  ln -s "$WORK/external/linked-skill" "$cfg/skills/linked-skill"
  write_skill "$cfg/skills/synced/uuid-1/synced-skill" synced-skill "A synced skill."
  write_skill "$alpha/skills/dup-skill" dup-skill "Plugin copy."
  write_agent "$alpha/agents/dup-agent.md" dup-agent
  write_agent "$cfg/agents/dup-agent.md" dup-agent
  write_skill "$beta/cat/big-skill" big-skill "$(printf 'x%.0s' $(seq 1 1500))"
  write_skill "$beta/cat/big-two" big-two "$(printf 'y%.0s' $(seq 1 1500))"
  local i
  for i in 1 2 3 4; do
    write_skill "$beta/cat/bulk-$i" "bulk-$i" "$(printf 'z%.0s' $(seq 1 1500))"
  done
  write_skill "$gamma/skills/solo" solo "Disabled plugin copy."
  mkdir -p "$cfg/plugins/cache/mkt/alpha/0.9.0/skills" "$cfg/plugins/marketplaces/mkt2/.claude-plugin"
  jq -n '{name: "mkt2", plugins: [{name: "beta", source: "./beta",
    skills: ["./cat/big-skill", "./cat/big-two", "./cat/bulk-1", "./cat/bulk-2", "./cat/bulk-3", "./cat/bulk-4"]}]}' \
    > "$cfg/plugins/marketplaces/mkt2/.claude-plugin/marketplace.json"
  jq -n --arg a "$alpha" --arg b "$beta" --arg g "$gamma" '{version: 2, plugins: {
    "alpha@mkt": [{scope: "user", installPath: $a, version: "1.0.0"}],
    "beta@mkt2": [{scope: "user", installPath: $b, version: "2.0.0"}],
    "gamma@mkt": [{scope: "user", installPath: $g, version: "1.0.0"}]}}' > "$cfg/plugins/installed_plugins.json"
  jq -n '{enabledPlugins: {"alpha@mkt": true, "beta@mkt2": true, "gamma@mkt": false}}' > "$cfg/settings.json"
  printf '# Rules\n\n- When haunted -> use /ghost-skill\n- When alone -> use /solo\n- Run `/hidden` by hand.\n' > "$cfg/CLAUDE.md"
  jq -n --arg s "$SECRET_ENV_VALUE" --arg h "$SECRET_HEADER_VALUE" '{
    mcpServers: {
      magic: {command: "npx", env: {API_KEY: $s, LOG_LEVEL: "debug"}},
      safe: {command: "npx", env: {API_TOKEN: "${MY_TOKEN}"}}
    },
    projects: {"/work/p": {mcpServers: {web: {type: "http", url: "https://x.invalid", headers: {Authorization: $h}}}}}
  }' > "$HOME/.claude.json"
}

# doctor [args...]: run the doctor from $HOME, outside any git repo, so no project layer leaks in.
doctor() { (cd "$HOME" && bash "$SCRIPTS/doctor.sh" "$@"); }
doctor_json() { doctor --json; }

# findings_of <json> <check>: the findings of one check, one compact JSON per line.
findings_of() { echo "$1" | jq -c --arg c "$2" '.findings[] | select(.check == $c)'; }

test_doctor_reports_duplicate_skill_with_sources() {
  dirty_fixture
  local out; out="$(doctor_json)"
  local dup; dup="$(findings_of "$out" duplicate-skill)"
  assert_eq "$(echo "$dup" | jq -r .severity)" "medium"
  assert_contains "$dup" "dup-skill"
  assert_contains "$dup" "$HOME/.claude/skills/dup-skill"
  assert_contains "$dup" "alpha@mkt"
  assert_eq "$(echo "$dup" | grep -c .)" "1" "only dup-skill is duplicated"
}

test_doctor_ignores_skills_of_disabled_plugins() {
  dirty_fixture
  local out; out="$(doctor_json)"
  assert_not_contains "$(findings_of "$out" duplicate-skill)" "solo"
}

test_doctor_reports_duplicate_agent() {
  dirty_fixture
  local out; out="$(doctor_json)"
  local dup; dup="$(findings_of "$out" duplicate-agent)"
  assert_contains "$dup" "dup-agent"
  assert_contains "$dup" "$HOME/.claude/agents/dup-agent.md"
  assert_contains "$dup" "alpha@mkt"
}

test_doctor_flags_listing_over_budget() {
  dirty_fixture
  local out; out="$(doctor_json)"
  local f; f="$(findings_of "$out" skill-listing)"
  assert_eq "$(echo "$f" | jq -r .severity)" "medium"
  assert_contains "$f" "8000"
  assert_contains "$f" "big-skill" "names the largest contributors"
  [[ "$(echo "$out" | jq '.listing.chars')" -gt 8000 ]] || die "listing should exceed the budget"
}

test_doctor_listing_reads_marketplace_skill_paths_and_skips_hidden() {
  dirty_fixture
  local out; out="$(doctor_json)"
  assert_eq "$(echo "$out" | jq '.listing.skills')" "11"
  rm -rf "$HOME/.claude/skills/hidden"
  assert_eq "$(doctor_json | jq '.listing.skills')" "11" "a disable-model-invocation skill is not listed"
}

test_doctor_flags_dead_and_non_invocable_claude_md_refs() {
  dirty_fixture
  local out; out="$(doctor_json)"
  local refs; refs="$(findings_of "$out" claude-md-ref)"
  assert_contains "$refs" "/ghost-skill"
  assert_contains "$refs" "/hidden"
  assert_contains "$refs" "disable-model-invocation"
  assert_not_contains "$refs" "/solo"
  assert_eq "$(echo "$refs" | grep -c .)" "2"
}

test_doctor_checks_every_ref_in_a_comma_list() {
  clean_fixture
  printf -- '- When stuck -> use /solo, /ghost-two, /alpha:go\n' > "$HOME/.claude/CLAUDE.md"
  local refs; refs="$(findings_of "$(doctor_json)" claude-md-ref)"
  assert_eq "$(echo "$refs" | jq -r .what | grep -c .)" "1"
  assert_contains "$refs" "/ghost-two"
  assert_contains "$refs" "CLAUDE.md:1"
}

test_doctor_reports_invalid_settings_json_and_still_exits_0() {
  clean_fixture
  echo '{"broken":' > "$HOME/.claude/settings.json"
  capture doctor --json
  assert_eq "$RC" "0"
  assert_contains "$(findings_of "$OUT" invalid-json)" "$HOME/.claude/settings.json"
}

test_doctor_flags_long_claude_md() {
  clean_fixture
  seq 1 250 | sed 's/^/- rule /' > "$HOME/.claude/CLAUDE.md"
  local f; f="$(findings_of "$(doctor_json)" claude-md-size)"
  assert_contains "$f" "250"
  assert_contains "$f" "$HOME/.claude/CLAUDE.md"
}

test_doctor_flags_plaintext_mcp_secrets_without_printing_values() {
  dirty_fixture
  local out human; out="$(doctor_json)"; human="$(doctor)$(doctor --verbose)"
  local f; f="$(findings_of "$out" mcp-secret)"
  assert_eq "$(echo "$f" | grep -c .)" "2"
  assert_contains "$f" "magic"
  assert_contains "$f" "API_KEY"
  assert_contains "$f" "web"
  assert_contains "$f" "Authorization"
  assert_eq "$(echo "$f" | jq -r .severity | sort -u)" "high"
  assert_not_contains "$f" "LOG_LEVEL"
  assert_not_contains "$f" "API_TOKEN" "a \${VAR} reference is not a secret"
  local text
  for text in "$out" "$human"; do
    assert_not_contains "$text" "$SECRET_ENV_VALUE"
    assert_not_contains "$text" "doctor-header-9876543210"
  done
}

test_doctor_reports_settings_gaps() {
  dirty_fixture
  local out; out="$(doctor_json)"
  local c
  for c in settings-attribution settings-deny settings-ask settings-statusline settings-telemetry loop-guard; do
    [[ -n "$(findings_of "$out" "$c")" ]] || die "missing finding $c"
  done
  assert_contains "$(findings_of "$out" settings-attribution)" "/loop-virtuoso:harden"
}

test_doctor_reports_orphan_plugin_cache() {
  dirty_fixture
  local f; f="$(findings_of "$(doctor_json)" orphan-cache)"
  assert_eq "$(echo "$f" | grep -c .)" "1"
  assert_contains "$f" "$HOME/.claude/plugins/cache/mkt/alpha/0.9.0"
}

test_doctor_clean_setup_has_no_findings() {
  clean_fixture
  local out; out="$(doctor_json)"
  assert_eq "$(echo "$out" | jq -c '.findings')" "[]"
  assert_eq "$(echo "$out" | jq '.listing.skills')" "2"
  assert_contains "$(doctor)" "No findings"
}

test_doctor_human_output_lists_findings_and_exits_0() {
  dirty_fixture
  capture doctor
  assert_eq "$RC" "0"
  assert_contains "$OUT" "[high]"
  assert_contains "$OUT" "/ghost-skill"
  assert_contains "$OUT" "fix:"
}

test_doctor_writes_nothing() {
  dirty_fixture
  local before after
  snapshot() { (cd "$HOME" && find . -print | sort && find . -type f -exec cksum {} + | sort); }
  before="$(snapshot)"
  doctor >/dev/null
  doctor --json >/dev/null
  doctor --verbose >/dev/null
  after="$(snapshot)"
  assert_eq "$after" "$before" "doctor must not write"
}

test_doctor_honors_claude_config_dir() {
  clean_fixture
  export CLAUDE_CONFIG_DIR; CLAUDE_CONFIG_DIR="$(new_tmp_dir cfg)"
  local out; out="$(doctor_json)"
  assert_eq "$(echo "$out" | jq -r .configDir)" "$CLAUDE_CONFIG_DIR"
  [[ -n "$(findings_of "$out" settings-attribution)" ]] || die "an empty config dir lacks attribution"
}

test_doctor_rejects_unknown_option() {
  capture doctor --bogus
  assert_eq "$RC" "2"
}

# second_dup_skill: a second duplicated skill and a second orphan cache for the dirty fixture.
second_dup_skill() {
  write_skill "$HOME/.claude/skills/dup-two" dup-two "Standalone copy."
  write_skill "$HOME/.claude/plugins/cache/mkt/alpha/1.0.0/skills/dup-two" dup-two "Plugin copy."
  mkdir -p "$HOME/.claude/plugins/cache/mkt/alpha/0.8.0"
}

# count_of <text> <fixed string>: how many lines contain the string.
count_of() { printf '%s\n' "$1" | grep -cF -- "$2" || true; }

test_doctor_groups_findings_of_one_check() {
  dirty_fixture
  second_dup_skill
  local out; out="$(doctor)"
  assert_contains "$out" "[medium] duplicate-skill: 2 findings - "
  assert_contains "$out" "  - dup-skill: alpha@mkt, user"
  assert_contains "$out" "  - dup-two: alpha@mkt, user"
  assert_eq "$(count_of "$out" "Keep one copy: delete the extra standalone")" "1" "the fix prints once per group"
  assert_not_contains "$out" "$HOME/.claude/skills/dup-skill/SKILL.md" "grouped items omit paths"
  assert_contains "$out" "[low] orphan-cache: 2 findings - "
  assert_contains "$out" "  - mkt/alpha/0.8.0"
  assert_contains "$out" "  - mkt/alpha/0.9.0"
  assert_contains "$out" "[high] mcp-secret: 2 findings - "
  assert_contains "$out" "magic: env.API_KEY"
}

test_doctor_splits_claude_md_refs_by_kind() {
  dirty_fixture
  printf -- '- -> use /ghost-one\n- -> use /ghost-two\n- Run `/hidden` by hand.\n' > "$HOME/.claude/CLAUDE.md"
  local out; out="$(doctor)"
  assert_contains "$out" "[medium] claude-md-ref: 2 findings - "
  assert_contains "$out" "  - /ghost-one (line 1)"
  assert_contains "$out" "  - /ghost-two (line 2)"
  assert_contains "$out" "[medium] claude-md-ref: /hidden points to a skill with disable-model-invocation"
}

test_doctor_single_finding_keeps_full_format() {
  dirty_fixture
  local out; out="$(doctor)"
  assert_contains "$out" "[low] orphan-cache: Plugin cache directory is not referenced by installed_plugins.json"
  assert_contains "$out" "where: $HOME/.claude/plugins/cache/mkt/alpha/0.9.0"
  assert_contains "$out" "[medium] duplicate-agent: Agent \"dup-agent\" is defined 2 times"
}

test_doctor_verbose_prints_every_finding() {
  dirty_fixture
  second_dup_skill
  local out; out="$(doctor --verbose)"
  assert_eq "$(count_of "$out" "Keep one copy: delete the extra standalone")" "2"
  assert_contains "$out" "$HOME/.claude/skills/dup-skill/SKILL.md"
  assert_contains "$out" "$HOME/.claude/skills/dup-two/SKILL.md"
  assert_not_contains "$out" "findings - "
  assert_eq "$(doctor --verbose --json)" "$(doctor_json)" "--json wins over --verbose"
}

test_doctor_json_findings_keep_their_shape() {
  dirty_fixture
  second_dup_skill
  local out; out="$(doctor_json)"
  assert_eq "$(echo "$out" | jq -c '[.findings[] | keys] | unique')" '[["check","fix","severity","what","where"]]'
  assert_eq "$(echo "$out" | jq -c 'keys - ["satisfiedBy"]')" '["configDir","findings","listing","summary"]'
}

# gap_fixture: the clean fixture without any settings key in the user settings.json or a user loop config.
gap_fixture() {
  clean_fixture
  jq '{enabledPlugins}' "$HOME/.claude/settings.json" > "$HOME/.claude/settings.json.tmp"
  mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
  rm -f "$XDG_CONFIG_HOME/code-virtuoso/config.json"
}

test_doctor_reads_user_settings_local_layer() {
  gap_fixture
  jq -n '{attribution: {commit: ""}, permissions: {deny: ["Read(./private/**)"], ask: ["Bash(git reset --hard*)"]},
    statusLine: {type: "command", command: "s.sh"}}' > "$HOME/.claude/settings.local.json"
  local out; out="$(doctor_json)"
  local c
  for c in settings-attribution settings-deny settings-ask settings-statusline; do
    [[ -z "$(findings_of "$out" "$c")" ]] || die "settings.local.json should satisfy $c"
  done
  assert_eq "$(echo "$out" | jq -r '.satisfiedBy["settings-deny"][0]')" "$HOME/.claude/settings.local.json"
}

test_doctor_reads_project_settings_layers_inside_a_repo() {
  gap_fixture
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.claude"
  jq -n '{attribution: {pr: ""}, permissions: {deny: ["Read(./private/**)"]}, env: {CLAUDE_CODE_ENABLE_TELEMETRY: "1"}}' \
    > "$repo/.claude/settings.json"
  jq -n '{permissions: {ask: ["Bash(git push --force*)"]}, statusLine: {type: "command", command: "s.sh"}}' \
    > "$repo/.claude/settings.local.json"
  local out; out="$(cd "$repo/src" && bash "$SCRIPTS/doctor.sh" --json)"
  local c
  for c in settings-attribution settings-deny settings-ask settings-statusline; do
    [[ -z "$(findings_of "$out" "$c")" ]] || die "project settings should satisfy $c"
  done
  assert_eq "$(echo "$out" | jq -r '.satisfiedBy["settings-ask"][0]')" "$repo/.claude/settings.local.json"
  local tel; tel="$(findings_of "$out" settings-telemetry)"
  [[ -n "$tel" ]] || die "telemetry is honoured only from the user settings.json"
  assert_contains "$(echo "$tel" | jq -r .fix)" "user settings.json"
  [[ -n "$(findings_of "$(doctor_json)" settings-deny)" ]] || die "outside the repo the project layer does not apply"
}

test_doctor_combines_deny_rules_across_layers() {
  gap_fixture
  jq '. + {permissions: {deny: []}}' "$HOME/.claude/settings.json" > "$HOME/.claude/s.tmp"
  mv "$HOME/.claude/s.tmp" "$HOME/.claude/settings.json"
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.claude"
  echo '{"permissions": {"deny": ["Read(./private/**)"]}}' > "$repo/.claude/settings.local.json"
  local out; out="$(cd "$repo" && bash "$SCRIPTS/doctor.sh" --json)"
  [[ -z "$(findings_of "$out" settings-deny)" ]] || die "a deny rule in any layer satisfies the check"
}

test_doctor_reports_invalid_project_settings() {
  gap_fixture
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.claude"
  echo '{"broken":' > "$repo/.claude/settings.json"
  local out; out="$(cd "$repo" && bash "$SCRIPTS/doctor.sh" --json)"
  assert_contains "$(findings_of "$out" invalid-json)" "$repo/.claude/settings.json"
}

test_doctor_loop_guard_reads_project_config() {
  gap_fixture
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.code-virtuoso"
  echo '{"loop": {"guard": {"protectTests": true}}}' > "$repo/.code-virtuoso/config.json"
  local out; out="$(cd "$repo" && bash "$SCRIPTS/doctor.sh" --json)"
  [[ -z "$(findings_of "$out" loop-guard)" ]] || die "the project config layer enables a guard"
  assert_eq "$(echo "$out" | jq -r '.satisfiedBy["loop-guard"][0]')" "$repo/.code-virtuoso/config.json"
  [[ -n "$(findings_of "$(doctor_json)" loop-guard)" ]] || die "outside the repo only the user layer counts"
}

test_doctor_writes_nothing_inside_a_repo() {
  dirty_fixture
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.claude"
  echo '{"permissions": {"deny": ["Read(./private/**)"]}}' > "$repo/.claude/settings.json"
  local before after
  snapshot() { (cd "$1" && find . -print | sort && find . -type f -exec cksum {} + | sort); }
  before="$(snapshot "$HOME")$(snapshot "$repo")"
  (cd "$repo" && bash "$SCRIPTS/doctor.sh" >/dev/null && bash "$SCRIPTS/doctor.sh" --verbose >/dev/null &&
    bash "$SCRIPTS/doctor.sh" --json >/dev/null)
  after="$(snapshot "$HOME")$(snapshot "$repo")"
  assert_eq "$after" "$before" "doctor must not write"
}

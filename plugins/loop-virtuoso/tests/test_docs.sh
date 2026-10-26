#!/bin/bash
# Bug 9 and repo hygiene: docs agree with the code and with each other.

plugin_files() { find "$PLUGIN_ROOT" -type f ! -name LICENSE ! -path '*/.git/*' ! -path '*/tests/*'; }

test_no_em_or_en_dashes() {
  local em en hits
  em="$(printf '\xe2\x80\x94')"; en="$(printf '\xe2\x80\x93')"
  hits="$({ plugin_files; find "$PLUGIN_ROOT/tests" -type f; } | xargs grep -l -e "$em" -e "$en" || true)"
  [[ -z "$hits" ]] || die "em/en dashes in: $hits"
}

test_no_contradictory_boundary_claims() {
  local hits
  hits="$(plugin_files | xargs grep -n -i -e "the guard, not the allowlist" -e "broad-but-still-bounded" -e "stay reasonably broad" || true)"
  [[ -z "$hits" ]] || die "contradictory boundary claim: $hits"
}

test_status_docs_do_not_claim_cost() {
  local hits
  hits="$(grep -n -i -e "counts, cost" -e "cost.*log tail" -e "cost if tracked" "$PLUGIN_ROOT/commands/help.md" "$PLUGIN_ROOT/commands/status.md" || true)"
  [[ -z "$hits" ]] || die "status docs mention cost: $hits"
  hits="$(grep -n -i "cumulative cost if tracked" "$PLUGIN_ROOT/skills/iteration-loop/SKILL.md" || true)"
  [[ -z "$hits" ]] || die "SKILL claims status shows cost: $hits"
}

test_scripts_never_bypass_hooks_or_stage_everything() {
  local hits
  hits="$(grep -rn -e "--no-verify" -e "add -A" "$PLUGIN_ROOT/scripts" "$PLUGIN_ROOT/hooks" || true)"
  [[ -z "$hits" ]] || die "unsafe git usage: $hits"
}

test_readme_license_and_install() {
  assert_contains "$(cat "$PLUGIN_ROOT/README.md")" "MIT"
  assert_not_contains "$(cat "$PLUGIN_ROOT/README.md")" "GPL"
  assert_contains "$(cat "$PLUGIN_ROOT/README.md")" "/plugin install loop-virtuoso@code-virtuoso"
}

test_start_docs_do_not_claim_archive_on_start() {
  local hits
  hits="$(grep -n -i "archives a previous run if the branch changed" "$PLUGIN_ROOT/commands/start.md" "$PLUGIN_ROOT/skills/iteration-loop/SKILL.md" || true)"
  [[ -z "$hits" ]] || die "start docs claim archive on start: $hits"
}

doc_files() { find "$PLUGIN_ROOT/commands" "$PLUGIN_ROOT/skills" -type f -name '*.md'; echo "$PLUGIN_ROOT/README.md"; echo "$PLUGIN_ROOT/REVIEW.md"; }

test_docs_use_the_new_storage_paths_only() {
  local hits
  hits="$(doc_files | xargs grep -n -e '\.delivery-loop' -e 'teams\.json' | grep -v -i -e 'migrat' -e 'old ' -e 'earlier' -e 'then named' || true)"
  [[ -z "$hits" ]] || die "legacy path outside a migration note: $hits"
}

test_docs_say_pipelines_not_teams() {
  local hits
  hits="$(doc_files | xargs grep -n -i -w -e 'team' -e 'teams' | grep -v -i -e 'agent team' -e 'agent-teams' -e 'team plan' -e 'with the team' -e 'earlier' -e 'old ' -e 'then named' -e 'migrat' || true)"
  [[ -z "$hits" ]] || die "'team' still used for pipelines: $hits"
}

test_iteration_loop_skill_is_reference_only() {
  local fm
  fm="$(sed -n '1,/^---$/p;' "$PLUGIN_ROOT/skills/iteration-loop/SKILL.md" | sed -n '2,/^---$/p')"
  assert_contains "$fm" "user-invocable: false"
  assert_not_contains "$fm" "argument-hint"
}

test_backlog_compiler_reads_shared_config_not_the_supplement() {
  local text; text="$(cat "$PLUGIN_ROOT/skills/backlog-compiler/SKILL.md")"
  assert_not_contains "$text" ".supplement.md"
  assert_contains "$text" "ticket-delivery"
  assert_contains "$text" ".code-virtuoso/config.json"
}

test_plugin_docs_cross_link_related_skills() {
  local text; text="$(cat "$PLUGIN_ROOT/skills/backlog-compiler/SKILL.md" "$PLUGIN_ROOT/README.md")"
  assert_contains "$text" "ticket-writer"
  assert_contains "$text" "ticket-delivery"
  assert_contains "$text" "finishing-branch"
}

test_plugin_version_is_2_1_0() {
  assert_eq "$(jq -r .version "$PLUGIN_ROOT/.claude-plugin/plugin.json")" "2.1.0"
}

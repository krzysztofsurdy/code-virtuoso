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

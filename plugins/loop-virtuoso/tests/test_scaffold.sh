#!/bin/bash
# scaffold.sh copies a template into the git root and never overwrites silently.

scaffold() {
  local dir="$1"; shift
  (cd "$dir" && bash "$SCRIPTS/scaffold.sh" "$@")
}

test_scaffold_devcontainer_writes_three_files() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo" devcontainer
  assert_eq "$RC" "0" "devcontainer scaffold exit code"
  assert_file "$repo/.devcontainer/devcontainer.json"
  assert_file "$repo/.devcontainer/Dockerfile"
  assert_file "$repo/.devcontainer/init-firewall.sh"
  [[ -x "$repo/.devcontainer/init-firewall.sh" ]] || die "init-firewall.sh must be executable"
  assert_contains "$OUT" ".devcontainer/devcontainer.json"
}

test_scaffold_issue_to_pr_writes_workflow() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo" issue-to-pr
  assert_eq "$RC" "0" "issue-to-pr scaffold exit code"
  assert_file "$repo/.github/workflows/claude-issue-to-pr.yml"
  assert_contains "$OUT" ".github/workflows/claude-issue-to-pr.yml"
}

test_scaffold_pilot_backlog_writes_backlog() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo" pilot-backlog
  assert_eq "$RC" "0" "pilot-backlog scaffold exit code"
  assert_file "$repo/.code-virtuoso/loop/backlog.json"
  assert_contains "$OUT" "/loop-virtuoso:start"
}

test_scaffold_writes_at_git_root_from_a_subdirectory() {
  local repo; repo="$(mk_repo)"
  scaffold "$repo/src" issue-to-pr >/dev/null
  assert_file "$repo/.github/workflows/claude-issue-to-pr.yml"
  assert_no_file "$repo/src/.github"
}

test_scaffold_refuses_to_overwrite_and_writes_nothing() {
  local repo; repo="$(mk_repo)"
  mkdir -p "$repo/.devcontainer"
  echo "mine" > "$repo/.devcontainer/Dockerfile"
  capture scaffold "$repo" devcontainer
  [[ $RC -ne 0 ]] || die "must refuse when a target exists"
  assert_contains "$OUT" ".devcontainer/Dockerfile"
  assert_contains "$OUT" "--force"
  assert_eq "$(cat "$repo/.devcontainer/Dockerfile")" "mine"
  assert_no_file "$repo/.devcontainer/devcontainer.json"
  assert_no_file "$repo/.devcontainer/init-firewall.sh"
}

test_scaffold_force_backs_up_existing_file() {
  local repo backup; repo="$(mk_repo)"
  mkdir -p "$repo/.github/workflows"
  echo "mine" > "$repo/.github/workflows/claude-issue-to-pr.yml"
  capture scaffold "$repo" issue-to-pr --force
  assert_eq "$RC" "0" "forced scaffold exit code"
  backup="$(ls "$repo/.github/workflows/" | grep '^claude-issue-to-pr\.yml\.bak\.' || true)"
  [[ -n "$backup" ]] || die "no backup written"
  assert_eq "$(cat "$repo/.github/workflows/$backup")" "mine"
  assert_contains "$(cat "$repo/.github/workflows/claude-issue-to-pr.yml")" "claude-code-action"
  assert_contains "$OUT" "$backup"
}

test_scaffold_force_before_kind_is_accepted() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo" --force pilot-backlog
  assert_eq "$RC" "0" "flag order must not matter"
  assert_file "$repo/.code-virtuoso/loop/backlog.json"
}

test_scaffold_pilot_backlog_refuses_while_a_loop_is_active() {
  local repo; repo="$(mk_repo)"
  write_backlog "$repo" feat/x
  mkdir -p "$repo/.code-virtuoso/loop/state"
  echo '{}' > "$repo/.code-virtuoso/loop/state/session.local.json"
  capture scaffold "$repo" pilot-backlog --force
  [[ $RC -ne 0 ]] || die "must refuse to replace the backlog of an active loop"
  assert_contains "$OUT" "active"
  assert_eq "$(jq -r .branch "$repo/.code-virtuoso/loop/backlog.json")" "feat/x"
}

test_scaffold_unknown_kind_prints_usage() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo" nope
  assert_eq "$RC" "1" "unknown kind exit code"
  assert_contains "$OUT" "usage"
  assert_contains "$OUT" "devcontainer"
}

test_scaffold_without_kind_prints_usage() {
  local repo; repo="$(mk_repo)"
  capture scaffold "$repo"
  assert_eq "$RC" "1" "missing kind exit code"
  assert_contains "$OUT" "usage"
}

test_scaffold_outside_a_git_repo_fails() {
  local dir; dir="$(new_tmp_dir plain)"
  capture scaffold "$dir" issue-to-pr
  [[ $RC -ne 0 ]] || die "must fail outside a git repo"
  assert_contains "$OUT" "git"
  assert_no_file "$dir/.github"
}

test_pilot_backlog_passes_validation() {
  local repo; repo="$(mk_repo)"
  scaffold "$repo" pilot-backlog >/dev/null
  capture bash "$SCRIPTS/validate-backlog.sh" "$repo/.code-virtuoso/loop/backlog.json"
  assert_eq "$RC" "0" "pilot backlog must validate: $OUT"
}

test_pilot_backlog_branch_is_not_a_default_branch() {
  local branch
  branch="$(jq -r .branch "$PLUGIN_ROOT/templates/backlog/pilot-backlog.json")"
  case "$branch" in
    main|master|trunk|develop|"") die "pilot branch must be a feature branch, got [$branch]" ;;
  esac
}

test_json_templates_parse() {
  local f
  for f in "$PLUGIN_ROOT/templates/backlog/pilot-backlog.json" "$PLUGIN_ROOT/templates/devcontainer/devcontainer.json"; do
    jq empty "$f" || die "not valid JSON: $f"
  done
}

test_devcontainer_template_mounts_no_host_credentials() {
  local mounts
  mounts="$(jq -r '(.mounts // [])[] | if type == "string" then . else (.source // "") end' "$PLUGIN_ROOT/templates/devcontainer/devcontainer.json")"
  assert_not_contains "$mounts" ".ssh"
  assert_not_contains "$mounts" ".aws"
  assert_not_contains "$mounts" ".config/gcloud"
  assert_not_contains "$mounts" ".azure"
  assert_not_contains "$mounts" "localEnv:HOME"
  assert_eq "$(jq -r .remoteUser "$PLUGIN_ROOT/templates/devcontainer/devcontainer.json")" "node"
}

test_firewall_template_allowlists_required_hosts() {
  local fw; fw="$(cat "$PLUGIN_ROOT/templates/devcontainer/init-firewall.sh")"
  assert_contains "$fw" "api.anthropic.com"
  assert_contains "$fw" "registry.npmjs.org"
  assert_contains "$fw" "repo.packagist.org"
  assert_contains "$fw" "api.github.com/meta"
  assert_contains "$fw" "OUTPUT DROP"
}

test_issue_to_pr_template_is_bounded() {
  local wf; wf="$(cat "$PLUGIN_ROOT/templates/github/claude-issue-to-pr.yml")"
  assert_contains "$wf" "anthropics/claude-code-action@v1"
  assert_contains "$wf" "timeout-minutes:"
  assert_contains "$wf" "concurrency:"
  assert_contains "$wf" "--max-turns"
  assert_contains "$wf" "--draft"
  assert_contains "$wf" "secrets.ANTHROPIC_API_KEY"
  assert_not_contains "$wf" "pull_request_target"
}

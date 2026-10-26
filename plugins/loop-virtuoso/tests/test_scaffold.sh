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
  assert_contains "$wf" "anthropics/claude-code-action@"
  assert_contains "$wf" "timeout-minutes:"
  assert_contains "$wf" "concurrency:"
  assert_contains "$wf" "--max-turns"
  assert_contains "$wf" "--draft"
  assert_contains "$wf" "secrets.ANTHROPIC_API_KEY"
  assert_not_contains "$wf" "pull_request_target"
}

test_issue_to_pr_template_pins_actions_to_commit_shas() {
  local wf unpinned
  wf="$PLUGIN_ROOT/templates/github/claude-issue-to-pr.yml"
  grep -q 'uses:' "$wf" || die "no uses: lines found"
  unpinned="$(grep 'uses:' "$wf" | grep -vE 'uses: [A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40} # v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
  assert_eq "$unpinned" "" "every action must be pinned to a commit SHA with a # vX.Y.Z comment"
}

test_issue_to_pr_template_does_not_persist_checkout_credentials() {
  local checkout
  checkout="$(grep -A 3 'uses: actions/checkout@' "$PLUGIN_ROOT/templates/github/claude-issue-to-pr.yml")"
  assert_contains "$checkout" "persist-credentials: false"
}

test_issue_to_pr_template_keeps_expressions_out_of_run_scripts() {
  local scripts
  scripts="$(awk '
    in_run && (NF == 0 || match($0, /^ */) && RLENGTH > run_indent) { print; next }
    { in_run = 0 }
    /^ *(- )?run: *[|>]/ { in_run = 1; match($0, /^ */); run_indent = RLENGTH; next }
    /^ *(- )?run: / { print }
  ' "$PLUGIN_ROOT/templates/github/claude-issue-to-pr.yml")"
  assert_contains "$scripts" "gh pr create" "run script extraction"
  assert_not_contains "$scripts" '${{' "pass values to run scripts through env, not expressions"
}

# run_firewall_with_stubs [fail_on]: runs init-firewall.sh against stub iptables,
# ip6tables, ipset, curl, dig, ip and aggregate that append their argv to
# $FW_LOG. fail_on=meta makes the api.github.com/meta fetch fail, fail_on=dig
# makes every DNS lookup come back empty. Sets OUT and RC.
run_firewall_with_stubs() {
  local bin cmd
  bin="$(new_tmp_dir fwbin)"
  export FW_LOG="$bin/calls.log" FW_FAIL_ON="${1:-}"
  : > "$FW_LOG"
  for cmd in iptables ip6tables ipset; do
    printf '#!/bin/bash\nprintf "%%s %%s\\n" %s "$*" >> "$FW_LOG"\n' "$cmd" > "$bin/$cmd"
  done
  printf '#!/bin/bash\n' > "$bin/iptables-save"
  cat > "$bin/curl" <<'STUB'
#!/bin/bash
printf 'curl %s\n' "$*" >> "$FW_LOG"
case "$*" in
  *api.github.com/meta*)
    [[ "$FW_FAIL_ON" == meta ]] && exit 7
    echo '{"web":["192.30.252.0/22"],"api":["192.30.252.0/22"],"git":["192.30.252.0/22","2a0a:a440::/29"]}' ;;
  *api.github.com/zen*) exit 0 ;;
  *) exit 7 ;;
esac
STUB
  cat > "$bin/dig" <<'STUB'
#!/bin/bash
[[ "$FW_FAIL_ON" == dig ]] || echo 203.0.113.10
STUB
  printf '#!/bin/bash\necho "default via 172.17.0.1 dev eth0"\n' > "$bin/ip"
  printf '#!/bin/bash\ncat\n' > "$bin/aggregate"
  chmod +x "$bin"/*
  capture env PATH="$bin:$PATH" bash "$PLUGIN_ROOT/templates/devcontainer/init-firewall.sh"
}

# last_policy <tool> <chain>: the last policy the stubbed firewall set on a chain.
last_policy() { grep "^$1 -P $2 " "$FW_LOG" | tail -n 1 | awk '{print $4}'; }

assert_firewall_closed() {
  local tool chain
  assert_not_contains "$(grep -e '-P ' "$FW_LOG")" "ACCEPT" "no chain may ever have an ACCEPT policy"
  for tool in iptables ip6tables; do
    for chain in INPUT FORWARD OUTPUT; do
      assert_eq "$(last_policy "$tool" "$chain")" "DROP" "$tool $chain policy"
    done
  done
}

test_firewall_sets_drop_policies_before_flushing() {
  local first_drop first_flush
  run_firewall_with_stubs
  assert_eq "$RC" "0" "firewall with working stubs: $OUT"
  first_drop="$(grep -n '^iptables -P OUTPUT DROP' "$FW_LOG" | head -n 1 | cut -d: -f1)"
  first_flush="$(grep -n '^iptables -F' "$FW_LOG" | head -n 1 | cut -d: -f1)"
  [[ -n "$first_drop" && -n "$first_flush" ]] || die "expected a DROP policy and a flush in: $(cat "$FW_LOG")"
  (( first_drop < first_flush )) || die "OUTPUT DROP (line $first_drop) must come before the flush (line $first_flush)"
  assert_firewall_closed
  assert_not_contains "$(cat "$FW_LOG")" "ipset flush" "a successful run keeps its allowlist"
}

test_firewall_fails_closed_when_github_meta_is_unreachable() {
  run_firewall_with_stubs meta
  [[ $RC -ne 0 ]] || die "must fail when api.github.com/meta is unreachable"
  assert_contains "$OUT" "api.github.com/meta"
  assert_firewall_closed
  assert_contains "$(cat "$FW_LOG")" "ipset flush allowed-hosts" "a failed run must empty the allowlist"
}

test_firewall_fails_closed_when_a_domain_does_not_resolve() {
  run_firewall_with_stubs dig
  [[ $RC -ne 0 ]] || die "must fail when an allowed domain does not resolve"
  assert_contains "$OUT" "cannot resolve"
  assert_firewall_closed
  assert_contains "$(cat "$FW_LOG")" "ipset flush allowed-hosts" "a failed run must empty the allowlist"
}

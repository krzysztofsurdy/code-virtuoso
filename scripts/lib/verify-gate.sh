#!/bin/bash
# The deterministic completion gate.
#
# Pure function: reports pass/fail/violation/stall for one step. Never writes
# backlog.json -- callers apply the result via lib/backlog.sh's
# step_apply_verdict. Both run modes call this same function; neither
# reimplements it.

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./backlog.sh
source "$LIB_DIR/backlog.sh"

# verify_gate_run <backlog_file> <item_id> <step_id> <start_sha>
# Prints exactly one JSON verdict to stdout:
#   {"verdict":"pass"}
#   {"verdict":"fail","exitCode":N,"output":"..."}
#   {"verdict":"violation","paths":["..."]}
#   {"verdict":"stall"}
verify_gate_run() {
  local backlog_file="$1" item_id="$2" step_id="$3" start_sha="$4"

  # The check that matters most: did the worker edit the loop's own control
  # files during its turn? File-name-based protected-path matching (below)
  # can never catch this alone -- the loop's directory is excluded from that
  # scan entirely (it's infrastructure, not work product), and even without
  # that exclusion, rewriting verifyCommand to "true" touches no path a glob
  # would flag. Comparing file *content* against a snapshot is what closes
  # this -- but ONLY if the snapshot itself lives somewhere the worker's
  # tools cannot reach. An earlier version kept it as a sibling file next to
  # backlog.json; a worker with the same Edit/Write/Bash access used to
  # tamper with backlog.json could just as easily overwrite the sibling
  # snapshot to match, laundering the comparison instead of failing it. The
  # snapshot now lives outside the project tree entirely (see
  # verify_gate_snapshot_path), relying on Claude Code's own file-tool
  # scoping to the project directory as the actual boundary, not a
  # convention the worker happens to follow.
  local loop_dir_label
  loop_dir_label="$(basename "$(dirname "$backlog_file")")"

  if _verify_gate_check_tamper "$backlog_file"; then
    echo "{\"verdict\":\"violation\",\"paths\":[\"${loop_dir_label}/$(basename "$backlog_file") (content tampered, restored)\"]}"
    return 0
  fi
  local teams_file
  teams_file="$(dirname "$backlog_file")/teams.json"
  if [[ -f "$teams_file" ]] && _verify_gate_check_tamper "$teams_file"; then
    echo "{\"verdict\":\"violation\",\"paths\":[\"${loop_dir_label}/teams.json (content tampered, restored)\"]}"
    return 0
  fi

  local repo_dir
  repo_dir="$(git -C "$(dirname "$backlog_file")" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -z "$repo_dir" ]] && repo_dir="$(cd "$(dirname "$backlog_file")" && pwd)"

  # `git diff` alone misses brand-new files -- a worker that only creates a
  # file (no existing file touched) would otherwise read as a stall. Union it
  # with untracked-but-not-gitignored files. This is only safe because every
  # non-violation iteration ends in a checkpoint commit (below) -- so "still
  # untracked" always means "new this iteration", never leftover cruft from
  # before the run started or from a prior iteration.
  #
  # The loop's own directory (backlog.json, teams.json, session/progress/
  # events files) is excluded entirely, not just protected -- it's the loop's
  # infrastructure, never the worker's work product.
  local loop_dir_name
  loop_dir_name="$(basename "$(dirname "$backlog_file")")"

  local changed_files
  changed_files=$(
    {
      git -C "$repo_dir" diff --name-only "$start_sha" 2>/dev/null
      git -C "$repo_dir" ls-files --others --exclude-standard 2>/dev/null
    } | sort -u | _verify_gate_drop_loop_dir "$loop_dir_name"
  )

  if [[ -z "$changed_files" ]]; then
    echo '{"verdict":"stall"}'
    return 0
  fi

  # Layer 2 of the write-boundary guard -- checks the resulting tree state,
  # not which tool produced it, so it catches what PreToolUse's Edit/Write
  # coverage misses.
  local protected violations=()
  protected=$(backlog_protected_paths "$backlog_file")
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    if backlog_path_is_protected "$f" "$protected"; then
      violations+=("$f")
    fi
  done <<< "$changed_files"

  if [[ ${#violations[@]} -gt 0 ]]; then
    local violated_json
    violated_json=$(printf '%s\n' "${violations[@]}" | jq -R . | jq -sc .)
    echo "{\"verdict\":\"violation\",\"paths\":$violated_json}"
    return 0
  fi

  local step verify_cmd exit_code output output_json
  step=$(backlog_get_step "$backlog_file" "$item_id" "$step_id")
  verify_cmd=$(echo "$step" | jq -r '.verifyCommand')

  output=$(cd "$repo_dir" && bash -c "$verify_cmd" 2>&1)
  exit_code=$?

  # Checkpoint commit on pass or fail (not violation -- those changes get left
  # uncommitted for inspection, not preserved). Without this, an iteration's
  # uncommitted diff persists into every later iteration's `git diff
  # $start_sha`, since nothing the worker does is required to commit -- which
  # would both mask a true stall forever after the first real change, and let
  # leftover untracked files keep re-triggering the union check above. One
  # checkpoint per iteration keeps `start_sha` meaningful for the next one.
  _verify_gate_checkpoint "$repo_dir" "$loop_dir_name" "loop-virtuoso: ${item_id}/${step_id}"

  if [[ $exit_code -eq 0 ]]; then
    echo '{"verdict":"pass"}'
  else
    output_json=$(echo "$output" | tail -n 40 | jq -Rs .)
    echo "{\"verdict\":\"fail\",\"exitCode\":$exit_code,\"output\":$output_json}"
  fi
}

# _verify_gate_drop_loop_dir <loop_dir_name>
# Reads paths on stdin, drops anything under <loop_dir_name>/, prints the
# rest. A plain `case` inside a `$(...)` command substitution does not parse
# on bash 3.2 (macOS's default /bin/bash) -- it's a real, documented parser
# bug in that version, not a style issue -- so this filtering lives in its
# own function instead of inline where verify_gate_run needs it.
_verify_gate_drop_loop_dir() {
  local loop_dir_name="$1" f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      "${loop_dir_name}"/*) ;;
      *) echo "$f" ;;
    esac
  done
}

# _verify_gate_checkpoint <repo_dir> <loop_dir_name> <message>
# Stages everything except the loop's own directory and commits if there's
# anything staged. Best-effort: a failed commit (e.g. no git identity
# configured) doesn't fail the gate, it just leaves start_sha stale for one
# more iteration.
_verify_gate_checkpoint() {
  local repo_dir="$1" loop_dir_name="$2" message="$3"
  git -C "$repo_dir" add -A -- . ":!${loop_dir_name}" 2>/dev/null || true
  if ! git -C "$repo_dir" diff --cached --quiet 2>/dev/null; then
    git -C "$repo_dir" commit -q -m "$message" --no-verify 2>/dev/null || true
  fi
}

# verify_gate_initial_checkpoint <backlog_file>
# Call once, at setup time, before computing the run's first start_sha.
# Without this, pre-existing untracked files sitting under a protected path
# from before the run even started would read as a violation on iteration 1
# -- the per-iteration checkpoint above only protects iteration 2 onward.
verify_gate_initial_checkpoint() {
  local backlog_file="$1"
  local repo_dir loop_dir_name
  repo_dir="$(git -C "$(dirname "$backlog_file")" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -z "$repo_dir" ]] && repo_dir="$(cd "$(dirname "$backlog_file")" && pwd)"
  loop_dir_name="$(basename "$(dirname "$backlog_file")")"
  _verify_gate_checkpoint "$repo_dir" "$loop_dir_name" "loop-virtuoso: run start"
}

# verify_gate_snapshot_path <file>
# A deterministic path OUTSIDE the project tree, keyed by the file's own
# absolute path. Outside the tree on purpose: the worker's Edit/Write tools,
# and any allowedTools-scoped Bash, operate within the project directory --
# a baseline stored there is reachable by the same access that tampers with
# the real file. This relies on Claude Code's own project-directory scoping
# of file tools as the actual boundary; the path itself isn't secret, being
# outside the tree is what makes it unreachable, not obscurity.
verify_gate_snapshot_path() {
  local file="$1"
  local abs_path hash
  abs_path="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  hash=$(printf '%s' "$abs_path" | cksum | cut -d' ' -f1)
  echo "${TMPDIR:-/tmp}/loop-virtuoso-snapshots/${hash}.snapshot"
}

# verify_gate_snapshot <file>
# Call once per tracked file (backlog.json, teams.json if present) right
# before handing a step's prompt to the worker -- every step, both modes.
# Without a fresh snapshot per step, the tamper check would compare against a
# stale baseline from a previous step and reject the engine's own legitimate
# status/attempts update from the iteration before as "tampering".
verify_gate_snapshot() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local snapshot_path
  snapshot_path="$(verify_gate_snapshot_path "$file")"
  mkdir -p "$(dirname "$snapshot_path")"
  cp "$file" "$snapshot_path"
}

# verify_gate_snapshot_all <backlog_file>
# Convenience wrapper callers should actually use: snapshots backlog.json and
# its sibling teams.json together, so call sites don't each need to know
# teams.json is part of the trust boundary too.
verify_gate_snapshot_all() {
  local backlog_file="$1"
  verify_gate_snapshot "$backlog_file"
  verify_gate_snapshot "$(dirname "$backlog_file")/teams.json"
}

# _verify_gate_check_tamper <file>
# Returns 0 (true) and restores $file from its snapshot if content differs;
# returns 1 (false, no tampering -- or no snapshot exists yet) otherwise.
_verify_gate_check_tamper() {
  local file="$1"
  local snapshot_path
  snapshot_path="$(verify_gate_snapshot_path "$file")"
  [[ -f "$snapshot_path" ]] || return 1
  cmp -s "$file" "$snapshot_path" && return 1
  cp "$snapshot_path" "$file"
  return 0
}

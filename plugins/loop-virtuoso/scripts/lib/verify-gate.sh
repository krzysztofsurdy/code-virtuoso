#!/bin/bash
# The deterministic completion gate.
#
# Pure function: reports pass/fail/violation/stall for one step. Never writes
# backlog.json - callers apply the result via lib/backlog.sh's
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
  # files during its turn (the plan, pipelines, or the project config layers)?
  # File-name-based protected-path matching (below) can never catch this alone -
  # .code-virtuoso is excluded from that scan entirely (it's infrastructure, not
  # work product), and even without that exclusion, rewriting verifyCommand to
  # "true" touches no path a glob would flag. Comparing file *content* against a
  # snapshot is what closes this - but ONLY if the snapshot itself lives
  # somewhere the worker's tools cannot reach, so it lives outside the project
  # tree (see verify_gate_snapshot_path), relying on Claude Code's own file-tool
  # scoping to the project directory as the actual boundary, not a convention
  # the worker happens to follow. A tracked file that did not exist at snapshot
  # time counts too: creating it mid-step is a violation and the file is removed.
  local repo_dir tampered=() f
  repo_dir="$(cv_root_for "$backlog_file")"
  while IFS= read -r f; do
    _verify_gate_check_tamper "$f" && tampered+=("${f#"${repo_dir}"/} (content tampered, restored)")
  done < <(verify_gate_tracked_files "$backlog_file")
  if [[ ${#tampered[@]} -gt 0 ]]; then
    jq -nc '{verdict: "violation", paths: $ARGS.positional}' --args "${tampered[@]}"
    return 0
  fi

  # `git diff` alone misses brand-new files, so union it with untracked but
  # not gitignored files. "Untracked" always means "new this iteration": the
  # run starts from a clean tree (loop_preflight) and every non-violation
  # iteration ends in a checkpoint commit.
  #
  # .code-virtuoso (plan, pipelines, config, state, archive) is excluded
  # entirely, not just protected: it is the loop's infrastructure, never the
  # worker's work product.
  #
  # An empty diff does NOT mean skip straight to a stall verdict. It only
  # means "no tracked-file changes this iteration", which is also what a
  # worker sees after fixing something outside git's view (a corrupted
  # gitignored vendor/ autoloader, a stale build cache) while the already
  # committed implementation was correct all along. verifyCommand is the
  # sole arbiter of done, so it always runs; an empty diff only changes how
  # a failure is classified below (stall vs fail).
  local has_changes=0 protected allowed path
  local violating=()
  protected=$(backlog_protected_paths "$backlog_file")
  allowed=$(backlog_get_config_json "$backlog_file" allowedPaths)

  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    _verify_gate_in_cv_dir "$path" && continue
    has_changes=1
    # Layer 2 of the write-boundary guard: checks the resulting tree state,
    # not which tool produced it, so it catches what PreToolUse misses.
    if backlog_path_is_protected "$path" "$protected"; then
      violating+=("$path")
    elif ! git -C "$repo_dir" cat-file -e "${start_sha}:${path}" 2>/dev/null \
         && ! _verify_gate_new_file_allowed "$path" "$allowed"; then
      # A file that did not exist at the iteration's start, outside
      # allowedPaths or with a secret-like name, is never accepted.
      violating+=("$path")
    fi
  done < <(
    {
      git -C "$repo_dir" -c core.quotepath=off diff --name-only "$start_sha" 2>/dev/null
      git -C "$repo_dir" -c core.quotepath=off ls-files --others --exclude-standard 2>/dev/null
    } | sort -u
  )

  if [[ ${#violating[@]} -gt 0 ]]; then
    _verify_gate_revert_paths "$repo_dir" "$start_sha" "${violating[@]}"
    jq -nc '{verdict: "violation", paths: $ARGS.positional}' --args "${violating[@]}"
    return 0
  fi

  local step verify_cmd exit_code output output_json
  step=$(backlog_get_step "$backlog_file" "$item_id" "$step_id")
  verify_cmd=$(echo "$step" | jq -r '.verifyCommand')

  output=$(cd "$repo_dir" && bash -c "$verify_cmd" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    # Checkpoint commit on pass or fail. A violation never reaches here: its
    # offending paths were reverted above. Without a checkpoint, an
    # iteration's uncommitted diff persists into every later iteration's
    # `git diff $start_sha`, since nothing the worker does is required to
    # commit, which would mask a true stall forever after the first real
    # change. One checkpoint per iteration keeps `start_sha` meaningful.
    _verify_gate_checkpoint "$backlog_file" "$(loop_commit_message "$backlog_file" "$item_id" "$step_id")"
    echo '{"verdict":"pass"}'
  elif [[ "$has_changes" -eq 0 ]]; then
    echo '{"verdict":"stall"}'
  else
    _verify_gate_checkpoint "$backlog_file" "$(loop_commit_message "$backlog_file" "$item_id" "$step_id")"
    output_json=$(echo "$output" | tail -n 40 | jq -Rs .)
    echo "{\"verdict\":\"fail\",\"exitCode\":$exit_code,\"output\":$output_json}"
  fi
}

# _verify_gate_in_cv_dir <repo_relative_path>
# True if the path sits under .code-virtuoso. A plain `case` inside a `$(...)`
# command substitution does not parse on bash 3.2 (macOS's default /bin/bash),
# so this lives in its own function.
_verify_gate_in_cv_dir() {
  case "$1" in
    "${CV_DIR_NAME}"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# _verify_gate_is_sensitive <repo_relative_path>
# Secret-like file names a worker must never get committed on its behalf.
_verify_gate_is_sensitive() {
  local base="${1##*/}"
  case "$base" in
    .env.example|.env.dist|.env.sample|.env.template) return 1 ;;
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|*.keystore|id_rsa*|id_ed25519*|id_ecdsa*|.npmrc|.netrc|.pgpass|*.tfstate) return 0 ;;
  esac
  return 1
}

# _verify_gate_new_file_allowed <repo_relative_path> <allowed_paths_json_or_empty>
# A new file is acceptable when its name is not secret-like and, if the
# backlog sets config.allowedPaths, it matches one of those globs. With no
# allowedPaths the whole project is allowed (protectedPaths still apply).
_verify_gate_new_file_allowed() {
  local rel="$1" allowed="$2"
  _verify_gate_is_sensitive "$rel" && return 1
  [[ -z "$allowed" || "$allowed" == "null" ]] && return 0
  backlog_path_is_protected "$rel" "$allowed"
}

# _verify_gate_revert_paths <repo_dir> <start_sha> <repo_relative_path>...
# Undoes a violation by restoring only the offending paths to their state at
# <start_sha> (tracked there) or deleting them (new this iteration). If the
# worker had already committed the offending change, the revert is committed
# too, so the next iteration's start_sha is clean and does not re-report it.
# Other changes the worker made stay in the tree untouched.
_verify_gate_revert_paths() {
  local repo_dir="${1:?}" start_sha="$2" p
  shift 2
  for p in "$@"; do
    if git -C "$repo_dir" cat-file -e "${start_sha}:${p}" 2>/dev/null; then
      git -C "$repo_dir" checkout -q "$start_sha" -- "$p" >/dev/null 2>&1 || true
    else
      git -C "$repo_dir" rm -q -f --cached --ignore-unmatch -- "$p" >/dev/null 2>&1 || true
      rm -f -- "${repo_dir:?}/${p:?}"
    fi
  done
  git -C "$repo_dir" rev-parse -q --verify HEAD >/dev/null 2>&1 || return 0
  local differing=()
  while IFS= read -r p; do
    [[ -n "$p" ]] && differing+=("$p")
  done < <(git -C "$repo_dir" -c core.quotepath=off diff --name-only HEAD -- "$@" 2>/dev/null)
  if [[ ${#differing[@]} -gt 0 ]]; then
    git -C "$repo_dir" commit -q -m "loop-virtuoso: revert violation" -- "${differing[@]}" >/dev/null 2>&1 \
      || echo "loop-virtuoso: could not commit the violation revert (a commit hook may have rejected it)" >&2
  fi
}

# _verify_gate_checkpoint <backlog_file> <message>
# Commits the iteration's work without ever touching files the loop may not
# own. Stages tracked changes (`add -u`) plus new files that pass
# _verify_gate_new_file_allowed and are not protected; anything else stays
# untracked and is never committed. Commit hooks run and are never skipped, so
# pre-commit secret scanners and linters still apply. Best effort:
# a rejected commit (hook failure, no git identity) does not fail the gate,
# it leaves start_sha stale for one more iteration.
_verify_gate_checkpoint() {
  local backlog_file="$1" message="$2"
  local repo_dir
  repo_dir="$(cv_root_for "$backlog_file")"
  git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1 || return 0

  local protected allowed path
  protected=$(backlog_protected_paths "$backlog_file")
  allowed=$(backlog_get_config_json "$backlog_file" allowedPaths)

  git -C "$repo_dir" add -u -- . ":!${CV_DIR_NAME}" >/dev/null 2>&1 || true
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    _verify_gate_in_cv_dir "$path" && continue
    backlog_path_is_protected "$path" "$protected" && continue
    _verify_gate_new_file_allowed "$path" "$allowed" || continue
    git -C "$repo_dir" add -- "$path" >/dev/null 2>&1 || true
  done < <(git -C "$repo_dir" -c core.quotepath=off ls-files --others --exclude-standard 2>/dev/null)

  if ! git -C "$repo_dir" diff --cached --quiet 2>/dev/null; then
    git -C "$repo_dir" commit -q -m "$message" >/dev/null 2>&1 \
      || echo "loop-virtuoso: checkpoint commit was rejected (a commit hook may have failed); changes stay uncommitted" >&2
  fi
}

# verify_gate_tracked_files <backlog_file>
# The loop's control files whose content the tamper check guards: the plan,
# the project pipelines, and the project config layers. They may not exist
# yet; a missing one is guarded by its absence. User-layer files live outside
# the project and are not guarded.
verify_gate_tracked_files() {
  local backlog_file="$1" root
  root="$(cv_root_for "$backlog_file")"
  echo "$backlog_file"
  echo "$(dirname "$backlog_file")/pipelines.json"
  echo "${root}/${CV_DIR_NAME}/config.json"
  echo "${root}/${CV_DIR_NAME}/config.local.json"
}

verify_gate_snapshot_dir() {
  echo "$(cv_state_home)/loop/snapshots"
}

# verify_gate_snapshot_path <file>
# A deterministic path OUTSIDE the project tree, keyed by the file's own
# absolute path, under the machine-state directory
# (${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso/loop/snapshots). Outside
# the tree on purpose: the worker's Edit/Write tools, and any allowedTools-scoped
# Bash, operate within the project directory -- a baseline stored there is
# reachable by the same access that tampers with the real file. This relies on
# Claude Code's own project-directory scoping of file tools as the actual
# boundary; the path itself isn't secret, being outside the tree is what makes
# it unreachable, not obscurity.
verify_gate_snapshot_path() {
  local file="$1"
  local abs_path hash
  abs_path="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
  hash=$(printf '%s' "$abs_path" | cksum | cut -d' ' -f1)
  echo "$(verify_gate_snapshot_dir)/${hash}.snapshot"
}

# verify_gate_snapshot <file>
# Records the file's content, or its absence (a <hash>.absent marker), so the
# check can tell "edited" and "created" from "unchanged".
verify_gate_snapshot() {
  local file="$1" snapshot_path
  snapshot_path="$(verify_gate_snapshot_path "$file")"
  mkdir -p "$(dirname "$snapshot_path")"
  rm -f "$snapshot_path" "${snapshot_path%.snapshot}.absent"
  if [[ -f "$file" ]]; then
    cp "$file" "$snapshot_path"
  else
    : > "${snapshot_path%.snapshot}.absent"
  fi
}

# verify_gate_snapshot_all <backlog_file>
# Call right before handing a step's prompt to the worker - every step, both
# modes. Without a fresh snapshot per step the tamper check would compare
# against a stale baseline. Snapshots every file in verify_gate_tracked_files,
# so call sites don't each need to know the trust boundary.
verify_gate_snapshot_all() {
  local f
  while IFS= read -r f; do
    verify_gate_snapshot "$f"
  done < <(verify_gate_tracked_files "$1")
}

# verify_gate_snapshot_cleanup <backlog_file>
# Removes the out-of-tree snapshots once a run ends (any stop reason, or
# cancel), so nothing accumulates under the machine-state directory.
verify_gate_snapshot_cleanup() {
  local f snapshot_path
  while IFS= read -r f; do
    snapshot_path="$(verify_gate_snapshot_path "$f")"
    rm -f "${snapshot_path:?}" "${snapshot_path%.snapshot}.absent"
  done < <(verify_gate_tracked_files "$1")
  rmdir "$(verify_gate_snapshot_dir)" 2>/dev/null || true
}

# _verify_gate_check_tamper <file>
# Returns 0 (true) after undoing a change: the file is restored from its
# snapshot when its content differs, or deleted when it did not exist at
# snapshot time. Returns 1 (no tampering, or no snapshot exists yet) otherwise.
_verify_gate_check_tamper() {
  local file="$1" snapshot_path absent
  snapshot_path="$(verify_gate_snapshot_path "$file")"
  absent="${snapshot_path%.snapshot}.absent"
  if [[ -f "$absent" ]]; then
    [[ -e "$file" ]] || return 1
    rm -f "$file"
    return 0
  fi
  [[ -f "$snapshot_path" ]] || return 1
  cmp -s "$file" "$snapshot_path" && return 1
  cp "$snapshot_path" "$file"
  return 0
}

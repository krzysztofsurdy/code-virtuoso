#!/bin/bash
# Start-of-run checks shared by Mode A (setup-start.sh) and Mode B
# (run-batch.sh), plus the git-root helpers every script and hook uses to find
# the loop's session file.
#
# The loop commits checkpoints, so it only ever starts from a clean tree, on
# the branch the backlog names, never on the repository's default branch.

PREFLIGHT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOOP_DIR_NAME=".delivery-loop"

# loop_repo_root <dir>
# Echoes the git top-level directory containing <dir>, or nothing.
loop_repo_root() {
  git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || true
}

# loop_session_file <repo_root>
# The one place the session file lives: <git root>/.delivery-loop. Hooks and
# scripts all resolve it from the git root, so starting or running from a
# subdirectory finds the same file.
loop_session_file() {
  echo "${1}/${LOOP_DIR_NAME}/session.local.json"
}

# loop_default_backlog <dir>
# <git root of dir>/.delivery-loop/backlog.json, or the cwd-relative
# fallback when <dir> is not in a repository.
loop_default_backlog() {
  local root
  root="$(loop_repo_root "${1:-.}")"
  if [[ -n "$root" ]]; then
    echo "${root}/${LOOP_DIR_NAME}/backlog.json"
  else
    echo "${LOOP_DIR_NAME}/backlog.json"
  fi
}

# _preflight_is_default_branch <repo> <branch>
_preflight_is_default_branch() {
  local repo="$1" branch="$2" origin_head
  case "$branch" in
    main|master) return 0 ;;
  esac
  origin_head="$(git -C "$repo" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" && "${origin_head#*/}" == "$branch" ]]
}

# loop_preflight <backlog_file>
# Hard gate. Exits the calling script (status 1) with a clear message when
# the run must not start. Sets LOOP_REPO_ROOT and LOOP_BACKLOG_ABS on success.
#   1. the backlog validates
#   2. the backlog sits in a .delivery-loop directory inside a git repository
#   3. backlog.branch is set and is not the repository's default branch
#   4. no modified or untracked files exist outside the loop directory
#   5. the current branch is backlog.branch (switched or created, tree is clean)
loop_preflight() {
  local backlog_file="$1"

  if [[ ! -f "$backlog_file" ]]; then
    echo "Error: backlog file not found: $backlog_file" >&2
    exit 1
  fi
  if [[ -f "${PREFLIGHT_LIB_DIR}/../validate-backlog.sh" ]]; then
    bash "${PREFLIGHT_LIB_DIR}/../validate-backlog.sh" "$backlog_file" || {
      echo "Error: backlog validation failed" >&2
      exit 1
    }
  else
    echo "Error: validate-backlog.sh not found; refusing to run without validation" >&2
    exit 1
  fi

  local loop_dir
  loop_dir="$(cd "$(dirname "$backlog_file")" && pwd -P)"
  LOOP_BACKLOG_ABS="${loop_dir}/$(basename "$backlog_file")"
  if [[ "$(basename "$loop_dir")" != "$LOOP_DIR_NAME" ]]; then
    echo "Error: the backlog must live in a ${LOOP_DIR_NAME} directory inside the repository (got: $loop_dir)" >&2
    exit 1
  fi
  LOOP_REPO_ROOT="$(loop_repo_root "$loop_dir")"
  if [[ -z "$LOOP_REPO_ROOT" ]]; then
    echo "Error: ${loop_dir} is not inside a git repository; the loop needs git for checkpoints and the write-boundary audit" >&2
    exit 1
  fi
  LOOP_REPO_ROOT="$(cd "$LOOP_REPO_ROOT" && pwd -P)"

  local target current
  target="$(jq -r '.branch // empty' "$LOOP_BACKLOG_ABS")"
  if [[ -z "$target" ]]; then
    echo "Error: backlog has no branch; set \"branch\" to the feature branch the loop should run on" >&2
    exit 1
  fi
  if _preflight_is_default_branch "$LOOP_REPO_ROOT" "$target"; then
    echo "Error: backlog branch \"$target\" is the repository's default branch; the loop only runs on a feature branch" >&2
    exit 1
  fi

  local loop_rel="${loop_dir#"${LOOP_REPO_ROOT}"/}" dirty
  dirty="$(git -C "$LOOP_REPO_ROOT" -c core.quotepath=off status --porcelain --untracked-files=all \
    -- . ":(exclude)${loop_rel}" ":(exclude)${LOOP_DIR_NAME}" 2>/dev/null | head -n 10)"
  if [[ -n "$dirty" ]]; then
    {
      echo "Error: the working tree has modified or untracked files outside ${LOOP_DIR_NAME}/."
      echo "The loop commits checkpoints and never commits files it did not create, so please commit or stash them first:"
      echo "$dirty" | sed 's/^/  /'
    } >&2
    exit 1
  fi

  current="$(git -C "$LOOP_REPO_ROOT" symbolic-ref --short -q HEAD 2>/dev/null || true)"
  if [[ "$current" != "$target" ]]; then
    if git -C "$LOOP_REPO_ROOT" show-ref --verify --quiet "refs/heads/${target}"; then
      git -C "$LOOP_REPO_ROOT" checkout -q "$target" || {
        echo "Error: could not switch to branch \"$target\"" >&2
        exit 1
      }
      echo "loop-virtuoso: switched to existing branch ${target} (was ${current:-detached HEAD})"
    else
      git -C "$LOOP_REPO_ROOT" checkout -q -b "$target" || {
        echo "Error: could not create branch \"$target\"" >&2
        exit 1
      }
      echo "loop-virtuoso: created branch ${target} from ${current:-detached HEAD}"
    fi
  fi
}

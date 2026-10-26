#!/bin/bash
# Path helpers shared by the PreToolUse guards and the verify gate: symlink-safe
# path resolution and project-relative glob matching.

# paths_resolve <path>
# Resolves the longest EXISTING prefix of <path> via `pwd -P`, re-appending
# whatever trailing segments don't exist yet unresolved - a path that isn't
# there yet can't itself be a symlink, so there's nothing to resolve in it.
# A brand-new file inside a not-yet-created directory (e.g. Write creating
# the first file under a fresh tests/ dir) used to fall straight back to the
# fully-unresolved path when `cd` failed outright, which broke the
# comparison whenever an ancestor ABOVE the missing directory was itself a
# symlink (macOS's /tmp -> /private/tmp, the same case already handled for
# existing paths) - walking up to the nearest real ancestor closes that gap
# for missing paths too.
paths_resolve() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" 2>/dev/null && pwd -P) || echo "$path"
    return
  fi
  local dir base suffix=""
  dir="$(dirname "$path")"
  base="$(basename "$path")"
  while [[ ! -d "$dir" && "$dir" != "/" ]]; do
    suffix="$(basename "$dir")/${suffix}"
    dir="$(dirname "$dir")"
  done
  local resolved_dir
  resolved_dir="$(cd "$dir" 2>/dev/null && pwd -P || echo "$dir")"
  echo "${resolved_dir}/${suffix}${base}"
}

# paths_relative_to <root> <path>
# <path> relative to <root>, both resolved through paths_resolve first:
# comparing raw strings broke whenever Claude Code resolved one of them
# through a symlink and not the other. A path outside <root> comes back
# resolved but absolute.
paths_relative_to() {
  local root path
  root="$(paths_resolve "$1")"
  path="$(paths_resolve "$2")"
  case "$path" in
    "$root"/*) echo "${path#"$root"/}" ;;
    *) echo "$path" ;;
  esac
}

# paths_match_any <path> <globs_json_array>
# Bash's case-pattern glob already matches "*" across "/", so "tests/**" and
# "tests/*" behave identically here - no special globstar handling needed.
paths_match_any() {
  local path="$1" patterns_json="$2"
  local pattern
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # shellcheck disable=SC2254
    case "$path" in
      $pattern) return 0 ;;
    esac
  done < <(echo "$patterns_json" | jq -r '.[]')
  return 1
}

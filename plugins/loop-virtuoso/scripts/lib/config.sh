#!/bin/bash
# Paths and shared config for the loop, following spec/config-spec.md.
#
#   plan (committed)   <root>/.code-virtuoso/loop/backlog.json, pipelines.json
#   run state (ignored) <root>/.code-virtuoso/loop/state/
#   archive (committed) <root>/.code-virtuoso/loop/archive/
#   user layer          ${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}
#   machine state       ${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso
#
# Settings come from the merged config layers (user, project shared, project
# local). A key set in the backlog's own "config" object wins over them.

CV_DIR_NAME=".code-virtuoso"
CV_DEFAULT_TEST_GLOBS='["tests/**","**/*Test.php","**/*_test.*","**/*.spec.*","**/test_*.py"]'

# cv_root_for <path-to-backlog-or-dir>
# <root> for a backlog at <root>/.code-virtuoso/loop/backlog.json; otherwise the
# git top-level of the path's directory, else that directory.
cv_root_for() {
  local path="$1" dir loop_dir cv_dir
  if [[ -d "$path" ]]; then dir="$path"; else dir="$(dirname "$path")"; fi
  dir="$(cd "$dir" 2>/dev/null && pwd -P)" || { echo "."; return; }
  loop_dir="$dir"
  cv_dir="$(dirname "$loop_dir")"
  if [[ "$(basename "$loop_dir")" == "loop" && "$(basename "$cv_dir")" == "$CV_DIR_NAME" ]]; then
    dirname "$cv_dir"
    return
  fi
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir"
}

cv_config_home() {
  echo "${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}"
}

cv_state_home() {
  echo "${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso"
}

# cv_config_files <root>: the existing config layers, lowest precedence first.
cv_config_files() {
  local root="$1" f
  for f in "$(cv_config_home)/config.json" "$root/$CV_DIR_NAME/config.json" "$root/$CV_DIR_NAME/config.local.json"; do
    [[ -f "$f" ]] && echo "$f"
  done
  return 0
}

# cv_merged_config <root>
# Deep-merged config (objects merge, arrays and scalars replace). A layer that
# is not valid JSON is skipped; validate-backlog.sh reports it.
cv_merged_config() {
  local root="$1" f files=()
  while IFS= read -r f; do
    [[ -n "$f" ]] && jq empty "$f" >/dev/null 2>&1 && files+=("$f")
  done < <(cv_config_files "$root")
  if [[ ${#files[@]} -gt 0 ]]; then
    jq -s 'reduce .[] as $x ({}; . * $x)' "${files[@]}"
  else
    echo '{}'
  fi
}

# cv_loop_setting <root> <key>: one key of the "loop" namespace as compact JSON; nothing if unset.
cv_loop_setting() {
  cv_merged_config "$1" | jq -c --arg key "$2" '.loop[$key] // empty'
}

# cv_guard_setting <root> <key>: one key of loop.guard as compact JSON; nothing if unset or false.
cv_guard_setting() {
  cv_merged_config "$1" | jq -c --arg key "$2" '(.loop.guard[$key])? // empty'
}

# cv_test_globs <root>: loop.guard.testGlobs when it is an array, else the default.
cv_test_globs() {
  local globs
  globs="$(cv_guard_setting "$1" testGlobs)"
  [[ "$(echo "${globs:-null}" | jq -r 'type')" == "array" ]] || globs="$CV_DEFAULT_TEST_GLOBS"
  echo "$globs"
}

# cv_ensure_gitignore <root>
# Creates <root>/.code-virtuoso/.gitignore with the spec lines, or appends the
# lines an existing file lacks. Never rewrites what is already there.
cv_ensure_gitignore() {
  local root="$1" file line
  file="$root/$CV_DIR_NAME/.gitignore"
  mkdir -p "$root/$CV_DIR_NAME"
  [[ -f "$file" ]] || : > "$file"
  for line in '*.local.json' 'loop/state/'; do
    grep -qxF -- "$line" "$file" && continue
    [[ -s "$file" && -n "$(tail -c 1 "$file")" ]] && printf '\n' >> "$file"
    printf '%s\n' "$line" >> "$file"
  done
}

# loop_state_dir <backlog_file>: the run-state directory, created (with the .gitignore) on demand.
loop_state_dir() {
  local dir
  dir="$(dirname "$1")/state"
  if [[ ! -d "$dir" ]]; then
    cv_ensure_gitignore "$(cv_root_for "$1")"
    mkdir -p "$dir"
  fi
  echo "$dir"
}

# loop_commit_message <backlog_file> <item_id> <step_id>
# Applies ticket-delivery.commitFormat when the project sets one. Placeholders:
# {ticket} (first match of ticket-delivery.ticketIdPattern in backlog.branch),
# {summary} ("<item title> (<item>/<step>)"), {item}, {step}.
# Falls back to "loop-virtuoso: <item>/<step>" when there is no format or the
# format needs a ticket that cannot be resolved.
loop_commit_message() {
  local file="$1" item_id="$2" step_id="$3"
  local fallback="loop-virtuoso: ${item_id}/${step_id}"
  local cfg format pattern branch ticket="" title summary
  cfg="$(cv_merged_config "$(cv_root_for "$file")")"
  format="$(echo "$cfg" | jq -r '.["ticket-delivery"].commitFormat // empty')"
  [[ -n "$format" ]] || { echo "$fallback"; return; }
  if [[ "$format" == *"{ticket}"* ]]; then
    pattern="$(echo "$cfg" | jq -r '.["ticket-delivery"].ticketIdPattern // empty')"
    branch="$(jq -r '.branch // empty' "$file")"
    if [[ -n "$pattern" && -n "$branch" ]]; then
      ticket="$(jq -rn --arg p "$pattern" --arg s "$branch" '[$s | match($p).string] | first // empty' 2>/dev/null || true)"
    fi
    [[ -n "$ticket" ]] || { echo "$fallback"; return; }
  fi
  title="$(jq -r --arg id "$item_id" '.items[] | select(.id == $id) | .title' "$file")"
  summary="${title} (${item_id}/${step_id})"
  format="${format//\{ticket\}/$ticket}"
  format="${format//\{summary\}/$summary}"
  format="${format//\{item\}/$item_id}"
  format="${format//\{step\}/$step_id}"
  echo "$format"
}

# loop_branch_name <ticket-or-empty> <title> <root>
# Branch name from ticket-delivery.branchPattern (default "feat/{slug}").
# Placeholders: {ticket}, {slug} (lowercase, underscores, at most 50 characters).
# Returns 1 when the pattern needs a ticket and none was given.
loop_branch_name() {
  local ticket="$1" title="$2" root="$3" pattern slug
  pattern="$(cv_merged_config "$root" | jq -r '.["ticket-delivery"].branchPattern // empty')"
  [[ -n "$pattern" ]] || pattern="feat/{slug}"
  if [[ "$pattern" == *"{ticket}"* && -z "$ticket" ]]; then
    echo "branch pattern \"$pattern\" needs a ticket id; pass --ticket" >&2
    return 1
  fi
  slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\{1,\}/_/g' -e 's/^_*//' -e 's/_*$//' | cut -c1-50 | sed -e 's/_*$//')"
  pattern="${pattern//\{ticket\}/$ticket}"
  echo "${pattern//\{slug\}/$slug}"
}

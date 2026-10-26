#!/bin/bash
# Claude Code statusLine command: reads the statusline JSON on stdin and prints
# one line: dir | branch | model | $cost | ctx N% | loop i/max.
#
# Field names follow https://code.claude.com/docs/en/statusline: workspace.current_dir
# (else cwd), model.display_name, cost.total_cost_usd, context_window.used_percentage.
# A missing field drops its segment; bad input prints an empty line. It never
# fails and never touches the network.
#
# Self-contained on purpose: /loop-virtuoso:harden copies this file to the user
# config home so the statusLine path survives plugin updates, so it must not
# source anything from the plugin. The loop segment mirrors status.sh: the
# session file at <git root>/.code-virtuoso/loop/state/session.local.json, the
# max from the backlog's config, then the loop namespace of the config layers,
# then 30 (the engine's default).

input="$(cat)"
fields="$(printf '%s' "$input" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.cost.total_cost_usd // "" | tostring),
    (.context_window.used_percentage // "" | if type == "number" then floor | tostring else "" end)
  ] | join("\u001f")' 2>/dev/null)" || fields=""

IFS=$'\x1f' read -r dir model cost pct <<< "$fields"

segments=()
root=""
if [[ -n "$dir" && -d "$dir" ]]; then
  segments+=("$(basename "$dir")")
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" ]]; then
    branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null || true)"
    [[ -n "$branch" ]] && segments+=("$branch")
  fi
fi
[[ -n "$model" ]] && segments+=("$model")
[[ "$cost" =~ ^[0-9.eE+-]+$ ]] && segments+=("$(LC_ALL=C printf '$%.2f' "$cost" 2>/dev/null)")
[[ -n "$pct" ]] && segments+=("ctx ${pct}%")

# loop_segment <git root>: "loop i/max" while a loop session is active, else nothing.
loop_segment() {
  local root="$1" session backlog iteration max config_home f layers=()
  session="${root}/.code-virtuoso/loop/state/session.local.json"
  [[ -f "$session" ]] || return 0
  iteration="$(jq -r 'select(.active == true) | .iteration // empty' "$session" 2>/dev/null)"
  [[ -n "$iteration" ]] || return 0
  backlog="$(jq -r '.backlogFile // empty' "$session" 2>/dev/null)"
  [[ -n "$backlog" && -f "$backlog" ]] && max="$(jq -r '.config.maxIterations // empty' "$backlog" 2>/dev/null)"
  if [[ -z "$max" ]]; then
    config_home="${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}"
    for f in "$config_home/config.json" "$root/.code-virtuoso/config.json" "$root/.code-virtuoso/config.local.json"; do
      [[ -f "$f" ]] && jq empty "$f" >/dev/null 2>&1 && layers+=("$f")
    done
    if [[ ${#layers[@]} -gt 0 ]]; then
      max="$(jq -rs 'reduce .[] as $x ({}; . * $x) | .loop.maxIterations // empty' "${layers[@]}" 2>/dev/null)"
    fi
  fi
  echo "loop ${iteration}/${max:-30}"
}

if [[ -n "$root" ]]; then
  loop="$(loop_segment "$root")"
  [[ -n "$loop" ]] && segments+=("$loop")
fi

line=""
for segment in ${segments[@]+"${segments[@]}"}; do
  line="${line:+$line | }$segment"
done
printf '%s\n' "$line"
exit 0

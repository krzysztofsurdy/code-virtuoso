#!/bin/bash
# Read/write helpers for .delivery-loop/backlog.json.
#
# Every item is a sequence of steps; there is no flat item-level verifyCommand
# any more. A single-step item is just a one-element steps array. Item status
# is never stored -- it's derived from its steps every time, so there's one
# source of truth instead of two that can drift apart.
#
# Only this file may write a step's status/attempts/notes. That boundary is
# what makes "verified" a script's output, not an agent's claim.
#
# All functions take the backlog file path as the first argument.

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./events.sh
source "$LIB_DIR/events.sh"

backlog_atomic_write() {
  local file="$1" content="$2"
  local tmp="${file}.tmp.$$"
  printf '%s' "$content" > "$tmp"
  mv "$tmp" "$file"
}

# Derived per-item status: verified iff every step is verified, blocked iff
# any step is blocked (steps run in array order, so a blocked step always
# means every step after it is also stuck), else pending.
_backlog_item_status_filter='
  if (.steps | length) == 0 then "pending"
  elif (.steps | all(.status == "verified")) then "verified"
  elif (.steps | any(.status == "blocked")) then "blocked"
  else "pending" end
'

backlog_item_status() {
  local file="$1" item_id="$2"
  jq -r --arg id "$item_id" ".items[] | select(.id == \$id) | ($_backlog_item_status_filter)" "$file"
}

# backlog_next_pending_step <file>
# The lowest-priority item that isn't fully verified, and within it, the
# first step not yet verified -- only if that step is "pending". If that
# step is "blocked" the whole item is stuck and is skipped entirely; later
# steps in a blocked item never become eligible on their own.
backlog_next_pending_step() {
  local file="$1"
  jq -c '
    [.items[] | select(.steps | length > 0)] | sort_by(.priority) |
    map(
      . as $item |
      ($item.steps | map(select(.status != "verified")) | first) as $next |
      if $next == null or $next.status == "blocked" then empty
      else {itemId: $item.id, itemTitle: $item.title, itemPriority: $item.priority, step: $next}
      end
    ) | first // empty
  ' "$file"
}

backlog_get_item() {
  local file="$1" id="$2"
  jq -c --arg id "$id" '.items[] | select(.id == $id)' "$file"
}

backlog_get_step() {
  local file="$1" item_id="$2" step_id="$3"
  jq -c --arg iid "$item_id" --arg sid "$step_id" \
    '.items[] | select(.id == $iid) | .steps[] | select(.id == $sid)' "$file"
}

step_mark_status() {
  local file="$1" item_id="$2" step_id="$3" status="$4"
  local updated
  updated=$(jq --arg iid "$item_id" --arg sid "$step_id" --arg status "$status" \
    '(.items[] | select(.id == $iid) | .steps[] | select(.id == $sid) | .status) = $status' "$file")
  backlog_atomic_write "$file" "$updated"
}

step_increment_attempts() {
  local file="$1" item_id="$2" step_id="$3"
  local updated
  updated=$(jq --arg iid "$item_id" --arg sid "$step_id" \
    '(.items[] | select(.id == $iid) | .steps[] | select(.id == $sid) | .attempts) += 1' "$file")
  backlog_atomic_write "$file" "$updated"
  jq -r --arg iid "$item_id" --arg sid "$step_id" \
    '.items[] | select(.id == $iid) | .steps[] | select(.id == $sid) | .attempts' "$file"
}

step_set_note() {
  local file="$1" item_id="$2" step_id="$3" note="$4"
  local updated
  updated=$(jq --arg iid "$item_id" --arg sid "$step_id" --arg note "$note" \
    '(.items[] | select(.id == $iid) | .steps[] | select(.id == $sid) | .notes) = $note' "$file")
  backlog_atomic_write "$file" "$updated"
}

# step_apply_verdict <file> <item_id> <step_id> <verdict_json> <max_attempts>
# The only place a verify-gate verdict turns into a backlog write. Both run
# modes call this instead of each re-deriving pass/fail/blocked handling --
# one implementation, one place that emits the matching event.
# Echoes {"action": "verified"|"failed"|"blocked"|"violation"|"stall"}.
step_apply_verdict() {
  local file="$1" item_id="$2" step_id="$3" verdict_json="$4" max_attempts="$5"
  local verdict action
  verdict=$(echo "$verdict_json" | jq -r '.verdict')

  case "$verdict" in
    pass)
      step_mark_status "$file" "$item_id" "$step_id" "verified"
      action="verified"
      ;;
    fail)
      local new_attempts note
      new_attempts=$(step_increment_attempts "$file" "$item_id" "$step_id")
      note=$(echo "$verdict_json" | jq -r '.output // ""')
      step_set_note "$file" "$item_id" "$step_id" "$note"
      if [[ "$new_attempts" =~ ^[0-9]+$ ]] && (( new_attempts >= max_attempts )); then
        step_mark_status "$file" "$item_id" "$step_id" "blocked"
        action="blocked"
      else
        action="failed"
      fi
      ;;
    violation|stall)
      action="$verdict"
      ;;
    *)
      action="unknown"
      ;;
  esac

  events_emit "$file" "step_verdict" \
    "$(jq -nc --arg item "$item_id" --arg step "$step_id" --arg action "$action" --argjson verdict "$verdict_json" \
       '{itemId: $item, stepId: $step, action: $action, verdict: $verdict}')"

  if [[ "$action" == "verified" || "$action" == "blocked" ]]; then
    local item_status
    item_status=$(backlog_item_status "$file" "$item_id")
    if [[ "$item_status" == "verified" || "$item_status" == "blocked" ]]; then
      events_emit "$file" "item_${item_status}" "$(jq -nc --arg item "$item_id" '{itemId: $item}')"
    fi
  fi

  jq -nc --arg action "$action" '{action: $action}'
}

# Item-level view, item status derived per backlog_item_status.
backlog_counts() {
  local file="$1"
  jq -c "{
    total: (.items | length),
    pending: ([.items[] | select($_backlog_item_status_filter == \"pending\")] | length),
    verified: ([.items[] | select($_backlog_item_status_filter == \"verified\")] | length),
    blocked: ([.items[] | select($_backlog_item_status_filter == \"blocked\")] | length)
  }" "$file"
}

# Step-level view -- finer-grained progress than backlog_counts.
backlog_step_counts() {
  local file="$1"
  jq -c '{
    total: ([.items[].steps[]] | length),
    pending: ([.items[].steps[] | select(.status == "pending")] | length),
    verified: ([.items[].steps[] | select(.status == "verified")] | length),
    blocked: ([.items[].steps[] | select(.status == "blocked")] | length)
  }' "$file"
}

backlog_blocked_items_report() {
  local file="$1"
  jq -c "[.items[] | select($_backlog_item_status_filter == \"blocked\") |
    . as \$item | (\$item.steps[] | select(.status == \"blocked\") | {itemId: \$item.id, itemTitle: \$item.title, stepId: .id, notes: .notes})]" "$file"
}

backlog_get_config() {
  local file="$1" key="$2"
  jq -r --arg key "$key" '.config[$key] // empty' "$file"
}

backlog_get_config_json() {
  local file="$1" key="$2"
  jq -c --arg key "$key" '.config[$key] // empty' "$file"
}

# Always includes the backlog file's own path and its sibling teams.json,
# expressed the same cwd-relative way callers express every other path here
# (".delivery-loop/backlog.json") -- an earlier version passed $file through
# as-is, which was whatever absolute/relative form the caller happened to
# resolve it to, and silently never matched the relative paths it was being
# compared against.
#
# This closes the Edit/Write vector for both files (layer 1, real time) and
# the git-diff-audit vector for anything outside the loop's own excluded
# directory (layer 2). It does NOT close the content-tamper vector on its
# own -- a worker with a bare-interpreter Bash grant can rewrite either
# file's content without ever calling Edit/Write or touching a path outside
# the excluded loop directory. That's what verify-gate.sh's snapshot-based
# tamper check is for, and why it matters more than this glob ever could.
backlog_protected_paths() {
  local file="$1"
  local loop_dir backlog_rel teams_rel
  loop_dir="$(basename "$(dirname "$file")")"
  backlog_rel="${loop_dir}/$(basename "$file")"
  teams_rel="${loop_dir}/teams.json"
  jq -c --arg self "$backlog_rel" --arg teams "$teams_rel" \
    '(.config.protectedPaths // []) + [$self, $teams]' "$file"
}

# backlog_path_is_protected <path> <protected_paths_json_array>
# Bash's case-pattern glob already matches "*" across "/", so "tests/**" and
# "tests/*" behave identically here -- no special globstar handling needed.
backlog_path_is_protected() {
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

# backlog_build_step_prompt <item_json> <step_json> <participant_json>
# Regenerated fresh every iteration from the backlog, never a stored string.
# participant_json may be "null" (or empty) for a step with no assigned
# participant -- it's just dropped from the prompt.
backlog_build_step_prompt() {
  local item_json="$1" step_json="$2" participant_json="${3:-null}"
  local item_id item_title item_desc crit step_id instructions verify
  item_id=$(echo "$item_json" | jq -r '.id')
  item_title=$(echo "$item_json" | jq -r '.title')
  item_desc=$(echo "$item_json" | jq -r '.description')
  crit=$(echo "$item_json" | jq -r '.acceptanceCriteria | map("- " + .) | join("\n")')
  step_id=$(echo "$step_json" | jq -r '.id')
  instructions=$(echo "$step_json" | jq -r '.instructions')
  verify=$(echo "$step_json" | jq -r '.verifyCommand')

  local framing=""
  if [[ -n "$participant_json" && "$participant_json" != "null" ]]; then
    local kind
    kind=$(echo "$participant_json" | jq -r '.kind // empty')
    if [[ "$kind" == "agent" ]]; then
      local agent_name
      agent_name=$(echo "$participant_json" | jq -r '.agent')
      framing=$'\n'"For this step, delegate to the \`${agent_name}\` subagent via the Task tool and wait for its result before continuing."
    elif [[ "$kind" == "persona" ]]; then
      local system_prompt
      system_prompt=$(echo "$participant_json" | jq -r '.systemPrompt // empty')
      framing=$'\n'"For this step, act as: ${system_prompt}"
    fi
  fi

  cat <<PROMPT
Backlog item ${item_id}: ${item_title}
Step: ${step_id}

${item_desc}

Acceptance criteria:
${crit}

This step's task:
${instructions}
${framing}

When you believe this step is done, do not declare completion yourself. The
following command is what actually decides it, run automatically after you
stop:

  ${verify}

Make that command pass. Do not edit it, any test files, or
.delivery-loop/backlog.json directly -- those are off limits and changes to
them are rejected and not counted toward this step.
PROMPT
}

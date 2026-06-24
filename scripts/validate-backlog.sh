#!/bin/bash
# Validate a backlog before a run. Collects every problem, prints a ✓/✗
# checklist, exits 1 on any failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/teams.sh
source "${SCRIPT_DIR}/lib/teams.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: validate-backlog.sh <path-to-backlog.json>" >&2
  exit 1
fi

file="$1"

problems=()
warnings=()

emit_check() {
  # emit_check <ok|fail> <message>
  if [[ "$1" == "ok" ]]; then
    printf '  \xe2\x9c\x93 %s\n' "$2"
  else
    printf '  \xe2\x9c\x97 %s\n' "$2"
  fi
}

echo "Validating backlog: $file"
echo

# --- File exists and parses as JSON --------------------------------------
if [[ ! -f "$file" ]]; then
  emit_check fail "file exists"
  echo
  echo "FAIL: backlog file does not exist."
  exit 1
fi
emit_check ok "file exists"

if ! jq empty "$file" >/dev/null 2>&1; then
  emit_check fail "valid JSON"
  echo
  echo "FAIL: backlog file is not valid JSON."
  exit 1
fi
emit_check ok "valid JSON"

# --- Top-level keys ------------------------------------------------------
for key in project branch description config items; do
  if [[ "$(jq "has(\"$key\")" "$file")" == "true" ]]; then
    emit_check ok "top-level \"$key\" present"
  else
    emit_check fail "top-level \"$key\" present"
    problems+=("missing top-level key: $key")
  fi
done

# --- config keys ---------------------------------------------------------
for key in maxIterations maxAttemptsPerItem maxStallIterations maxViolations permissionMode; do
  if [[ "$(jq ".config | has(\"$key\")" "$file" 2>/dev/null)" == "true" ]]; then
    emit_check ok "config.$key present"
  else
    emit_check fail "config.$key present"
    problems+=("missing config key: $key")
  fi
done

# protectedPaths: non-empty array
case "$(jq -r '.config.protectedPaths | if type == "array" then (if length > 0 then "ok" else "empty" end) else "notarray" end' "$file" 2>/dev/null)" in
  ok)       emit_check ok "config.protectedPaths is a non-empty array" ;;
  empty)    emit_check fail "config.protectedPaths is a non-empty array"; problems+=("config.protectedPaths is empty") ;;
  *)        emit_check fail "config.protectedPaths is a non-empty array"; problems+=("config.protectedPaths is missing or not an array") ;;
esac

# allowedTools: array
case "$(jq -r '.config.allowedTools | if type == "array" then "ok" else "notarray" end' "$file" 2>/dev/null)" in
  ok) emit_check ok "config.allowedTools is an array" ;;
  *)  emit_check fail "config.allowedTools is an array"; problems+=("config.allowedTools is missing or not an array") ;;
esac

# --- items ---------------------------------------------------------------
items_is_array="$(jq -r '.items | type' "$file" 2>/dev/null || echo "null")"
if [[ "$items_is_array" != "array" ]]; then
  emit_check fail "items is an array"
  problems+=("items is missing or not an array")
else
  item_count="$(jq '.items | length' "$file")"
  if [[ "$item_count" -eq 0 ]]; then
    emit_check fail "items array is non-empty"
    problems+=("items array is empty")
  else
    emit_check ok "items is a non-empty array ($item_count items)"

    # One jq pass: item-level fields, then every step's fields, then
    # within-item step-id uniqueness. One problem line per offending field.
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      problems+=("$line")
    done < <(jq -r '
      .items | to_entries[] |
      .key as $i | .value as $it |
      ("item[" + ($i|tostring) + "]" + (if ($it.id|type) == "string" and ($it.id|length) > 0 then " (" + $it.id + ")" else "" end)) as $ref |
      (
        [
          (if ($it.id|type) == "string" and ($it.id|length) > 0 then empty else $ref + ": missing or empty id" end),
          (if ($it.title|type) == "string" and ($it.title|length) > 0 then empty else $ref + ": missing or empty title" end),
          (if ($it.description|type) == "string" and ($it.description|length) > 0 then empty else $ref + ": missing or empty description" end),
          (if ($it.acceptanceCriteria|type) == "array" and ($it.acceptanceCriteria|length) > 0 then empty else $ref + ": acceptanceCriteria missing or empty" end),
          (if ($it.priority|type) == "number" then empty else $ref + ": priority missing or not numeric" end),
          (if ($it.steps|type) == "array" and ($it.steps|length) > 0 then empty else $ref + ": steps missing or empty" end)
        ]
        + (if ($it.steps|type) == "array" then
            ($it.steps | to_entries | map(
              .key as $j | .value as $st |
              ($ref + " step[" + ($j|tostring) + "]" + (if ($st.id|type) == "string" and ($st.id|length) > 0 then " (" + $st.id + ")" else "" end)) as $sref |
              [
                (if ($st.id|type) == "string" and ($st.id|length) > 0 then empty else $sref + ": missing or empty id" end),
                (if ($st.instructions|type) == "string" and ($st.instructions|length) > 0 then empty else $sref + ": missing or empty instructions" end),
                (if ($st.verifyCommand|type) == "string" and ($st.verifyCommand|length) > 0 then empty else $sref + ": verifyCommand missing or empty" end),
                (if ($st.status|type) == "string" and (["pending","verified","blocked"] | index($st.status)) != null then empty else $sref + ": status must be pending/verified/blocked" end),
                (if ($st.attempts|type) == "number" then empty else $sref + ": attempts missing or not numeric" end)
              ]
            ) | add // [])
          else [] end)
        + (if ($it.steps|type) == "array" then
            ([$it.steps[].id | select(type == "string")] | group_by(.) | map(select(length > 1) | .[0]) | map($ref + ": duplicate step id within item: " + .))
          else [] end)
      ) | .[]
    ' "$file")

    # Per-item/step summary check line
    item_problem_count=0
    for p in "${problems[@]+"${problems[@]}"}"; do
      [[ "$p" == item\[* ]] && item_problem_count=$((item_problem_count + 1))
    done
    if [[ "$item_problem_count" -eq 0 ]]; then
      emit_check ok "all items and steps have required fields"
    else
      emit_check fail "all items and steps have required fields ($item_problem_count problem(s))"
    fi

    # Duplicate ids
    dup_ids="$(jq -r '[.items[].id | select(. != null)] | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$file" 2>/dev/null || true)"
    if [[ -z "$dup_ids" ]]; then
      emit_check ok "no duplicate item ids"
    else
      emit_check fail "no duplicate item ids"
      while IFS= read -r d; do
        [[ -z "$d" ]] && continue
        problems+=("duplicate item id: $d")
      done <<< "$dup_ids"
    fi

    # ITEM-NNN is convention, not a hard rule -- warn only.
    bad_ids="$(jq -r '[.items[].id | select(type == "string") | select(test("^ITEM-[0-9]+$") | not)] | .[]' "$file" 2>/dev/null || true)"
    if [[ -z "$bad_ids" ]]; then
      emit_check ok "item ids follow ITEM-NNN convention"
    else
      emit_check ok "item ids present (some off-convention, see warnings)"
      while IFS= read -r b; do
        [[ -z "$b" ]] && continue
        warnings+=("id \"$b\" does not match the ITEM-NNN convention")
      done <<< "$bad_ids"
    fi

    # Step participant references resolve against teams.json -- warn only.
    # No teams.json, or steps with no participant, is fine. An unparseable
    # teams.json is not fine -- without this check, teams_get_participant's
    # jq call fails silently and every reference looks "resolved" by accident.
    teams_file="$(teams_path_for "$file")"
    if [[ -f "$teams_file" ]] && ! jq empty "$teams_file" >/dev/null 2>&1; then
      emit_check fail "teams.json is valid JSON"
      problems+=("teams.json exists but is not valid JSON: $teams_file")
    elif [[ -f "$teams_file" ]]; then
      unresolved=0
      while IFS=$'\t' read -r iid sid pid; do
        [[ -z "$pid" ]] && continue
        if [[ "$(teams_get_participant "$teams_file" "$pid")" == "null" ]]; then
          warnings+=("step ${iid}/${sid} references participant \"$pid\" not found in teams.json")
          unresolved=$((unresolved + 1))
        fi
      done < <(jq -r '.items[] | .id as $iid | (.steps // [])[] | select((.participant // "") != "") | [$iid, .id, .participant] | @tsv' "$file" 2>/dev/null)
      if [[ "$unresolved" -eq 0 ]]; then
        emit_check ok "step participants resolve against teams.json"
      else
        emit_check ok "step participants present ($unresolved unresolved, see warnings)"
      fi
    fi
  fi
fi

# --- Report --------------------------------------------------------------
echo
if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "Warnings (${#warnings[@]}):"
  for w in "${warnings[@]}"; do
    printf '  - %s\n' "$w"
  done
  echo
fi

if [[ ${#problems[@]} -eq 0 ]]; then
  echo "OK: backlog is valid."
  exit 0
fi

echo "FAIL: ${#problems[@]} problem(s) found:"
for p in "${problems[@]}"; do
  printf '  - %s\n' "$p"
done
exit 1

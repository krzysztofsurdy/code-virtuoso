#!/bin/bash
# Validate a backlog before a run. Collects every problem, prints a ✓/✗
# checklist, exits 1 on any failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/pipelines.sh
source "${SCRIPT_DIR}/lib/pipelines.sh"

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

# --- config layers -------------------------------------------------------
# A key may come from the backlog's own config or from the "loop" namespace of
# the shared config (user, project shared, project local). A layer that does
# not parse is a hard error: it would otherwise be skipped without a word.
root="$(cv_root_for "$file")"
layers_ok=1
layer_files=()
while IFS= read -r layer; do
  [[ -n "$layer" ]] && layer_files+=("$layer")
done < <(cv_config_files "$root")
layer_files+=("$(pipelines_path_for "$file")" "$(pipelines_user_path)")
for layer in "${layer_files[@]}"; do
  if [[ -f "$layer" ]] && ! jq empty "$layer" >/dev/null 2>&1; then
    emit_check fail "$layer is valid JSON"
    problems+=("not valid JSON: $layer")
    layers_ok=0
  fi
done
[[ "$layers_ok" -eq 1 ]] && emit_check ok "config and pipelines files parse"

# --- config keys ---------------------------------------------------------
loop_cfg="$(cv_merged_config "$root" | jq -c '.loop // {}')"
for key in maxIterations maxAttemptsPerItem maxStallIterations maxViolations permissionMode; do
  if [[ "$(jq ".config | has(\"$key\")" "$file" 2>/dev/null)" == "true" ]] \
     || [[ "$(echo "$loop_cfg" | jq "has(\"$key\")")" == "true" ]]; then
    emit_check ok "config.$key present"
  else
    emit_check fail "config.$key present"
    problems+=("missing config key: $key (set it in the backlog config or the loop namespace of .code-virtuoso/config.json)")
  fi
done

# protectedPaths: the backlog's list plus the loop namespace's, together non-empty
case "$(jq -r --argjson loop "$loop_cfg" '
  (.config.protectedPaths // []) as $own | ($loop.protectedPaths // []) as $shared |
  if ($own | type) != "array" or ($shared | type) != "array" then "notarray"
  elif (($own + $shared) | length) > 0 then "ok" else "empty" end' "$file" 2>/dev/null)" in
  ok)       emit_check ok "config.protectedPaths is a non-empty array" ;;
  empty)    emit_check fail "config.protectedPaths is a non-empty array"; problems+=("config.protectedPaths is empty") ;;
  *)        emit_check fail "config.protectedPaths is a non-empty array"; problems+=("config.protectedPaths is missing or not an array") ;;
esac

# allowedTools: array
case "$(jq -r --argjson loop "$loop_cfg" '(.config.allowedTools // $loop.allowedTools) | if type == "array" then "ok" else "notarray" end' "$file" 2>/dev/null)" in
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
                (if ($st.verifyCommand|type) == "string" and ($st.verifyCommand|length) > 0 then empty else $sref + ": verifyCommand missing or empty" end)
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

    # Run state belongs in loop/state/state.json, not in the plan.
    stateful_steps="$(jq '[.items[].steps[]? | select(has("status") or has("attempts") or has("notes"))] | length' "$file" 2>/dev/null || echo 0)"
    if [[ "$stateful_steps" -gt 0 ]]; then
      warnings+=("$stateful_steps step(s) carry status, attempts or notes in the plan; they are ignored. Run state lives in state/state.json next to the backlog.")
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

    # ITEM-NNN is convention, not a hard rule - warn only.
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

    # Step participant references resolve against pipelines.json - project
    # layer first, then the user layer (pipelines_get_participant checks both).
    # No pipelines file at either layer, or steps with no participant, is fine.
    # An unparseable file was already reported above; skip the lookups then,
    # because pipelines_get_participant's jq call would fail silently and make
    # every reference at that layer look "resolved" by accident.
    pipelines_file="$(pipelines_path_for "$file")"
    user_pipelines_file="$(pipelines_user_path)"

    if [[ "$layers_ok" -eq 1 ]] && { [[ -f "$pipelines_file" ]] || [[ -f "$user_pipelines_file" ]]; }; then
      unresolved=0
      referenced_participants=()
      while IFS=$'\t' read -r iid sid pid; do
        [[ -z "$pid" ]] && continue
        referenced_participants+=("$pid")
        if [[ "$(pipelines_get_participant "$file" "$pid")" == "null" ]]; then
          warnings+=("step ${iid}/${sid} references participant \"$pid\" not found in the project or user pipelines.json")
          unresolved=$((unresolved + 1))
        fi
      done < <(jq -r '.items[] | .id as $iid | (.steps // [])[] | select((.participant // "") != "") | [$iid, .id, .participant] | @tsv' "$file" 2>/dev/null)
      if [[ "$unresolved" -eq 0 ]]; then
        emit_check ok "step participants resolve against pipelines.json (project or user)"
      else
        emit_check ok "step participants present ($unresolved unresolved, see warnings)"
      fi

      # A malformed participant definition doesn't fail until runtime --
      # kind other than agent/persona, an agent with no .agent, or a persona
      # with no .systemPrompt each produce a broken CLI invocation
      # (`--agent null`, `--append-system-prompt null`) that's easy to miss
      # by eye. Hard errors, not warnings: these are never valid.
      #
      # Only participants this backlog's steps actually reference are
      # checked, resolved through the same project-then-global lookup the
      # engine uses at run time - not "every participant in whichever file
      # happens to exist", which would mean every project's validate run
      # re-checking the whole user library on every invocation.
      #
      # The check itself lives entirely in jq, one complete message per
      # output line - an earlier version split a jq @tsv row in the shell
      # via `IFS=$'\t' read`, which silently collapsed a persona's always-
      # empty "agent" field (tab is IFS *whitespace*, so bash treats
      # consecutive tabs as one delimiter, not an empty field between two),
      # shifting every later field left and flagging every valid persona as
      # broken. jq has no such footgun: each line below is already the full,
      # correctly-attributed message, nothing left to mis-split.
      bad_participants=0
      for pid in "${referenced_participants[@]+"${referenced_participants[@]}"}"; do
        participant_json="$(pipelines_get_participant "$file" "$pid")"
        [[ "$participant_json" == "null" ]] && continue
        while IFS= read -r problem_line; do
          [[ -z "$problem_line" ]] && continue
          problems+=("$problem_line")
          bad_participants=$((bad_participants + 1))
        done < <(echo "$participant_json" | jq -r --arg pid "$pid" '
          . as $p | ($p.kind // "") as $kind |
          if $kind == "agent" then
            (if (($p.agent // "") | length) > 0 then empty
             else "participant \"" + $pid + "\" is kind=agent but has no non-empty \"agent\" field" end)
          elif $kind == "persona" then
            (if (($p.systemPrompt // "") | length) > 0 then empty
             else "participant \"" + $pid + "\" is kind=persona but has no non-empty \"systemPrompt\" field" end)
          else
            "participant \"" + $pid + "\" has kind \"" + $kind + "\", must be \"agent\" or \"persona\""
          end
        ')
      done
      if [[ "$bad_participants" -eq 0 ]]; then
        emit_check ok "referenced participants are well-formed"
      else
        emit_check fail "referenced participants are well-formed ($bad_participants problem(s))"
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

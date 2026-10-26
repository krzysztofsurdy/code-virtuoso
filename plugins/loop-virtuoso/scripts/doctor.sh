#!/bin/bash
# Read-only audit of the user's Claude Code setup. Never writes any file.
#
#   doctor.sh [--json | --verbose]
#
# Reads ${CLAUDE_CONFIG_DIR:-$HOME/.claude} (skills, agents, CLAUDE.md,
# settings.json, settings.local.json, plugins) and $HOME/.claude.json; inside a
# git repo also <root>/.claude/settings*.json and the project code-virtuoso
# config. Each finding has a check id, a severity (high, medium, low), what,
# where and fix. The human report groups findings of one check; --verbose
# prints each one in full. Exits 0 whether or not there are findings; 2 on bad
# usage or an internal error.
set -Eeuo pipefail
trap 'echo "doctor: internal error at line $LINENO" >&2; exit 2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

json=false
verbose=false
for arg in "$@"; do
  case "$arg" in
    --json) json=true ;;
    --verbose) verbose=true ;;
    *) echo "usage: doctor.sh [--json | --verbose]" >&2; exit 2 ;;
  esac
done
command -v jq >/dev/null 2>&1 || { echo "doctor: jq is required" >&2; exit 2; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CFG="${CFG%/}"
# The listing budget is 1% of the context window. Assumes a 200k-token window
# and about 4 characters per token: 2,000 tokens, about 8,000 characters.
LISTING_BUDGET=8000
DESCRIPTION_CAP=1536
CLAUDE_MD_MAX_LINES=200
HARDEN="Run /loop-virtuoso:harden to review and apply the missing settings."

FINDINGS=""
SKILLS=""
AGENTS=""
COMMANDS=""

# finding <check> <severity> <what> <where> <fix> [<group> <item>]
# group and item feed the grouped human report and never reach --json.
finding() {
  FINDINGS+="$(jq -nc --arg c "$1" --arg s "$2" --arg w "$3" --arg p "$4" --arg f "$5" --arg g "${6:-}" --arg i "${7:-}" \
    '{check: $c, severity: $s, what: $w, where: $p, fix: $f} + (if $g == "" then {} else {group: $g, item: $i} end)')"$'\n'
}

# read_json <file>: the file's JSON, {} when missing or invalid.
read_json() {
  if [[ -f "$1" ]] && jq empty "$1" >/dev/null 2>&1; then cat "$1"; else echo '{}'; fi
}

# check_json <file>...: a finding for each existing file that is not valid JSON.
check_json() {
  local file
  for file in "$@"; do
    if [[ -f "$file" ]] && ! jq empty "$file" >/dev/null 2>&1; then
      finding invalid-json medium "Not valid JSON, so it was skipped" "$file" "Fix the JSON syntax." \
        "files that are not valid JSON, so they were skipped" "$file"
    fi
  done
}

# frontmatter <file>: "name<TAB>description+when_to_use length<TAB>disable-model-invocation".
frontmatter() {
  awk '
    NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; next }
    /^---[[:space:]]*$/ { exit }
    /^[A-Za-z0-9_-]+:/ {
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:[[:space:]]*/, "", val)
      if (val ~ /^[>|][-+0-9]*[[:space:]]*$/) val = ""
      gsub(/^["\047]|["\047][[:space:]]*$/, "", val)
      f[key] = val; cur = key; next
    }
    /^[[:space:]]/ && cur != "" {
      line = $0; sub(/^[[:space:]]+/, "", line)
      f[cur] = (f[cur] == "" ? line : f[cur] " " line); next
    }
    END { printf "%s\t%d\t%s\n", f["name"], length(f["description"]) + length(f["when_to_use"]), f["disable-model-invocation"] }
  ' "$1"
}

# add_skill <origin> <SKILL.md>
add_skill() {
  local name len dmi
  IFS=$'\t' read -r name len dmi < <(frontmatter "$2") || true
  [[ -n "$name" ]] || name="$(basename "$(dirname "$2")")"
  SKILLS+="$1"$'\t'"$2"$'\t'"$name"$'\t'"${len:-0}"$'\t'"${dmi:-false}"$'\n'
}

# add_agent <origin> <agent.md>
add_agent() {
  local name
  IFS=$'\t' read -r name _ < <(frontmatter "$2") || true
  [[ -n "$name" ]] || name="$(basename "$2" .md)"
  AGENTS+="$1"$'\t'"$2"$'\t'"$name"$'\n'
}

# skill_files <base> <relative path>: SKILL.md of a skill dir, or of each skill dir inside it.
skill_files() {
  local dir="$1/${2#./}" f
  dir="${dir%/}"
  if [[ -f "$dir/SKILL.md" ]]; then
    echo "$dir/SKILL.md"
  else
    for f in "$dir"/*/SKILL.md; do
      if [[ -f "$f" ]]; then echo "$f"; fi
    done
  fi
}

# agent_files <base> <relative path>: an agent file, or the *.md files of a directory.
agent_files() {
  local path="$1/${2#./}" f
  path="${path%/}"
  if [[ -f "$path" ]]; then
    echo "$path"
  else
    for f in "$path"/*.md; do
      if [[ -f "$f" ]]; then echo "$f"; fi
    done
  fi
}

# plugin_files <install path> <manifest> <marketplace entry> <field> <lister>
# Files from the default <field>/ directory plus the paths plugin.json and the
# marketplace entry declare for <field> (a string or an array).
plugin_files() {
  local path="$1" field="$4" lister="$5" rel
  "$lister" "$path" "$field"
  printf '%s\n%s\n' "$2" "$3" |
    jq -r --arg k "$field" '.[$k] // empty | if type == "array" then .[] else . end | select(type == "string")' |
    while IFS= read -r rel; do "$lister" "$path" "$rel"; done
}

# add_findings: append the compact finding objects read from stdin.
add_findings() {
  local line
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then FINDINGS+="$line"$'\n'; fi
  done
}

# marketplace_entry <marketplace> <plugin>: the plugin's marketplace.json entry, {} if none.
marketplace_entry() {
  local location file
  location="$(echo "$KNOWN_MARKETPLACES" | jq -r --arg m "$1" '.[$m].installLocation // empty')"
  [[ -n "$location" ]] || location="$CFG/plugins/marketplaces/$1"
  file="$location/.claude-plugin/marketplace.json"
  if [[ -f "$file" ]] && jq empty "$file" >/dev/null 2>&1; then
    jq -c --arg p "$2" '[.plugins[]? | select(.name == $p)] | first // {}' "$file"
  else
    echo '{}'
  fi
}

# physical_dir <dir>: the dir with symlinks resolved, empty when it does not exist.
physical_dir() { (cd "$1" 2>/dev/null && pwd -P) || true; }

# --- Collect skills, agents and commands ---------------------------------
CV_USER_CONFIG="$(cv_config_home)/config.json"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
SETTINGS_FILES=("$CFG/settings.json" "$CFG/settings.local.json")
if [[ -n "$ROOT" && "$(physical_dir "$ROOT/.claude")" != "$(physical_dir "$CFG")" ]]; then
  SETTINGS_FILES+=("$ROOT/.claude/settings.json" "$ROOT/.claude/settings.local.json")
fi
check_json "${SETTINGS_FILES[@]}" "$CFG/plugins/installed_plugins.json" "$CFG/plugins/known_marketplaces.json" \
  "$HOME/.claude.json" "$CV_USER_CONFIG"
if [[ -n "$ROOT" ]]; then check_json "$ROOT/$CV_DIR_NAME/config.json" "$ROOT/$CV_DIR_NAME/config.local.json"; fi
if [[ "$CFG" != "$HOME" ]]; then check_json "$CFG/.claude.json"; fi
SETTINGS="$(read_json "$CFG/settings.json")"
INSTALLED="$(read_json "$CFG/plugins/installed_plugins.json")"
KNOWN_MARKETPLACES="$(read_json "$CFG/plugins/known_marketplaces.json")"

for f in "$CFG"/skills/*/SKILL.md; do
  if [[ -f "$f" ]]; then add_skill user "$f"; fi
done
for f in "$CFG"/skills/synced/*/SKILL.md "$CFG"/skills/synced/*/*/SKILL.md; do
  if [[ -f "$f" ]]; then add_skill synced "$f"; fi
done
for f in "$CFG"/agents/*.md; do
  if [[ -f "$f" ]]; then add_agent user "$f"; fi
done
for f in "$CFG"/commands/*.md; do
  if [[ -f "$f" ]]; then COMMANDS+="user"$'\t'"$(basename "$f" .md)"$'\n'; fi
done

while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  path="$(echo "$INSTALLED" | jq -r --arg k "$key" '
    .plugins[$k] // empty | if type == "array" then . else [.] end
    | (map(select(.scope == "user")) + .) | first | .installPath // empty')"
  [[ -n "$path" && -d "$path" ]] || continue
  path="${path%/}"
  manifest='{}'
  if [[ -f "$path/.claude-plugin/plugin.json" ]] && jq empty "$path/.claude-plugin/plugin.json" >/dev/null 2>&1; then
    manifest="$(cat "$path/.claude-plugin/plugin.json")"
  fi
  entry="$(marketplace_entry "${key##*@}" "${key%@*}")"
  while IFS= read -r f; do
    if [[ -n "$f" ]]; then add_skill "$key" "$f"; fi
  done < <(plugin_files "$path" "$manifest" "$entry" skills skill_files)
  while IFS= read -r f; do
    if [[ -n "$f" ]]; then add_agent "$key" "$f"; fi
  done < <(plugin_files "$path" "$manifest" "$entry" agents agent_files)
  for f in "$path"/commands/*.md; do
    if [[ -f "$f" ]]; then COMMANDS+="$key"$'\t'"$(basename "$f" .md)"$'\n'; fi
  done
done < <(echo "$SETTINGS" | jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key')

tsv_to_json() {
  printf '%s' "$1" | jq -R -s --argjson cols "$2" \
    'split("\n") | map(select(length > 0) | split("\t") as $v | [$cols, $v] | transpose | map({(.[0]): .[1]}) | add)'
}
SKILLS_JSON="$(tsv_to_json "$SKILLS" '["origin","path","name","len","dmi"]' |
  jq -c --argjson cap "$DESCRIPTION_CAP" 'unique_by(.origin + .path) |
    map(.dmi = (.dmi == "true") | .chars = ((.name | length) + ([(.len | tonumber), $cap] | min)) | del(.len))')"
AGENTS_JSON="$(tsv_to_json "$AGENTS" '["origin","path","name"]' | jq -c 'unique_by(.origin + .path)')"
COMMANDS_JSON="$(tsv_to_json "$COMMANDS" '["origin","name"]')"

# --- 1. Duplicate skill and agent names ----------------------------------
add_findings < <(jq -nc --argjson skills "$SKILLS_JSON" --argjson agents "$AGENTS_JSON" '
  def dups($items; $check; $kind; $fix):
    $items | group_by(.name)[] | select(length > 1)
    | (map(.origin) | join(", ")) as $origins
    | {check: $check, severity: "medium",
       what: ("\($kind) \"\(.[0].name)\" is defined \(length) times: " + $origins),
       where: (map(.path) | join(", ")), fix: $fix,
       group: "\($kind | ascii_downcase) names defined more than once (name: sources)", item: "\(.[0].name): \($origins)"};
  dups($skills; "duplicate-skill"; "Skill";
    "Keep one copy: delete the extra standalone or synced copies, or disable the plugin that ships one (/plugin)."),
  dups($agents; "duplicate-agent"; "Agent";
    "Keep one copy: delete the extra agent files, or disable the plugin that ships one (/plugin).")')

# --- 2. Skill listing budget ---------------------------------------------
LISTING="$(echo "$SKILLS_JSON" | jq -c --argjson budget "$LISTING_BUDGET" '
  map(select(.dmi | not)) | {skills: length, chars: (map(.chars) | add // 0), budget: $budget,
    top: (sort_by(-.chars) | .[0:5] | map("\(.name) (\(.chars))") | join(", "))}')"
listing_chars="$(echo "$LISTING" | jq -r .chars)"
listing_what="$(echo "$LISTING" | jq -r '"Skill listing is about \(.chars) characters for \(.skills) model-invocable skills; budget about \(.budget) (1% of a 200k-token context at about 4 characters per token). Largest: \(.top)"')"
listing_fix="Disable unused plugins (/plugin), mark run-by-name skills disable-model-invocation: true, set skillOverrides to name-only or off, or trim descriptions. Check the real figure with /context."
if (( listing_chars > LISTING_BUDGET )); then
  finding skill-listing medium "$listing_what" "$CFG/skills" "$listing_fix"
elif (( listing_chars * 10 > LISTING_BUDGET * 8 )); then
  finding skill-listing low "$listing_what" "$CFG/skills" "$listing_fix"
fi

# --- 3. Global CLAUDE.md -------------------------------------------------
claude_md="$CFG/CLAUDE.md"
if [[ -f "$claude_md" ]]; then
  lines="$(wc -l < "$claude_md" | tr -d ' ')"
  if (( lines > CLAUDE_MD_MAX_LINES )); then
    finding claude-md-size medium "Global CLAUDE.md has $lines lines (target under $CLAUDE_MD_MAX_LINES); it loads into every session" \
      "$claude_md" "Delete generic advice and skill tables; move scoped rules to ~/.claude/rules/*.md with paths."
  fi
  name_re='/[A-Za-z0-9][A-Za-z0-9_.:-]*'
  refs="$( { grep -noE "(->|→)[[:space:]]*use[[:space:]]+${name_re}([[:space:]]*,[[:space:]]*${name_re})*" "$claude_md" || true
             grep -noE "\`${name_re}\`" "$claude_md" || true; } |
    while IFS= read -r match; do
      echo "${match#*:}" | grep -oE "$name_re" | sed -e 's/[.:]*$//' -e "s/^/${match%%:*}"$'\t'"/" || true
    done)"
  add_findings < <(tsv_to_json "$refs" '["line","ref"]' | jq -c --argjson skills "$SKILLS_JSON" \
    --argjson commands "$COMMANDS_JSON" --arg file "$claude_md" '
    def plugin: split("@")[0];
    def builtin: ["add-dir","agents","bug","clear","compact","config","context","cost","doctor","effort",
      "exit","export","fast","help","hooks","ide","init","login","logout","mcp","memory","model",
      "output-style","permissions","plan","plugin","pr-comments","release-notes","resume","review",
      "rewind","security-review","skill-doctor","skills","status","statusline","terminal-setup",
      "todos","usage","vim"];
    def names($i): [$i.name] + (if $i.origin == "user" or $i.origin == "synced" then [] else ["\($i.origin | plugin):\($i.name)"] end);
    (reduce $commands[] as $c ({}; reduce names($c)[] as $n (.; .[$n] = "command"))) as $cmd
    | (reduce $skills[] as $s ({}; reduce names($s)[] as $n (.; .[$n] = ((.[$n] // false) or ($s.dmi | not))))) as $skill
    | unique_by(.ref)[] | (.ref | ltrimstr("/")) as $n
    | select((builtin | index($n) | not) and ($cmd[$n] | not) and ($skill[$n] != true))
    | if $skill[$n] == false then
        {check: "claude-md-ref", severity: "medium",
         what: "\(.ref) points to a skill with disable-model-invocation: true, so the model cannot invoke it",
         where: "\($file):\(.line)", fix: "Drop the routing line, or remove disable-model-invocation from the skill.",
         group: "references in \($file) to skills with disable-model-invocation: true, which the model cannot invoke",
         item: "\(.ref) (line \(.line))"}
      else
        {check: "claude-md-ref", severity: "medium", what: "\(.ref) resolves to no installed skill or command",
         where: "\($file):\(.line)", fix: "Delete the reference or install the skill it names.",
         group: "references in \($file) that resolve to no installed skill or command", item: "\(.ref) (line \(.line))"}
      end')
fi

# --- 4. Plaintext secrets in MCP server config ---------------------------
for claude_json in "$HOME/.claude.json" "$CFG/.claude.json"; do
  [[ -f "$claude_json" ]] || continue
  if [[ "$claude_json" == "$CFG/.claude.json" && "$CFG" == "$HOME" ]]; then continue; fi
  add_findings < <(read_json "$claude_json" | jq -c --arg file "$claude_json" '
    def secretish: test("key|token|secret|passw|auth|credential"; "i");
    def literal: type == "string" and length > 0 and (contains("${") | not);
    def pairs($o): $o // {} | if type == "object" then to_entries[] else empty end;
    ( (pairs(.mcpServers) | {at: "mcpServers.\(.key)", server: .key, cfg: .value}),
      (pairs(.projects) | .key as $p | pairs(.value.mcpServers)
        | {at: "projects[\($p | tojson)].mcpServers.\(.key)", server: .key, cfg: .value}) )
    | . as $s
    | ( (pairs($s.cfg.env) | {kind: "env", key, value}), (pairs($s.cfg.headers) | {kind: "headers", key, value}) )
    | select((.key | secretish) and (.value | literal))
    | {check: "mcp-secret", severity: "high",
       what: "MCP server \"\($s.server)\" has a plaintext \(.kind) value for \(.key)",
       where: "\($file) (\($s.at).\(.kind).\(.key))",
       fix: "Move the value to an environment variable, reference it as ${VAR}, and rotate the key.",
       group: "plaintext secret values in MCP server config (names only, values are never printed)",
       item: "\($s.server): \(.kind).\(.key) (\($file), \($s.at))"}')
done

# --- 5. Settings gaps ----------------------------------------------------
# A setting in any layer satisfies its check; deny and ask rules combine across
# layers. Telemetry env counts only from the user settings.json.
# layers_json <file>...: [{file, config}] for each file, {} when missing or invalid.
layers_json() {
  local f
  for f in "$@"; do read_json "$f" | jq -c --arg f "$f" '{file: $f, config: .}'; done | jq -s -c .
}
if [[ -n "$ROOT" ]]; then
  GUARD_CONFIG="$(cv_merged_config "$ROOT")"
  GUARD_FILES=()
  while IFS= read -r f; do
    if [[ -n "$f" ]]; then GUARD_FILES+=("$f"); fi
  done < <(cv_config_files "$ROOT")
else
  GUARD_CONFIG="$(read_json "$CV_USER_CONFIG")"
  GUARD_FILES=("$CV_USER_CONFIG")
fi
SATISFIED="$(jq -nc --argjson settings "$(layers_json "${SETTINGS_FILES[@]}")" \
  --argjson guard "$(layers_json ${GUARD_FILES[@]+"${GUARD_FILES[@]}"})" --argjson merged "$GUARD_CONFIG" '
  def obj: if type == "object" then . else {} end;
  def rules($kind): .permissions?[$kind]? // [] | type == "array" and length > 0;
  def guarded: (.loop?.guard? // {}) | obj | [.blockSecrets, .protectTests, .stopGate] | any(. != null and . != false);
  def by($layers; f): [$layers[] | select(.config | obj | f) | .file];
  {"settings-attribution": by($settings; has("attribution")),
   "settings-deny": by($settings; rules("deny")),
   "settings-ask": by($settings; rules("ask")),
   "settings-statusline": by($settings; has("statusLine")),
   "settings-telemetry": by($settings[0:1]; .env?.CLAUDE_CODE_ENABLE_TELEMETRY? // "" | tostring | IN("1", "true")),
   "loop-guard": (if $merged | obj | guarded then by($guard; guarded) else [] end)}')"
# gap <check>: true when no layer satisfies the check.
gap() { [[ "$(echo "$SATISFIED" | jq --arg c "$1" '.[$c] | length')" == "0" ]]; }

settings_file="$CFG/settings.json"
if gap settings-attribution; then
  finding settings-attribution medium "No attribution setting; commits and PRs get the default AI attribution" "$settings_file" \
    "Set \"attribution\": {\"commit\": \"\", \"pr\": \"\"} (or your own lines). $HARDEN"
fi
if gap settings-deny; then
  finding settings-deny medium "No permissions.deny rules; secrets such as .env and ~/.ssh are readable" "$settings_file" "$HARDEN"
fi
if gap settings-ask; then
  finding settings-ask low "No permissions.ask rules; force pushes and hard resets run without a prompt" "$settings_file" "$HARDEN"
fi
if gap settings-statusline; then
  finding settings-statusline low "No statusLine; cost, context use and loop progress are not visible" "$settings_file" \
    "Run /loop-virtuoso:harden --with statusline."
fi
if gap settings-telemetry; then
  finding settings-telemetry low "Telemetry is off (env.CLAUDE_CODE_ENABLE_TELEMETRY)" "$settings_file" \
    "Run /loop-virtuoso:harden --with telemetry once you have an OpenTelemetry backend. Only the user settings.json is read for telemetry; project settings do not turn it on."
fi
if gap loop-guard; then
  finding loop-guard low "No loop.guard hook is enabled (blockSecrets, protectTests, stopGate)" "$CV_USER_CONFIG" "$HARDEN"
fi

# --- 6. Orphan plugin caches ---------------------------------------------
installed_paths="$(echo "$INSTALLED" | jq -r '.plugins // {} | .[] | if type == "array" then .[] else . end | .installPath // empty' |
  while IFS= read -r p; do
    if [[ -d "$p" ]]; then (cd "$p" && pwd -P); fi
  done)"
for dir in "$CFG"/plugins/cache/*/*/*/; do
  [[ -d "$dir" ]] || continue
  dir="${dir%/}"
  if ! printf '%s\n' "$installed_paths" | grep -qxF -- "$(cd "$dir" && pwd -P)"; then
    finding orphan-cache low "Plugin cache directory is not referenced by installed_plugins.json" "$dir" \
      "Delete the directory after checking no session uses it." \
      "plugin cache directories under $CFG/plugins/cache not referenced by installed_plugins.json" \
      "${dir#"$CFG/plugins/cache/"}"
  fi
done

# --- Report ---------------------------------------------------------------
REPORT="$(printf '%s' "$FINDINGS" | jq -s -c --arg cfg "$CFG" --argjson listing "$LISTING" --argjson satisfied "$SATISFIED" '
  def rank: {high: 0, medium: 1, low: 2}[.severity];
  {configDir: $cfg, listing: ($listing | del(.top)), findings: sort_by(rank),
   summary: {high: map(select(.severity == "high")) | length,
             medium: map(select(.severity == "medium")) | length,
             low: map(select(.severity == "low")) | length},
   satisfiedBy: ($satisfied | with_entries(select(.value | length > 0)))}')"

if [[ "$json" == "true" ]]; then
  echo "$REPORT" | jq -c '.findings |= map(del(.group, .item))'
  exit 0
fi

echo "================================================================"
echo "  Claude Code Setup Doctor"
echo "================================================================"
echo "  Config dir:    $CFG"
echo "$REPORT" | jq -r '"  Skill listing: \(.listing.skills) model-invocable skill(s), about \(.listing.chars) of \(.listing.budget) characters"'
echo
if [[ "$(echo "$REPORT" | jq '.findings | length')" == "0" ]]; then
  echo "  No findings."
else
  echo "$REPORT" | jq -r --argjson verbose "$verbose" '
    def full: "  [\(.severity)] \(.check): \(.what)\n      where: \(.where)\n      fix:   \(.fix)\n";
    .findings | to_entries | group_by([.value.severity, .value.check, .value.group // ""]) | sort_by(.[0].key)
    | map(map(.value))[]
    | if length == 1 or $verbose or (.[0].group == null) then .[] | full
      else "  [\(.[0].severity)] \(.[0].check): \(length) findings - \(.[0].group)\n"
        + (map("      - \(.item)\n") | join(""))
        + "      fix:   \(map(.fix) | unique | join(" "))\n"
      end'
  echo "$REPORT" | jq -r '"  Findings: \(.summary.high) high | \(.summary.medium) medium | \(.summary.low) low"'
fi
echo "================================================================"

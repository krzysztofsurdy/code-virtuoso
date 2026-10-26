#!/bin/bash
# /loop-virtuoso:harden: merges a guardrail baseline into Claude Code's
# settings.json and the loop.guard defaults into the matching code-virtuoso
# config layer.
#   ./scripts/harden.sh [--scope user|project] [--apply] [--with statusline,telemetry,sandbox]
#
# Without --apply it prints a unified diff per file and writes nothing.
#
# Merge rules: nothing the user set is removed or replaced. Objects merge key
# by key, an array gains the baseline entries it lacks (existing entries keep
# their order, new ones follow), and a value the user already set stays as is,
# with a note when it differs from the baseline. A file is compared and written
# the way `jq .` prints it (2-space indent, key order kept, new keys last), so
# the diff shows content changes only. --apply copies a changed file to
# <file>.bak.<timestamp> first, then writes a temp file and renames it over the
# file (or its symlink target); an unchanged file is not touched, so a second
# apply writes nothing.
#
# The deny and ask rules come from skills/playbooks/hooks-and-guardrails/
# references/claude-code-settings.md, except that only force pushes ask: the
# three git push rules catch --force, --force-with-lease and -f in any argument
# position, per the wildcard rules in https://code.claude.com/docs/en/permissions. The telemetry variables follow
# https://code.claude.com/docs/en/monitoring-usage; Claude Code ignores them in
# project settings, so telemetry (and the statusline, whose path is per user)
# is --scope user only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/preflight.sh
source "$SCRIPT_DIR/lib/preflight.sh"

usage() {
  echo "usage: harden.sh [--scope user|project] [--apply] [--with statusline,telemetry,sandbox]" >&2
  exit 1
}

BASE_SETTINGS='{
  "attribution": {"commit": "", "pr": ""},
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(!.env.example)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Edit(./.env)",
      "Edit(./.env.*)"
    ],
    "ask": [
      "Bash(git push *--force*)",
      "Bash(git push -f*)",
      "Bash(git push * -f*)",
      "Bash(git branch -D *)",
      "Bash(git reset --hard *)",
      "Bash(composer require *)",
      "Bash(composer remove *)",
      "Bash(composer update *)"
    ]
  }
}'

SANDBOX_SETTINGS='{
  "sandbox": {
    "enabled": true,
    "allowUnsandboxedCommands": false,
    "filesystem": {"denyRead": ["~/.ssh", "~/.aws"]},
    "network": {"allowedDomains": ["github.com"]}
  }
}'

# The console exporter needs no collector; point OTEL_* at one to ship data.
TELEMETRY_SETTINGS='{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "console",
    "OTEL_LOGS_EXPORTER": "console"
  }
}'

GUARD_CONFIG='{"loop": {"guard": {"blockSecrets": true, "protectTests": "ask"}}}'

# harden_merge($have; $want): $have plus whatever of $want it lacks.
# harden_kept($have; $want; $path): one note per user value that differs from the baseline.
HARDEN_JQ='
def harden_merge($have; $want):
  if $have == null then $want
  elif ($have | type) == "object" and ($want | type) == "object" then
    reduce ($want | keys_unsorted[]) as $k ($have; .[$k] = harden_merge($have[$k]; $want[$k]))
  elif ($have | type) == "array" and ($want | type) == "array" then
    $have + [$want[] | select(. as $x | $have | any(.[]; . == $x) | not)]
  else $have end;
def harden_kept($have; $want; $path):
  if $have == null then empty
  elif ($have | type) == "object" and ($want | type) == "object" then
    $want | keys_unsorted[] as $k | harden_kept($have[$k]; $want[$k]; $path + [$k])
  elif ($have | type) == "array" and ($want | type) == "array" then empty
  elif $have == $want then empty
  else "\($path | join(".")): kept your \($have | tojson) (baseline: \($want | tojson))" end;
'

scope="user"
apply=0
with_list=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) [[ $# -ge 2 ]] || usage; scope="$2"; shift 2 ;;
    --scope=*) scope="${1#*=}"; shift ;;
    --apply) apply=1; shift ;;
    --with) [[ $# -ge 2 ]] || usage; with_list="${with_list},$2"; shift 2 ;;
    --with=*) with_list="${with_list},${1#*=}"; shift ;;
    -h|--help) usage ;;
    *) echo "Error: unknown argument: $1" >&2; usage ;;
  esac
done

case "$scope" in
  user|project) ;;
  *) echo "Error: --scope must be user or project (got: $scope)" >&2; exit 1 ;;
esac

with_statusline=0 with_telemetry=0 with_sandbox=0
IFS=',' read -r -a with_items <<< "$with_list"
for item in ${with_items[@]+"${with_items[@]}"}; do
  case "$item" in
    "") ;;
    statusline) with_statusline=1 ;;
    telemetry) with_telemetry=1 ;;
    sandbox) with_sandbox=1 ;;
    *) echo "Error: unknown --with item: $item (expected statusline, telemetry, sandbox)" >&2; exit 1 ;;
  esac
done

if [[ "$scope" == "project" ]]; then
  if [[ $with_telemetry -eq 1 || $with_statusline -eq 1 ]]; then
    echo "Error: --with telemetry and --with statusline need --scope user: Claude Code ignores telemetry variables in project settings, and the statusline path is per user" >&2
    exit 1
  fi
  root="$(loop_repo_root .)"
  if [[ -z "$root" ]]; then
    echo "Error: --scope project needs a git repository; run it inside the project" >&2
    exit 1
  fi
  settings_file="$root/.claude/settings.json"
  config_file="$root/${CV_DIR_NAME}/config.json"
else
  settings_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
  config_file="$(cv_config_home)/config.json"
fi

statusline_src="$SCRIPT_DIR/statusline.sh"
statusline_dest="$(cv_config_home)/statusline.sh"

# read_object <file>: the file as `jq .` prints it, empty when it does not exist.
# Exits when it is not a JSON object, so a broken file is never overwritten.
read_object() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if ! jq -e 'type == "object"' "$file" >/dev/null 2>&1; then
    echo "Error: $file is not a JSON object; fix it by hand, then run harden again" >&2
    exit 1
  fi
  jq . "$file"
}

current_settings="$(read_object "$settings_file")"
current_config="$(read_object "$config_file")"

want="$BASE_SETTINGS"
[[ $with_sandbox -eq 1 ]] && want="$(jq -n --argjson a "$want" --argjson b "$SANDBOX_SETTINGS" '$a * $b')"
[[ $with_telemetry -eq 1 ]] && want="$(jq -n --argjson a "$want" --argjson b "$TELEMETRY_SETTINGS" '$a * $b')"

install_statusline=0
if [[ $with_statusline -eq 1 ]]; then
  existing_statusline=""
  if [[ -n "$current_settings" ]]; then
    existing_statusline="$(printf '%s' "$current_settings" | jq -r '.statusLine.command // empty')"
  fi
  if [[ -z "$existing_statusline" || "$existing_statusline" == "$statusline_dest" ]]; then
    install_statusline=1
    want="$(jq -n --argjson a "$want" --arg cmd "$statusline_dest" '$a * {statusLine: {type: "command", command: $cmd}}')"
  else
    echo "note: statusLine already runs $existing_statusline; left as is, statusline.sh not installed"
  fi
fi

changed=0

# symlink_target <file>: <file> with every symlink in its last component followed.
symlink_target() {
  local target="$1" link
  while [[ -L "$target" ]]; do
    link="$(readlink "$target")"
    case "$link" in
      /*) target="$link" ;;
      *) target="$(dirname "$target")/$link" ;;
    esac
  done
  echo "$target"
}

# write_json_atomic <file> <json>
# Writes a temp file next to the symlink target, seeded from the target so the
# mode carries over, checks that it parses, then renames it over the target.
# On any failure the target is left as it was.
write_json_atomic() {
  local target tmp
  target="$(symlink_target "$1")"
  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp "$(dirname "$target")/.$(basename "$target").XXXXXX")"
  if [[ -f "$target" ]]; then
    cp -p "$target" "$tmp"
  else
    chmod "$(printf '%o' $(( 0666 & ~$(umask) )))" "$tmp"
  fi
  if printf '%s\n' "$2" > "$tmp" && jq empty "$tmp" >/dev/null 2>&1 && mv -f "$tmp" "$target"; then
    return 0
  fi
  rm -f "$tmp"
  echo "Error: could not write $target; it is unchanged" >&2
  exit 1
}

# harden_file <label> <file> <current> <baseline-json>
harden_file() {
  local label="$1" file="$2" current="$3" want="$4" have proposed backup
  have="$current"
  [[ -n "$have" ]] || have='{}'
  proposed="$(jq -n --argjson have "$have" --argjson want "$want" "$HARDEN_JQ harden_merge(\$have; \$want)")"
  jq -rn --argjson have "$have" --argjson want "$want" "$HARDEN_JQ harden_kept(\$have; \$want; [])" |
    sed "s|^|note: $label |"

  if [[ "$current" == "$proposed" ]]; then
    echo "$label: $file already has the baseline, no change"
    return 0
  fi
  changed=1
  echo "$label: $file"
  diff -u --label "$file (current)" --label "$file (proposed)" \
    <([[ -z "$current" ]] || printf '%s\n' "$current") <(printf '%s\n' "$proposed") || true
  [[ $apply -eq 1 ]] || return 0

  if [[ -f "$file" ]]; then
    backup="${file}.bak.$(date +%Y%m%d-%H%M%S)"
    [[ ! -e "$backup" ]] || backup="${backup}.$$"
    cp -p "$file" "$backup"
    write_json_atomic "$file" "$proposed"
    echo "$label: wrote $file (backup: $backup)"
  else
    write_json_atomic "$file" "$proposed"
    echo "$label: created $file"
  fi
}

harden_file settings "$settings_file" "$current_settings" "$want"
harden_file config "$config_file" "$current_config" "$GUARD_CONFIG"

if [[ $install_statusline -eq 1 ]]; then
  if cmp -s "$statusline_src" "$statusline_dest"; then
    echo "statusline: $statusline_dest is current, no change"
  elif [[ $apply -eq 1 ]]; then
    mkdir -p "$(dirname "$statusline_dest")"
    cp "$statusline_src" "$statusline_dest"
    chmod 755 "$statusline_dest"
    echo "statusline: installed $statusline_dest"
  else
    changed=1
    echo "statusline: would install $statusline_dest (a copy of the plugin's statusline.sh)"
  fi
fi

if [[ $apply -eq 0 && $changed -eq 1 ]]; then
  echo
  echo "Dry run: nothing was written. Re-run with --apply to write these changes."
fi

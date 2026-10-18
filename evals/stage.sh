#!/usr/bin/env bash
# Builds a throwaway Claude Code plugin from .claude-plugin/marketplace.json plus evals/cases,
# because `claude plugin eval` needs a plugin root with a manifest and the marketplace bundles
# (source "./skills" and "./") have none. Usage: evals/stage.sh <empty-destination-dir>
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
dest=${1:?usage: stage.sh <empty-destination-dir>}

mkdir -p "$dest"
if [ -n "$(ls -A "$dest")" ]; then
  echo "stage.sh: $dest is not empty" >&2
  exit 1
fi

mkdir -p "$dest/.claude-plugin" "$dest/skills" "$dest/agents"
jq -n '{name: "code-virtuoso-evals", version: "0.0.0", description: "Staged copy of the Code Virtuoso marketplace plugins, for eval runs only."}' \
  > "$dest/.claude-plugin/plugin.json"

entries=$(jq -r '.plugins[] | select(.source != null) | .source as $s
  | ((.skills // [])[] | "skill\t\($s)/\(.)"), ((.agents // [])[] | "agent\t\($s)/\(.)")' \
  "$repo/.claude-plugin/marketplace.json")

while IFS=$'\t' read -r kind path; do
  [ -n "$kind" ] || continue
  name=$(basename "$path")
  if [ "$kind" = skill ]; then
    [ ! -e "$dest/skills/$name" ] || { echo "stage.sh: duplicate skill $name" >&2; exit 1; }
    cp -R "$repo/$path" "$dest/skills/$name"
  else
    cp "$repo/$path" "$dest/agents/$name"
  fi
done <<< "$entries"

cp -R "$here/cases" "$dest/evals"
echo "$dest"

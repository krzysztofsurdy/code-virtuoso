#!/usr/bin/env bash
# Install the Code Virtuoso agents for Codex.
#
# Copies codex/agents/*.toml to ~/.codex/agents/ (or ./.codex/agents/ with --project),
# and copies roles/ plus the skill reference directories the agents read to
# ${CODE_VIRTUOSO_HOME:-~/.codex/code-virtuoso}.
#
# A file you changed is never overwritten unless you pass --force. Changes are
# detected by comparing against the checksum stored at install time in
# $CODE_VIRTUOSO_HOME/.install-manifest.
#
# Usage: scripts/install-codex-agents.sh [--project] [--force] [--help]

set -euo pipefail

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

PROJECT=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --project) PROJECT=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CV_HOME="${CODE_VIRTUOSO_HOME:-$HOME/.codex/code-virtuoso}"
if [ "$PROJECT" -eq 1 ]; then
  AGENTS_DEST="$PWD/.codex/agents"
else
  AGENTS_DEST="$HOME/.codex/agents"
fi
MANIFEST="$CV_HOME/.install-manifest"

if ! ls "$REPO"/codex/agents/*.toml >/dev/null 2>&1; then
  echo "No generated agents found. Run: python3 scripts/build-codex-agents.py" >&2
  exit 1
fi

sha() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

recorded() {
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' -v p="$1" '$2 == p { print $1 }' "$MANIFEST"
}

record() {
  local tmp="$MANIFEST.tmp"
  mkdir -p "$CV_HOME"
  {
    if [ -f "$MANIFEST" ]; then awk -F'\t' -v p="$1" '$2 != p' "$MANIFEST"; fi
    printf '%s\t%s\n' "$(sha "$1")" "$1"
  } > "$tmp"
  mv "$tmp" "$MANIFEST"
}

install_file() {
  local src="$1" dst="$2" label="$3" action
  mkdir -p "$(dirname "$dst")"
  if [ ! -e "$dst" ]; then
    action="installed"
  elif cmp -s "$src" "$dst"; then
    record "$dst"
    echo "  unchanged   $label"
    return 0
  elif [ "$FORCE" -eq 1 ]; then
    action="overwritten"
  elif [ "$(recorded "$dst")" = "$(sha "$dst")" ]; then
    action="updated"
  else
    echo "  skipped     $label (modified locally, use --force to overwrite)"
    return 0
  fi
  cp "$src" "$dst"
  record "$dst"
  echo "  $action   $label"
}

install_tree() {
  local src_dir="$1" dst_dir="$2" prefix="$3" file rel
  while IFS= read -r file; do
    rel="${file#"$src_dir"/}"
    install_file "$file" "$dst_dir/$rel" "$prefix/$rel"
  done < <(find "$src_dir" -type f ! -name '.*' | sort)
}

echo "Agents -> $AGENTS_DEST"
for toml in "$REPO"/codex/agents/*.toml; do
  install_file "$toml" "$AGENTS_DEST/$(basename "$toml")" "$(basename "$toml")"
done

echo "Library -> $CV_HOME"
install_tree "$REPO/roles" "$CV_HOME/roles" "roles"

while IFS= read -r ref_dir; do
  if [ -d "$REPO/$ref_dir" ]; then
    install_tree "$REPO/$ref_dir" "$CV_HOME/$ref_dir" "$ref_dir"
  fi
done < <(grep -rhoE 'skills/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/references' "$REPO/agents" 2>/dev/null | sort -u)

echo "Done."

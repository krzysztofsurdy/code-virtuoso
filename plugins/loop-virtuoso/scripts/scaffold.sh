#!/bin/bash
# Copy a starter template into the current git repository.
#   scaffold.sh <devcontainer|issue-to-pr|pilot-backlog> [--force]
#
# Files land at the git root, whatever the current subdirectory. An existing
# target is never overwritten unless --force is given; then it is first copied
# to <file>.bak.<timestamp>. Without --force, nothing is written when any
# target exists. The pilot backlog is never replaced while a loop is active.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$(cd "${SCRIPT_DIR}/../templates" && pwd)"

usage() {
  cat >&2 <<'EOF'
usage: scaffold.sh <kind> [--force]

  devcontainer    .devcontainer/ with a non-root user and an egress-allowlist firewall
  issue-to-pr     .github/workflows/claude-issue-to-pr.yml (issue -> draft PR)
  pilot-backlog   .code-virtuoso/loop/backlog.json (a small, low-risk first run)

  --force         replace existing files, keeping a .bak.<timestamp> copy of each
EOF
  exit 1
}

kind=""
force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -*) usage ;;
    *) [[ -z "$kind" ]] || usage; kind="$arg" ;;
  esac
done

# One "<template> <target>" pair per line; target is relative to the git root.
case "$kind" in
  devcontainer)
    files="devcontainer/devcontainer.json .devcontainer/devcontainer.json
devcontainer/Dockerfile .devcontainer/Dockerfile
devcontainer/init-firewall.sh .devcontainer/init-firewall.sh" ;;
  issue-to-pr)
    files="github/claude-issue-to-pr.yml .github/workflows/claude-issue-to-pr.yml" ;;
  pilot-backlog)
    files="backlog/pilot-backlog.json .code-virtuoso/loop/backlog.json" ;;
  *) usage ;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "scaffold: not inside a git repository. Run it from the repository you want to scaffold." >&2
  exit 1
}

if [[ "$kind" == "pilot-backlog" && -f "$root/.code-virtuoso/loop/state/session.local.json" ]]; then
  echo "scaffold: a loop is active in this repository. Run /loop-virtuoso:cancel before replacing its backlog." >&2
  exit 1
fi

existing=()
while read -r _ target; do
  if [[ -e "$root/$target" ]]; then existing+=("$target"); fi
done <<< "$files"

if [[ ${#existing[@]} -gt 0 && "$force" -eq 0 ]]; then
  echo "scaffold: refusing to overwrite existing files:" >&2
  printf '  %s\n' "${existing[@]}" >&2
  echo "Nothing was written. Re-run with --force to replace them (each is backed up first)." >&2
  exit 1
fi

stamp="$(date +%Y%m%d%H%M%S)"
while read -r template target; do
  dest="$root/$target"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    backup="${dest}.bak.${stamp}"
    n=1
    while [[ -e "$backup" ]]; do backup="${dest}.bak.${stamp}.${n}"; n=$((n + 1)); done
    cp -p "$dest" "$backup"
    echo "Backed up ${target} to ${backup#"$root"/}"
  fi
  cp "$TEMPLATES/$template" "$dest"
  if [[ "$dest" == *.sh ]]; then chmod +x "$dest"; fi
  echo "Wrote ${target}"
done <<< "$files"

echo
echo "Next steps:"
case "$kind" in
  devcontainer)
    cat <<'EOF'
  1. Read the header of .devcontainer/Dockerfile and add your language toolchain
     (the PHP block is optional and commented out).
  2. Add any extra hosts your build needs to ALLOWED_DOMAINS in .devcontainer/init-firewall.sh.
  3. Open the folder in a devcontainer ("Dev Containers: Reopen in Container" or
     `devcontainer up --workspace-folder .`) and run `claude` inside it.
EOF
    ;;
  issue-to-pr)
    cat <<'EOF'
  1. Add the ANTHROPIC_API_KEY secret (or CLAUDE_CODE_OAUTH_TOKEN, see the file header)
     and install the Claude GitHub App: https://github.com/apps/claude
  2. Protect the default branch (require pull requests) so no token can push to it.
  3. Create a `claude` label, then label an issue or comment `@claude` on it.
EOF
    ;;
  pilot-backlog)
    cat <<'EOF'
  1. Edit .code-virtuoso/loop/backlog.json: replace `make lint` and `make test` in each
     verifyCommand and allowedTools with your project's commands, and adjust protectedPaths.
  2. Commit your stricter static analysis setting on the pilot branch (see ITEM-001).
  3. Run /loop-virtuoso:start (it validates the backlog before anything runs).
EOF
    ;;
esac

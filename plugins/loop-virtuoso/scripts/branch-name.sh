#!/bin/bash
# Print a branch name that follows the project's convention.
#   branch-name.sh [--ticket <id>] <title>
#
# Uses ticket-delivery.branchPattern from the merged .code-virtuoso config
# ({ticket} and {slug} placeholders), or "feat/{slug}" when none is set. The
# backlog-compiler skill calls it to fill backlog.branch. Exits 1 when the
# pattern needs a ticket id and none was given.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

ticket=""
if [[ "${1:-}" == "--ticket" ]]; then
  ticket="${2:-}"
  shift 2 || true
fi
title="$*"
if [[ -z "$title" ]]; then
  echo "usage: branch-name.sh [--ticket <id>] <title>" >&2
  exit 1
fi

loop_branch_name "$ticket" "$title" "$(cv_root_for .)"

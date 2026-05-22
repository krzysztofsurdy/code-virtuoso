#!/usr/bin/env bash
# Copy a screenshot file from the MCP browser docker container to the host.
#
# Why this exists:
#   Browser MCP servers (Playwright-based) typically save screenshots inside
#   the docker container at paths like /tmp/playwright-output/<file>.png.
#   The host cannot reach those files - they are visible only inside the
#   container. Any capture path that lands in the container MUST end with
#   a host-side copy, or the screenshot is functionally invisible to the user.
#
# What it does:
#   1. Locates a running container that matches the MCP browser label
#      (default: docker-mcp-name=playwright).
#   2. Runs `docker cp <container>:<source> <destination>`.
#   3. Prints the absolute host path on success.
#
# Usage:
#   ./copy_mcp_capture_to_host.sh <container-path> <host-destination>
#
# Examples:
#   ./copy_mcp_capture_to_host.sh /tmp/playwright-output/page-XYZ.png ~/Desktop/shot.png
#   ./copy_mcp_capture_to_host.sh ../tmp/playwright-output/page-XYZ.png ~/Desktop/shot.png
#       (a "../tmp/..." path from the MCP output resolves to /tmp/... inside the container)
#
# Options:
#   --container NAME   Container name or id. Skip auto-detection.
#   --label KEY=VALUE  Override the docker label used for auto-detection
#                      (default: docker-mcp-name=playwright).

set -euo pipefail

CONTAINER=""
LABEL_FILTER="docker-mcp-name=playwright"
SRC=""
DST=""

usage() {
  echo "Usage: $0 <container-path> <host-destination> [--container NAME] [--label KEY=VALUE]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --container) CONTAINER="$2"; shift 2 ;;
    --label) LABEL_FILTER="$2"; shift 2 ;;
    -h|--help) usage ;;
    *)
      if [[ -z "$SRC" ]]; then SRC="$1"
      elif [[ -z "$DST" ]]; then DST="$1"
      else echo "Unexpected argument: $1" >&2; usage
      fi
      shift ;;
  esac
done

[[ -z "$SRC" || -z "$DST" ]] && usage

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not on PATH." >&2
  exit 3
fi

# MCP browsers often report container-internal paths as ../tmp/playwright-output/...
# (relative to the MCP server's CWD at /app). Resolve to /tmp/... when that's the case.
if [[ "$SRC" == ../tmp/* ]]; then
  SRC="${SRC#../}"
  SRC="/$SRC"
fi

if [[ -z "$CONTAINER" ]]; then
  CONTAINER=$(docker ps --filter "label=$LABEL_FILTER" --format '{{.Names}}' | head -n 1)
  if [[ -z "$CONTAINER" ]]; then
    echo "No running container matched label '$LABEL_FILTER'." >&2
    echo "Pass --container <name> explicitly, or change --label." >&2
    exit 4
  fi
fi

DST_DIR="$(dirname "$DST")"
mkdir -p "$DST_DIR"
DST_ABS="$(cd "$DST_DIR" && pwd)/$(basename "$DST")"

docker cp "$CONTAINER:$SRC" "$DST_ABS"

echo "$DST_ABS"

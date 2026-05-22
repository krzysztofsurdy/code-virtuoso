#!/usr/bin/env bash
# Tier 3 (last resort): open the URL in the system's own browser using built-in
# OS commands, then capture the screen with the OS's built-in screenshot tool.
#
# No install needed beyond what comes with the OS. This is the most brittle
# tier - it steals focus, depends on OS permissions, and produces a shot that
# includes whatever browser chrome happens to be visible. Use only after
# Tiers 1 and 2 are not viable.
#
# Cross-platform dispatcher: detects the OS and runs the right native commands.
#
# What it does, per platform:
#
#   macOS:
#     - osascript: opens URL in a new Google Chrome tab and reads window bounds
#     - screencapture -R: captures that screen region
#     - Requires: System Settings -> Privacy & Security -> Screen Recording
#       allowed for the calling Terminal (prompted on first failure)
#
#   Linux (X11):
#     - xdg-open <url> (or google-chrome <url>) to load the page
#     - import (ImageMagick) -window root, or `scrot` if installed
#     - Requires: ImageMagick or scrot, plus an X11 session
#
#   Linux (Wayland):
#     - xdg-open <url>
#     - grim out.png (sway/wlroots), or gnome-screenshot -w -f out.png
#     - Requires: grim or gnome-screenshot
#
#   Windows:
#     - Start-Process chrome <url>
#     - PowerShell Add-Type capture or `nircmd savescreenshot out.png`
#     - Requires: Chrome in PATH, PowerShell
#
# Usage:
#   ./capture_via_system_browser.sh <url> <output.png> [--wait SECS]

set -euo pipefail

URL=""
OUTPUT=""
WAIT_SECS="5"

usage() {
  echo "Usage: $0 <url> <output.png> [--wait SECS]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --wait) WAIT_SECS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *)
      if [[ -z "$URL" ]]; then URL="$1"
      elif [[ -z "$OUTPUT" ]]; then OUTPUT="$1"
      else echo "Unexpected argument: $1" >&2; usage
      fi
      shift ;;
  esac
done

[[ -z "$URL" || -z "$OUTPUT" ]] && usage

OUTPUT_DIR="$(dirname "$OUTPUT")"
mkdir -p "$OUTPUT_DIR"
OUTPUT_ABS="$(cd "$OUTPUT_DIR" && pwd)/$(basename "$OUTPUT")"

OS="$(uname)"

case "$OS" in
  Darwin)
    echo "Platform: macOS. Opening Chrome..." >&2
    TAB_INDEX=$(osascript <<EOF
tell application "Google Chrome"
  activate
  if (count of windows) = 0 then make new window
  tell front window
    set newTab to make new tab with properties {URL:"$URL"}
    return (count of tabs)
  end tell
end tell
EOF
)

    # Poll Chrome's tab loading state up to WAIT_SECS.
    ELAPSED=0
    MAX=$((WAIT_SECS + 15))
    while [[ "$ELAPSED" -lt "$MAX" ]]; do
      LOADING=$(osascript <<EOF
tell application "Google Chrome"
  tell front window
    return loading of tab $TAB_INDEX
  end tell
end tell
EOF
)
      [[ "$LOADING" == "false" ]] && break
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done
    sleep 1

    osascript <<EOF >/dev/null
tell application "Google Chrome"
  activate
  tell front window
    set active tab index to $TAB_INDEX
  end tell
end tell
EOF
    sleep 0.3

    BOUNDS=$(osascript <<'EOF'
tell application "Google Chrome"
  set b to bounds of front window
  set xPos to item 1 of b
  set yPos to item 2 of b
  set wVal to (item 3 of b) - xPos
  set hVal to (item 4 of b) - yPos
  return (xPos as text) & "," & (yPos as text) & "," & (wVal as text) & "," & (hVal as text)
end tell
EOF
)

    if ! screencapture -x -o -R"$BOUNDS" "$OUTPUT_ABS"; then
      echo "screencapture failed - likely missing Screen Recording permission for Terminal." >&2
      echo "Grant it in System Settings -> Privacy & Security -> Screen Recording, then re-run." >&2
      exit 4
    fi
    ;;

  Linux)
    echo "Platform: Linux. Opening default browser..." >&2
    xdg-open "$URL" >/dev/null 2>&1 || google-chrome "$URL" >/dev/null 2>&1 &
    sleep "$WAIT_SECS"

    if command -v grim >/dev/null 2>&1; then
      grim "$OUTPUT_ABS"
    elif command -v import >/dev/null 2>&1; then
      import -window root "$OUTPUT_ABS"
    elif command -v scrot >/dev/null 2>&1; then
      scrot "$OUTPUT_ABS"
    elif command -v gnome-screenshot >/dev/null 2>&1; then
      gnome-screenshot -f "$OUTPUT_ABS"
    else
      echo "No screen capture tool found. Install one of: grim (Wayland), ImageMagick, scrot, gnome-screenshot." >&2
      exit 5
    fi
    ;;

  MINGW*|MSYS*|CYGWIN*)
    echo "Platform: Windows (POSIX subsystem). Launching Chrome and capturing with PowerShell..." >&2
    powershell.exe -NoProfile -Command "Start-Process chrome '$URL'" >/dev/null 2>&1
    sleep "$WAIT_SECS"

    powershell.exe -NoProfile -Command "
      Add-Type -AssemblyName System.Drawing;
      Add-Type -AssemblyName System.Windows.Forms;
      \$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds;
      \$bitmap = New-Object System.Drawing.Bitmap \$bounds.Width, \$bounds.Height;
      \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap);
      \$graphics.CopyFromScreen(\$bounds.Location, [System.Drawing.Point]::Empty, \$bounds.Size);
      \$bitmap.Save('$OUTPUT_ABS', [System.Drawing.Imaging.ImageFormat]::Png);
      \$graphics.Dispose();
      \$bitmap.Dispose();
    "
    ;;

  *)
    echo "Unsupported platform: $OS. Supported: Darwin (macOS), Linux, Windows (MSYS/Cygwin)." >&2
    exit 6
    ;;
esac

echo "$OUTPUT_ABS"

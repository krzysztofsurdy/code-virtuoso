#!/usr/bin/env bash
set -euo pipefail
mkdir -p skills .github
cat > .github/dependabot.yml <<'YML'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
YML

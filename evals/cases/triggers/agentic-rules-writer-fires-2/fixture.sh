#!/usr/bin/env bash
set -euo pipefail
{
  echo "# Project rules"
  echo
  echo "## Commands"
  echo "- Test one file: make test-one T=path/to/test"
  echo
  echo "## Principles"
  for i in $(seq 1 40); do
    echo "- Write clean, maintainable code and keep changes minimal ($i)."
    echo "- Read the code before editing it and never guess ($i)."
  done
  echo
  echo "## Safety"
  echo "- Never force push to main."
  echo "- Never read .env files."
} > AGENTS.md

#!/usr/bin/env bash
set -euo pipefail
{
  echo "# Project rules"
  for i in $(seq 1 450); do
    echo "- Rule $i: follow convention $i in module $i."
    echo "  Applies to files under src/module$i/ and to their tests."
  done
} > CLAUDE.md

#!/usr/bin/env bash
# Runs the Code Virtuoso eval suites with `claude plugin eval` against a staged plugin.
# Usage: evals/run.sh [check|triggers|outcomes|all] [extra claude plugin eval options]
# `check` loads every case without running any (free): it fails when a case file is malformed.
# Environment: EVAL_THRESHOLD (default 0.8), EVAL_OUT (results dir, default a new temp dir),
#              EVAL_MODEL and EVAL_JUDGE_MODEL (pin the models), EVAL_DRY_RUN=1 (print, do not run).
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
mode=${1:-all}
[ "$#" -eq 0 ] || shift

case "$mode" in
  check | triggers | outcomes | all) ;;
  *)
    echo "usage: run.sh [check|triggers|outcomes|all] [claude plugin eval options]" >&2
    exit 2
    ;;
esac

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
"$here/stage.sh" "$stage" > /dev/null

out=${EVAL_OUT:-$(mktemp -d)}
common=(--trust-plugin --scaffold --no-publish --threshold "${EVAL_THRESHOLD:-0.8}")
[ -z "${EVAL_MODEL:-}" ] || common+=(--model "$EVAL_MODEL")
[ -z "${EVAL_JUDGE_MODEL:-}" ] || common+=(--judge-model "$EVAL_JUDGE_MODEL")

run() {
  if [ -n "${EVAL_DRY_RUN:-}" ]; then
    echo "claude plugin eval $*"
  else
    claude plugin eval "$@"
  fi
}

status=0

if [ "$mode" = check ]; then
  if [ -n "${EVAL_DRY_RUN:-}" ]; then
    run "$stage" --trust-plugin --tag __none__
    exit 0
  fi
  log=$(claude plugin eval "$stage" --trust-plugin --tag __none__ 2>&1 || true)
  if grep -q "failed to load" <<< "$log"; then
    echo "$log" >&2
    exit 1
  fi
  echo "all cases load"
  exit 0
fi

if [ "$mode" = triggers ] || [ "$mode" = all ]; then
  run "$stage" "${common[@]}" --ablation none --output-dir "$out/triggers" --tag trigger demotion "$@" || status=$?
fi

if [ "$mode" = outcomes ] || [ "$mode" = all ]; then
  run "$stage" "${common[@]}" --allow-tools Write Edit "Bash(python3 *)" --output-dir "$out/outcomes" --tag outcome "$@" || rc=$?
  [ "${rc:-0}" -le "$status" ] || status=$rc
fi

[ -n "${EVAL_DRY_RUN:-}" ] || echo "Results: $out"
exit "$status"

#!/bin/bash
# One `claude -p` call, shared by run-batch.sh and eval-setup.sh. Callers build
# the argument list; this runs it and classifies a failed invocation.

# invoke_claude <dir> <claude args...>
# Runs `claude <args>` in <dir>. Sets INVOKE_JSON (stdout) and INVOKE_STDERR.
# The exit code is swallowed: a max-turns/max-budget cutoff exits non-zero but
# still returns a JSON envelope, so the caller decides from the output.
invoke_claude() {
  local dir="$1" stderr_file
  shift
  stderr_file="$(mktemp)"
  INVOKE_JSON="$( (cd "$dir" && claude "$@") 2>"$stderr_file" )" || true
  INVOKE_STDERR="$(cat "$stderr_file")"
  rm -f "$stderr_file"
}

# invoke_failure_hint <stderr>
# Most common cause of no JSON at all under a Claude subscription is the
# plan's usage/rate limit; say so when stderr points there.
invoke_failure_hint() {
  if echo "$1" | grep -qiE 'usage limit|rate limit|quota|too many requests|overloaded|billing'; then
    echo "likely a usage/rate limit"
  else
    echo "other (see detail)"
  fi
}

# invoke_failure_detail <stderr>: the first 200 characters on one line.
invoke_failure_detail() {
  echo "$1" | tr '\n' ' ' | cut -c1-200
}

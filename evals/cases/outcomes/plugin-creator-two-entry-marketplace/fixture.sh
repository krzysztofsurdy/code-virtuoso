#!/usr/bin/env bash
set -euo pipefail
mkdir -p skills/lint-docs skills/triage-bugs agents
cat > skills/lint-docs/SKILL.md <<'MD'
---
name: lint-docs
description: Checks markdown docs for broken links and stale commands. Use when reviewing docs.
user-invocable: true
---

# Lint docs

Check each link and command in the docs.
MD
cat > skills/triage-bugs/SKILL.md <<'MD'
---
name: triage-bugs
description: Sorts incoming bug reports by severity. Use when triaging a bug queue.
user-invocable: true
---

# Triage bugs

Sort reports by severity and owner.
MD
cat > agents/reviewer.md <<'MD'
---
name: reviewer
description: Reviews a diff for correctness. Delegate before merging.
tools: Read, Grep, Glob, Bash
---

You review a diff and report findings.
MD

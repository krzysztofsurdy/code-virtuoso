#!/usr/bin/env bash
set -euo pipefail
mkdir -p skills/release-notes agents .claude-plugin
cat > .claude-plugin/plugin.json <<'JSON'
{"name": "team-docs", "version": "1.0.0", "description": "Docs tooling for the team"}
JSON
cat > skills/release-notes/SKILL.md <<'MD'
---
name: release-notes
description: Writes release notes from merged pull requests.
user-invocable: true
disable-model-invocation: true
---

# Release notes

Summarize merged pull requests into a changelog entry.
MD
cat > agents/changelog-bot.md <<'MD'
---
name: changelog-bot
description: Drafts changelog entries from a diff. Delegate after a feature lands.
tools: Read, Grep, Glob, Bash
---

You draft changelog entries from a diff.
MD

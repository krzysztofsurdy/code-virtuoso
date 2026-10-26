---
type: llm
focus: last_message
---

PASS if the reply says Claude Code reads AGENTS.md by itself only when no CLAUDE.md exists in the directory (so with a CLAUDE.md present the import line is needed).
FAIL if the reply says Claude Code always reads AGENTS.md, or does not say when Claude Code reads it.

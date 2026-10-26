---
type: llm
focus: last_message
---

PASS if the reply recommends keeping the project rules in AGENTS.md only, with a CLAUDE.md whose first line imports it (@AGENTS.md) and that holds only Claude-specific lines, AND says the import does not reduce token cost because the imported file still loads at session start (so the saving comes from deleting duplicates and keeping the file short, not from the import).
FAIL if the reply claims the import or a symlink lowers per-session token cost, keeps duplicated rules in both files, or never says what happens to the cost.

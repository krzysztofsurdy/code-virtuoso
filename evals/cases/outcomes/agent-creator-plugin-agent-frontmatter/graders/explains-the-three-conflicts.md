---
type: llm
focus: last_message
---

PASS if the reply tells the user all three of these: (1) setting project memory means the agent can write files (memory enables Read, Write and Edit), so it is no longer strictly read-only; (2) hooks and mcpServers set on an agent that a plugin ships are ignored, so they belong in the plugin's hooks/hooks.json and .mcp.json instead; (3) the release-notes skill cannot be preloaded because it is a run-by-name skill (disable-model-invocation).
FAIL if the reply claims the agent is read-only while it has memory, silently puts hooks or mcpServers in the agent frontmatter as if they work, preloads the run-by-name skill without a warning, or omits any one of the three points.

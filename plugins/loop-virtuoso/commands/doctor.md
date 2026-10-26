---
description: "Read-only audit of your Claude Code setup: duplicate skills and agents, skill listing size, CLAUDE.md references, plaintext MCP secrets, settings gaps, orphan plugin caches"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh:*)"]
---

# Setup doctor

Run the doctor script:

```
${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh
```

It reads `${CLAUDE_CONFIG_DIR:-~/.claude}` and `~/.claude.json` and writes nothing. Each finding has a severity (high, medium, low), what is wrong, where (a path), and the fix.

Relay the output verbatim. Don't summarize or add commentary unless the user asks a follow-up. Then:

- If there are `settings-*` or `loop-guard` findings, offer `/loop-virtuoso:harden`, which shows a diff and changes nothing until the user approves it.
- For `mcp-secret` findings the script prints the server and key name only, never the value. Do not open `~/.claude.json` to look at the value.
- Do not delete skills, agents or cache directories on your own. List what you would remove and ask first.

The skill listing figure is an estimate: it assumes a 200k-token context window, so the budget (1% of the context) is about 8,000 characters. `/context` shows the real figure.

# Phase 2: Component selection

**Progress: Phase 2 of 6**

## Purpose

Decide which component types this plugin includes. Select at least one.

## Steps

1. Present a multi-select menu of available component types:

   | Component | Default location | Purpose |
   |---|---|---|
   | Skills | `skills/<name>/SKILL.md` | User- or model-invokable capabilities |
   | Agents | `agents/<name>.md` | Specialized subagents with tool allow-lists |
   | Workflows | `workflows/<name>.js` | Scripts that run a fixed recipe of agents, run as `/plugin:name` (paid plans) |
   | Commands | `commands/<name>.md` | Flat skill files (legacy format, still supported) |
   | Hooks | `hooks/hooks.json` | Event handlers (PreToolUse, PostToolUse, etc.) |
   | MCP servers | `.mcp.json` | External tool integrations via Model Context Protocol |
   | LSP servers | `.lsp.json` | Language Server Protocol for code intelligence |
   | Bin executables | `bin/` | Shell scripts added to tool PATH |
   | Output styles | `output-styles/` | Custom response styles |
   | Default settings | `settings.json` | Pre-configured agent overrides |

2. Validate at least one component is selected. If none, ask again.

3. Note the default scans: Claude Code registers whatever sits in `agents/`, `commands/`, `workflows/`, `hooks/hooks.json`, `output-styles/`, and `.mcp.json` under the plugin source, without listing them. A plugin inside a repository that already has a root marketplace entry should live in its own directory (for example `plugins/<name>/`) so its components are not registered twice.

4. Summarize the selection for confirmation.

## Gate

**Advances when:** User confirms the selected component types.
**Returns to this phase when:** User wants to add or remove component types.

Ask the user: "Selected components: [list]. Confirm, or add/remove?"

Do not proceed to Phase 3 until the user confirms.

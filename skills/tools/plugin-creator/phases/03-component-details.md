# Phase 3: Component Details

**Progress: Phase 3 of 6**

## Purpose

For each selected component type, run a sub-questionnaire to gather the details needed to scaffold it. Loop through each type until all are configured.

## Steps

For each component type selected in Phase 2, run the matching sub-questionnaire. See [references/component-templates.md](../references/component-templates.md) for file templates.

### Skills (for each skill)
1. Skill name (kebab-case)
2. Description (free text) - goes into frontmatter
3. Invocation model: Model-invoked (default) or User-only (`disable-model-invocation: true`)
4. Needs arguments? (yes/no) - adds `argument-hint` and `$ARGUMENTS`
5. Add references directory? (yes/no)
After each: "Add another skill?" (yes/no)

### Agents (for each agent)
1. Agent name (kebab-case)
2. Description (free text)
3. Isolation: None (default) or worktree
4. Tool allow-list: Read-only, Full access, or Custom
5. Memory: none or project
6. Preload skills? (comma-separated names, optional)
Plugin agents cannot set `hooks`, `mcpServers`, or `permissionMode`.

### Hooks
1. Which lifecycle events? (multi-select: SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, FileChanged, CwdChanged)
2. For each event: matcher pattern (optional regex), hook type (command/http/prompt/agent), command/body

### MCP Servers (for each)
1. Server key (kebab-case)
2. Command (e.g., `npx`, `${CLAUDE_PLUGIN_ROOT}/servers/db-server`)
3. Args (comma-separated, optional)
4. Environment variables (KEY=VALUE, optional)

### LSP Servers (for each)
1. Language identifier (e.g., `go`, `typescript`)
2. Binary (must be on `$PATH`)
3. Args (optional)
4. File extensions (comma-separated)

### Bin Executables (for each)
1. Executable name
2. Language: bash/node/python/other
3. Short description

### Output Styles (for each)
1. Style name (kebab-case)
2. Style description

### Default Settings
1. Which plugin agent should be the main thread default? (single-select from agents, or None)

## Gate

**Advances when:** All selected component types have been configured and user confirms.
**Returns to this phase when:** User wants to add more components or edit existing ones.

Ask the user: "All components configured: [summary]. Confirm, or edit a component?"

Do NOT proceed to Phase 4 until the user confirms.

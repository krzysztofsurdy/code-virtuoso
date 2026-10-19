# Phase 3: Component details

**Progress: Phase 3 of 6**

## Purpose

For each selected component type, run a sub-questionnaire to gather the details needed to scaffold it. Repeat for each type until all are configured.

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
3. Isolation: None (default) or worktree. Use worktree only when the agent changes source code
4. Tool allow-list: Read-only, Edit and Write, or Custom
5. Memory: none or project. Claude Code enables Read, Write, and Edit for an agent with memory
6. Preload skills? (bare names, at most four, optional). They resolve across installed plugins and are skipped silently if missing
Plugin agents ignore `hooks`, `mcpServers`, and `permissionMode`. Role agents read reference files from a `roles/<role>/` folder by path, not from a role skill. For a full agent design, use the `agent-creator` skill.

### Workflows (for each)
1. Workflow name (kebab-case, equals the file name and `meta.name`)
2. Description and the agents it runs (plugin-scoped names such as `<plugin>:<agent>`)
3. Phases, and which phases run in parallel
Scripts must start with a pure-literal `export const meta = { ... }` and cannot use `import`, `Date.now()`, or `Math.random()`. See [component-templates.md](../references/component-templates.md#workflow-script).

### Commands (for each)
1. Command name and description
2. Whether it takes arguments (`$ARGUMENTS`)

### Hooks
1. Which lifecycle events? (multi-select: SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, FileChanged, CwdChanged)
2. For each event: matcher pattern (optional regex), hook type (command/http/prompt/agent), command/body

### MCP servers (for each)
1. Server key (kebab-case)
2. Command (e.g., `npx`, `${CLAUDE_PLUGIN_ROOT}/servers/db-server`)
3. Args (comma-separated, optional)
4. Environment variables (KEY=VALUE, optional)

### LSP servers (for each)
1. Language identifier (e.g., `go`, `typescript`)
2. Binary (must be on `$PATH`)
3. Args (optional)
4. File extensions (comma-separated)

### Bin executables (for each)
1. Executable name
2. Language: bash/node/python/other
3. Short description
Files in `bin/` go on the Bash tool's `PATH` while the plugin is enabled, so keep names specific and never shadow a system command.

### Settings the plugin needs from users
Ask whether the plugin needs saved values. Plugin-level settings Claude Code should prompt for at enable time (an endpoint, a token) go in `userConfig`. Team or project decisions (branch pattern, test command, tuning) do not go in the plugin: point them at the layered config in [plugin-manifest.md](../references/plugin-manifest.md#persistent-user-and-project-choices). Never store them under `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_DATA}`.

### Output styles (for each)
1. Style name (kebab-case)
2. Style description

### Default settings
1. Which plugin agent should be the main thread default? (single-select from agents, or None)

## Gate

**Advances when:** All selected component types have been configured and user confirms.
**Returns to this phase when:** User wants to add more components or edit existing ones.

Ask the user: "All components configured: [summary]. Confirm, or edit a component?"

Do not proceed to Phase 4 until the user confirms.

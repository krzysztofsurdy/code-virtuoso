# Phase 5: Write files

**Progress: Phase 5 of 6**

## Purpose

Write all generated files in a single pass after final validation and user approval.

## Steps

1. **Validate before writing:**
   - Plugin name is valid kebab-case, not a reserved marketplace name
   - Generated JSON (plugin.json, marketplace.json) parses cleanly
   - All paths use `./` or `${CLAUDE_PLUGIN_ROOT}`, no absolute paths
   - Marketplace entry hooks (if any) are an inline object, not a path
   - No state or user choices are written under `${CLAUDE_PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_DATA}`

2. **Show the target directory and the full file tree** to the user for final approval.

3. **Write all files.** Directory structure:
   ```
   <plugin-name>/
   ├── .claude-plugin/plugin.json
   ├── skills/<name>/SKILL.md          (if skills)
   ├── agents/<name>.md                (if agents)
   ├── commands/<name>.md              (if commands)
   ├── workflows/<name>.js             (if workflows)
   ├── hooks/hooks.json                (if hooks)
   ├── .mcp.json                       (if MCP servers)
   ├── .lsp.json                       (if LSP servers)
   ├── bin/<name>                      (if executables)
   ├── output-styles/<name>.md         (if styles)
   ├── scripts/<hook-name>.sh          (if hooks use bundled scripts)
   ├── settings.json                   (if default settings)
   ├── LICENSE                         (if license chosen, skip for UNLICENSED)
   └── CHANGELOG.md                    (seeded with version entry)
   ```

4. Use templates from [references/component-templates.md](../references/component-templates.md) for each file.

5. Never invent fields not in the schema. Never put components inside `.claude-plugin/`.

## Gate

**Advances when:** All files written successfully and user confirms.
**Returns to Phase 3 when:** Validation fails on a specific component.

Ask the user: "All files written to `[path]`. Proceed to test instructions?"

Do not proceed to Phase 6 until the user confirms.

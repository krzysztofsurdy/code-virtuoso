# Component templates

File templates for every plugin component. Replace the `<placeholder>` values when scaffolding.

## Contents

- [plugin.json (minimal)](#pluginjson-minimal)
- [plugin.json (with metadata)](#pluginjson-with-metadata)
- [plugin.json (with user config and channels)](#pluginjson-with-user-config-and-channels)
- [SKILL.md (model-invoked)](#skillmd-model-invoked)
- [SKILL.md (user-invoked only)](#skillmd-user-invoked-only)
- [Agent file (read-only specialist)](#agent-file-read-only-specialist)
- [Agent file (source code, worktree-isolated)](#agent-file-source-code-worktree-isolated)
- [Agent file (role with reference files)](#agent-file-role-with-reference-files)
- [Workflow script](#workflow-script)
- [hooks/hooks.json](#hookshooksjson)
- [.mcp.json](#mcpjson)
- [.lsp.json](#lspjson)
- [settings.json](#settingsjson)
- [bin/ executable stubs](#bin-executable-stubs)
- [Output style file](#output-style-file)
- [Script helpers](#script-helpers)
- [CHANGELOG.md seed](#changelogmd-seed)

## plugin.json (minimal)

```json
{
  "name": "<plugin-name>",
  "description": "<one-sentence description>",
  "version": "1.0.0"
}
```

## plugin.json (with metadata)

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<one-sentence description>",
  "author": {
    "name": "<Your Name>",
    "email": "<you@example.com>"
  },
  "homepage": "https://github.com/<owner>/<repo>",
  "repository": "https://github.com/<owner>/<repo>",
  "license": "MIT",
  "keywords": ["<tag1>", "<tag2>"]
}
```

## plugin.json (with user config and channels)

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "<description>",
  "userConfig": {
    "api_endpoint": { "type": "string", "title": "API endpoint", "description": "API endpoint URL" },
    "api_token": { "type": "string", "title": "API token", "description": "API authentication token", "sensitive": true }
  },
  "mcpServers": "./.mcp.json",
  "channels": [
    {
      "server": "<server-key>",
      "userConfig": {
        "bot_token": { "type": "string", "title": "Bot token", "description": "Bot token", "sensitive": true }
      }
    }
  ]
}
```

## SKILL.md (model-invoked)

```markdown
---
name: <skill-name>
description: <What this skill does. Use when <trigger condition>.>
---

# <Skill Title>

<Brief description of the skill's purpose.>

## When to Use

- <Situation 1>
- <Situation 2>

## Workflow

1. <Step one>
2. <Step two>
3. <Step three>
```

## SKILL.md (user-invoked only)

```markdown
---
name: <skill-name>
description: <Description for discoverability.>
disable-model-invocation: true
argument-hint: "[optional: <arg-description>]"
---

# <Skill Title>

<Description.>

## Arguments

If `$ARGUMENTS` is provided, <what to do with it>. Otherwise ask the user.
```

## Agent file (read-only specialist)

```markdown
---
name: <agent-name>
description: <What this agent does. Delegate when <trigger condition>.>
tools: Read, Grep, Glob, Bash
---

You are a <role>. You <core responsibility>.

## Input

<What the agent receives.>

## Process

1. <Step one>
2. <Step two>
3. <Step three>

## Rules

- <Constraint 1>
- <Constraint 2>

## Output

<What the agent returns when finished.>
```

## Agent file (source code, worktree-isolated)

```markdown
---
name: <agent-name>
description: <Description. Delegate when ...>
tools: Read, Grep, Glob, Bash, Edit, Write
isolation: worktree
skills:
  - <skill-name>
---

You are a <role>. Work in an isolated worktree. Commit after each logical change.

## Input

<What the agent receives.>

## Process

1. <Step one>
2. <Step two>

## Rules

- <Constraint>

## Output

<Template.>
```

Use `isolation: worktree` only for agents that change source code. A documentation-only writer uses the same `tools` line without `isolation`. List preloaded skills by bare name, at most four, and only skills that are not run-by-name. A missing skill is skipped silently, so the agent must work without it.

**Ignored on plugin agents**: `hooks`, `mcpServers`, `permissionMode`. Put hooks in `hooks/hooks.json` and MCP servers in `.mcp.json`.

## Agent file (role with reference files)

```markdown
---
name: <role-name>
description: <Description. Delegate when ...>
tools: Read, Grep, Glob, Bash
memory: project
---

You are the team's <role>. You own <domain>. You write only <documents and memory notes>, never source code.

## Process

1. <Step one>

## Reference files

- `${CLAUDE_PLUGIN_ROOT}/roles/<role-name>/<template>.md` (or `roles/<role-name>/<template>.md` from the repository root): open when <task>
```

The reference files are plain Markdown without frontmatter in `roles/<role-name>/`, so they ship with the plugin source and load only when the agent opens them. There is no role skill. `memory` makes Claude Code enable Read, Write, and Edit for the agent. For a full agent design, use the `agent-creator` skill.

## Workflow script

`workflows/<name>.js` runs a fixed recipe of agents as `/<plugin>:<name>` (paid plans). The first statement is a pure-literal `meta` whose `name` equals the file name. The body is plain JavaScript with top-level `await` and a final `return`. It may not use `import`, `Date.now()`, or `Math.random()`.

```javascript
export const meta = {
  name: '<name>',
  description: '<what the team delivers, in one sentence>',
  whenToUse: '<when to run it and the args it takes>',
  phases: [
    { title: 'Work', detail: '<which agents run>' },
    { title: 'Review', detail: '<who merges the results>' },
  ],
}

const input = args || {}
if (typeof input.target !== 'string' || !input.target.trim()) {
  return { status: 'error', reason: 'args.target is required' }
}

phase('Work')
const results = await parallel([
  () => agent(`<full brief>. Target: ${input.target}.`, {
    label: '<label>',
    phase: 'Work',
    agentType: '<plugin>:<agent-name>',
  }),
])

const reports = results.filter(Boolean)
if (reports.length === 0) {
  return { status: 'blocked', reason: 'every agent in the Work phase failed' }
}

phase('Review')
const report = await agent(`<lead brief>\n${JSON.stringify(reports)}`, {
  label: 'Review',
  phase: 'Review',
  agentType: '<plugin>:<agent-name>',
})

return { status: 'approved', target: input.target, report }
```

Use plugin-scoped `agentType` names, filter `null` results, and return a status object instead of looping at a gate. Pass a JSON `schema` wherever a later step reads the result. A team is also written as a Markdown recipe so other agent harnesses can follow it: see the `agent-orchestration` skill.

## hooks/hooks.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/session-init.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "prompt",
            "command": "Summarize context before processing: $ARGUMENTS"
          }
        ]
      }
    ]
  }
}
```

### Supported hook events

| Event                | Fires when                                                                                            |
|----------------------|-------------------------------------------------------------------------------------------------------|
| `SessionStart`       | Session begins or resumes.                                                                            |
| `SessionEnd`         | Session terminates.                                                                                   |
| `UserPromptSubmit`   | User submits a prompt, before Claude processes it.                                                    |
| `PreToolUse`         | Before a tool call executes. Can block the call.                                                      |
| `PostToolUse`        | After a tool call succeeds.                                                                           |
| `PostToolUseFailure` | After a tool call fails.                                                                              |
| `PermissionRequest`  | A permission dialog appears.                                                                          |
| `PermissionDenied`   | A tool call is auto-denied. Return `{retry: true}` to let the model retry.                            |
| `Notification`       | Claude Code sends a notification.                                                                     |
| `SubagentStart`      | A subagent is spawned.                                                                                |
| `SubagentStop`       | A subagent finishes.                                                                                  |
| `TaskCreated`        | A task is created via `TaskCreate`.                                                                   |
| `TaskCompleted`      | A task is marked completed.                                                                           |
| `Stop`               | Claude finishes responding.                                                                           |
| `StopFailure`        | Turn ends due to an API error.                                                                        |
| `TeammateIdle`       | An agent-team teammate is about to go idle.                                                           |
| `InstructionsLoaded` | A CLAUDE.md or `.claude/rules/*.md` file is loaded into context.                                      |
| `ConfigChange`       | A configuration file changes during a session.                                                        |
| `CwdChanged`         | Working directory changes (e.g., after a `cd`).                                                       |
| `FileChanged`        | A watched file changes on disk. `matcher` specifies filenames.                                        |
| `WorktreeCreate`     | A worktree is being created via `--worktree` or `isolation: "worktree"`.                              |
| `WorktreeRemove`     | A worktree is being removed.                                                                          |
| `PreCompact`         | Before context compaction.                                                                            |
| `PostCompact`        | After context compaction.                                                                             |
| `Elicitation`        | An MCP server requests user input during a tool call.                                                 |
| `ElicitationResult`  | After a user responds to an MCP elicitation, before the response is sent back.                        |

### Hook types

| Type      | Behavior                                                                                              |
|-----------|-------------------------------------------------------------------------------------------------------|
| `command` | Execute shell command or script. Hook input is piped as JSON on stdin.                                |
| `http`    | POST the event JSON to a URL.                                                                         |
| `prompt`  | Evaluate a prompt with an LLM. `$ARGUMENTS` is substituted with event context.                        |
| `agent`   | Run an agentic verifier with tools for complex verification.                                          |

## .mcp.json

```json
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_DATA}/db"
      }
    },
    "plugin-api-client": {
      "command": "npx",
      "args": ["@company/mcp-server", "--plugin-mode"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

## .lsp.json

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

### Optional LSP fields

| Field                   | Description                                                     |
|-------------------------|-----------------------------------------------------------------|
| `args`                  | Command-line arguments.                                         |
| `transport`             | `stdio` (default) or `socket`.                                  |
| `env`                   | Environment variables at server startup.                        |
| `initializationOptions` | Options passed during LSP `initialize`.                         |
| `settings`              | Config via `workspace/didChangeConfiguration`.                  |
| `workspaceFolder`       | Workspace folder path.                                          |
| `startupTimeout`        | Max wait for startup (ms).                                      |
| `shutdownTimeout`       | Max wait for graceful shutdown (ms).                            |
| `restartOnCrash`        | Auto-restart on crash.                                          |
| `maxRestarts`           | Max restart attempts before giving up.                          |

Users must install the language server binary separately. An LSP plugin only configures the connection.

## settings.json

Only the `agent` key is currently supported. Activates a plugin-shipped agent as the main thread when the plugin is enabled.

```json
{
  "agent": "<agent-name>"
}
```

The referenced agent name must match a file in the plugin's `agents/` directory (without the `.md` extension).

## bin/ executable stubs

Files in `bin/` are on the Bash tool's `PATH` while the plugin is enabled, so Claude and skill instructions run them as bare commands. They must be executable and start with a shebang. `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` are not set in the environment of commands run through the Bash tool, so a stub finds its bundled files relative to itself, or takes a path as an argument.

### Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

# <Name> - <Description>

plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Running ${0##*/} from $plugin_root"
```

### Node

```javascript
#!/usr/bin/env node

// <Name> - <Description>

const path = require("path");
const pluginRoot = path.resolve(__dirname, "..");
console.log(`Running from ${pluginRoot}`);
```

### Python

```python
#!/usr/bin/env python3

"""<Name> - <Description>"""

from pathlib import Path

plugin_root = Path(__file__).resolve().parent.parent
print(f"Running from {plugin_root}")
```

After writing, remind the user to `chmod +x bin/<name>`.

## Output style file

`output-styles/<style-name>.md`:

```markdown
---
name: <style-name>
description: <When to use this output style.>
---

# <Style Name>

<Instructions that modify Claude's response style. Describe the voice, tone, formatting, verbosity level, etc.>

## Examples

### Input
<example user prompt>

### Output
<how this style would respond>
```

## Script helpers

Hook scripts usually go in `scripts/` at the plugin root:

### scripts/format-code.sh (example hook target)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Reads hook input from stdin as JSON; extracts the edited file path.
file_path=$(jq -r '.tool_input.file_path // empty')

if [[ -z "$file_path" ]]; then
  exit 0
fi

# Run the project's formatter on the file.
cd "$(dirname "$file_path")" && npm run format:file - "$file_path"
```

Make executable: `chmod +x scripts/format-code.sh`.

## CHANGELOG.md seed

```markdown
# Changelog

All notable changes to this plugin are documented here.

## 1.0.0 - <YYYY-MM-DD>

### Added

- Initial release.
```

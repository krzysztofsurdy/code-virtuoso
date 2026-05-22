# Component Templates

Ready-to-use file templates for every plugin component. Replace the `<placeholder>` values when scaffolding.

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
    "api_endpoint": { "description": "API endpoint URL", "sensitive": false },
    "api_token": { "description": "API authentication token", "sensitive": true }
  },
  "mcpServers": "./.mcp.json",
  "channels": [
    {
      "server": "<server-key>",
      "userConfig": {
        "bot_token": { "description": "Bot token", "sensitive": true }
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

## Agent File (read-only specialist)

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

## Agent File (full access, worktree-isolated)

```markdown
---
name: <agent-name>
description: <Description. Delegate when ...>
isolation: worktree
memory: project
skills:
  - <skill-name-1>
  - <skill-name-2>
---

You are a <role>. Work in an isolated worktree. Commit after each logical change.

## Process

1. <Step one>
2. <Step two>
```

**Not supported on plugin agents**: `hooks`, `mcpServers`, `permissionMode`. These are blocked for security.

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

Users must install the language server binary separately. LSP plugins only configure the connection.

## settings.json

Only the `agent` key is currently supported. Activates a plugin-shipped agent as the main thread when the plugin is enabled.

```json
{
  "agent": "<agent-name>"
}
```

The referenced agent name must match a file in the plugin's `agents/` directory (without the `.md` extension).

## bin/ Executable Stubs

### Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

# <Name> - <Description>

# Access plugin-bundled resources via ${CLAUDE_PLUGIN_ROOT}.
echo "Running ${0##*/} from $CLAUDE_PLUGIN_ROOT"
```

### Node

```javascript
#!/usr/bin/env node

// <Name> - <Description>

const pluginRoot = process.env.CLAUDE_PLUGIN_ROOT;
console.log(`Running from ${pluginRoot}`);
```

### Python

```python
#!/usr/bin/env python3

"""<Name> - <Description>"""

import os
plugin_root = os.environ["CLAUDE_PLUGIN_ROOT"]
print(f"Running from {plugin_root}")
```

After writing, remind the user to `chmod +x bin/<name>`.

## Output Style File

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

## Script Helpers

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

## CHANGELOG.md Seed

```markdown
# Changelog

All notable changes to this plugin are documented here.

## 1.0.0 - <YYYY-MM-DD>

### Added

- Initial release.
```

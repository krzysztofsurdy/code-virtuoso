## Contents

- [Paste-ready settings.json](#paste-ready-settingsjson)
- [Where the files go](#where-the-files-go)
- [How each event talks to the agent](#how-each-event-talks-to-the-agent)
- [Notes on the config](#notes-on-the-config)
- [Sources](#sources)

## Paste-ready settings.json

Save as `.claude/settings.json` (shared with the team) or `.claude/settings.local.json` (yours only). Replace the Stop test command with the project's real one.

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(!.env.example)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Edit(./.env)",
      "Edit(./.env.*)",
      "Bash(curl *)",
      "Bash(wget *)"
    ],
    "ask": [
      "Bash(git push *)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-secret-reads.sh",
            "args": [],
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/post-edit-check.sh",
            "args": [],
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-gate.sh",
            "args": ["make test"],
            "timeout": 300
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/reinject-context.sh",
            "args": [],
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Setting `args` puts the hook in exec form with no shell, so the script path needs no quoting and `args[0]` reaches `stop-gate.sh` as one argument. `Bash(curl *)` is a speed bump, not a wall: it does not match `/usr/bin/curl` or `sh -c 'curl ...'`. Use the sandbox network allowlist when the restriction must hold.

`.claude/key-context.md` is the file `reinject-context.sh` reads. Keep it to a few lines: the test command, the generated directories not to edit, the one convention the agent keeps forgetting.

## Where the files go

| File | Purpose |
|---|---|
| `.claude/hooks/*.sh` | Copy the scripts here and run `chmod +x` |
| `.claude/settings.json` | Team-shared settings, committed |
| `.claude/settings.local.json` | Personal overrides, gitignored |
| `~/.claude/settings.json` | All your projects |
| Managed settings | Organization policy that no lower level can override |

Settings sources are merged, and a deny rule at any level blocks the call. Interactive sessions hold back hooks from every settings file until you accept the workspace trust dialog for the folder. In `claude -p` and SDK sessions there is no dialog and the folder counts as trusted, so review `.claude/` before scripting the CLI over a repo you did not write, or pass `--settings '{"disableAllHooks": true}'`.

## How each event talks to the agent

| Event | Matcher filters on | Input fields you will use | To block or feed back | Notes |
|---|---|---|---|---|
| PreToolUse | tool name | `tool_name`, `tool_input` | exit 2 with stderr, or JSON `hookSpecificOutput.permissionDecision: "deny"` with a reason | A deny rule still wins over a hook allow. A hook exit 2 wins over an allow rule |
| PostToolUse | tool name | `tool_input.file_path`, `tool_response` | exit 2 shows stderr to the agent, or JSON `decision: "block"` with `reason` | The tool already ran, so this cannot undo the edit |
| Stop | not used | `cwd`, `stop_hook_active`, `last_assistant_message` | JSON `decision: "block"` with `reason`, or exit 2 | `stop_hook_active` is true when already continuing from a stop hook. Eight consecutive continuations end the turn |
| SessionStart | `startup`, `resume`, `clear`, `compact`, `fork` | `source`, `cwd` | none, adds context | Plain stdout or `hookSpecificOutput.additionalContext` becomes context. Over 10,000 characters is saved to a file with a preview |
| PreCompact | `manual`, `auto` | `trigger`, `custom_instructions` | exit 2 or `decision: "block"` blocks compaction | Cannot inject context. Blocking an auto compaction near the limit makes the request fail |

Exit code 0 means success and stdout is parsed as JSON if it is a single object. Exit code 2 is a blocking error on events that can block. Any other code is a non-blocking error that only shows a notice.

All tool paths in `tool_input` are absolute. Tool names are case-sensitive: `Read`, `Glob`, `Grep`, `Write`, `Edit`, `Bash`.

## Notes on the config

- The optional `if` field on a handler (for example `"if": "Bash(git *)"`) uses permission-rule syntax and avoids spawning a process for every call. It is best effort, so do not use it to enforce a hard rule.
- `PreToolUse` does not fire for files pulled in with `@` in a prompt, because their content is inserted without a tool call. Deny rules cover those paths differently, so test them.
- The sandbox covers shell commands only. Hooks and the file tools run outside it, which is why the secret hook runs even when the sandbox is on.

## Sources

- https://code.claude.com/docs/en/hooks (events, input and output, exit codes, security considerations)
- https://code.claude.com/docs/en/permissions (rule syntax, precedence, hook and rule interaction)
- https://code.claude.com/docs/en/settings-reference (permissions.deny example)

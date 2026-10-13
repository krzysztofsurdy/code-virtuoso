## Contents

- [hooks.json form](#hooksjson-form)
- [config.toml form](#configtoml-form)
- [Where Codex differs from Claude Code](#where-codex-differs-from-claude-code)
- [Sources](#sources)

The same four guardrails work in Codex. Copy the scripts to `.codex/hooks/` and make them executable. Project hooks load only when the project's `.codex/` layer is trusted, and Codex skips new or changed hooks until you review them with `/hooks`.

## hooks.json form

Save as `<repo>/.codex/hooks.json`. The structure is event, then matcher group, then handlers, under a top-level `hooks` key. Matchers are regular expressions.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "^(Bash|apply_patch)$",
        "hooks": [
          {
            "type": "command",
            "command": "\"$(git rev-parse --show-toplevel)/.codex/hooks/block-secret-reads.sh\"",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$(git rev-parse --show-toplevel)/.codex/hooks/stop-gate.sh\" 'make test'",
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
            "command": "\"$(git rev-parse --show-toplevel)/.codex/hooks/reinject-context.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## config.toml form

The same hooks inline in `~/.codex/config.toml` or `<repo>/.codex/config.toml`:

```toml
[[hooks.PreToolUse]]
matcher = "^(Bash|apply_patch)$"

[[hooks.PreToolUse.hooks]]
type = "command"
command = '"$(git rev-parse --show-toplevel)/.codex/hooks/block-secret-reads.sh"'
timeout = 10

[[hooks.Stop.hooks]]
type = "command"
command = '"$(git rev-parse --show-toplevel)/.codex/hooks/stop-gate.sh" "make test"'
timeout = 300

[[hooks.SessionStart]]
matcher = "compact"

[[hooks.SessionStart.hooks]]
type = "command"
command = '"$(git rev-parse --show-toplevel)/.codex/hooks/reinject-context.sh"'
timeout = 10
```

## Where Codex differs from Claude Code

| Topic | Claude Code | Codex |
|---|---|---|
| Config location | `.claude/settings.json` | `.codex/hooks.json` or `[hooks]` in `config.toml` |
| Handler types | command, http, mcp_tool, prompt, agent | `command` and `mcp_tool`. `prompt` and `agent` are parsed but skipped |
| Script arguments | `args` array gives exec form | Put arguments in the `command` string |
| File reads | Dedicated `Read`, `Grep`, `Glob` tools | No `Read` tool is documented. Reads go through `Bash`, so the Bash check carries the secret guard |
| File edits | `Edit`, `Write`, `MultiEdit` with `tool_input.file_path` | `apply_patch` with the patch text in `tool_input.command`. The matcher also accepts `Edit` and `Write` |
| Post-edit check | `post-edit-check.sh` reads `file_path` | Not usable as written, because `apply_patch` gives no `file_path`. Rely on the Stop gate |
| Stop output | JSON `decision: "block"` or exit 2 | `Stop` and `SubagentStop` require JSON on success: plain text is invalid, so print nothing or a JSON object. `decision: "block"` keeps Codex going and the reason becomes a new prompt |
| PreToolUse ask | `permissionDecision: "ask"` supported | `"ask"` is not supported. Use deny, allow, or exit 2 |
| PreCompact | Can block compaction | Plain stdout is ignored. `continue: false` stops before compacting |
| Output size | `additionalContext` over 10,000 characters goes to a file | Output over about 2,500 tokens spills to a file. `additionalContextLimit` changes it |
| Hooks that do not fire | Subagent and `@` file content cases, see settings reference | Hosted tools such as WebSearch do not trigger hooks |
| Turning hooks off | `disableAllHooks` setting | `hooks = false` under `[features]` in `config.toml` |

`block-secret-reads.sh` handles `apply_patch` by checking only the `*** Add File:`, `*** Update File:`, and `*** Delete File:` header lines, so a patch that mentions `.env` in prose is not blocked. The patch header format is Codex's apply_patch grammar. The hooks page confirms where the patch text lives but not the header syntax, so run a test patch before relying on it.

## Sources

- https://learn.chatgpt.com/docs/hooks (config locations, events, input, output, exit codes)
- https://learn.chatgpt.com/docs/sandboxing (sandbox modes and approval policies)

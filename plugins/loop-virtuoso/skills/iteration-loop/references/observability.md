# Observability: statusline, telemetry, loop logs, and harden

A loop that runs for an hour is only as trustworthy as what you can see while it runs. This file covers the three views the plugin gives you (the statusline, Claude Code's own OpenTelemetry export, and the loop's state files) and the `harden` command that installs the first two into your settings.

## Contents

- [Statusline](#statusline)
- [Telemetry](#telemetry)
- [Loop cost and events](#loop-cost-and-events)
- [Settings: harden](#settings-harden)
- [Sources](#sources)

## Statusline

`scripts/statusline.sh` is a `statusLine` command. Claude Code pipes a JSON object to it on stdin after each assistant message and shows the one line it prints:

```
my-app | feat/login | Opus | $1.42 | ctx 37% | loop 4/30
```

| Segment | Source | Omitted when |
|---|---|---|
| Directory | basename of `workspace.current_dir`, else `cwd` | both are missing or not a directory |
| Branch | `git symbolic-ref --short HEAD` in that directory | outside a repository, or detached HEAD |
| Model | `model.display_name` | missing |
| Cost | `cost.total_cost_usd`, two decimals | missing |
| Context | `context_window.used_percentage`, rounded down | missing or `null` (early in a session) |
| Loop | `iteration` from `<git root>/.code-virtuoso/loop/state/session.local.json` over `maxIterations` | no session file, or `active` is not `true` |

The loop maximum is read the way the engine reads it: the backlog's `config.maxIterations`, then `loop.maxIterations` from the merged config layers (user, project, project local), then the engine default of 30. Only a Mode A session writes the session file, so a Mode B batch run shows no loop segment; use `/loop-virtuoso:status` or the state files below for that.

The script never fails and never touches the network. Bad input prints an empty line. It runs `git` and `jq` a few times per refresh, which is fast enough for the event-driven updates Claude Code sends.

`cost.total_cost_usd` is Claude Code's client-side estimate at list price. It resets when `/clear` starts a new session, so it is the cost of this session, not of the loop run.

To install it, run `/loop-virtuoso:harden --with statusline` (see below). It copies the script to `statusline.sh` in the code-virtuoso config home (`${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}`), because the plugin's own path changes with every plugin version. Re-run it after a plugin update to refresh the copy. To set it up by hand instead:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/you/.config/code-virtuoso/statusline.sh"
  }
}
```

## Telemetry

Claude Code exports metrics and events through OpenTelemetry once `CLAUDE_CODE_ENABLE_TELEMETRY=1` is set. The variables `harden --with telemetry` uses, and the ones you add to ship data to a collector:

| Variable | Value | Purpose |
|---|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `1` | Turns telemetry on. Required |
| `OTEL_METRICS_EXPORTER` | `console`, `otlp`, `prometheus`, `none` | Where metrics go. harden sets `console` |
| `OTEL_LOGS_EXPORTER` | `console`, `otlp`, `none` | Where events go. harden sets `console` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `grpc`, `http/json`, `http/protobuf` | Needed for every `otlp` exporter; Claude Code has no default |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4317` | Collector address |
| `OTEL_EXPORTER_OTLP_HEADERS` | `Authorization=Bearer <token>` | Collector credentials. A rotating token belongs in `otelHeadersHelper`, not in `env` |
| `OTEL_METRIC_EXPORT_INTERVAL` | milliseconds, default `60000` | Lower it while checking a new setup |

harden picks `console` because it needs no collector and sends nothing off the machine. It is a way to check that telemetry works, not a place to keep it. To keep the data, switch both exporters to `otlp` and add the protocol and endpoint for your collector:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317"
  }
}
```

Pitfalls:

- **Project settings can't turn telemetry on.** Claude Code ignores `CLAUDE_CODE_ENABLE_TELEMETRY`, the exporter selectors and the `OTEL_EXPORTER_OTLP_*` endpoint, header and protocol variables in `.claude/settings.json` and `.claude/settings.local.json`. Only `none` and other off values apply from there. Set them in user settings, managed settings or the shell. This is why harden refuses `--with telemetry` with `--scope project`.
- **Prompt and tool content are off by default.** `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_TOOL_DETAILS` and `OTEL_LOG_TOOL_CONTENT` add them. Leave them off unless the collector is allowed to hold source code and secrets.
- **Subprocesses do not inherit `OTEL_*`.** A tool you run through Bash does not export to Claude Code's collector.
- **Verify it arrives.** Check the backend for the `claude_code.session.count` metric. If nothing shows up, start with `claude --debug-file <path>` and look for `[3P telemetry]` errors.

## Loop cost and events

The loop keeps its own record under `<git root>/.code-virtuoso/loop/state/` (run state, not committed). Both run modes write the same shapes.

| File | Format | What it holds |
|---|---|---|
| `events.jsonl` | one JSON object per line, `{ts, event, ...}` | `run_started`; `step_verdict` with `itemId`, `stepId`, `action` and the gate's `verdict`; `item_verified` and `item_blocked`; `run_stopped` with `reason` |
| `progress.log` | one text line per transition | `run-start`, `iteration=N ... status=running`, `iteration=N ... action=... stalls=... violations=...`, `stop reason=...`, `run-end reason=... iterations=... verified=... pending=... blocked=...` |
| `session.local.json` | JSON, Mode A only | `active`, `iteration`, `currentItemId`, `currentStepId`, stall and violation counts. Removed when the run ends |

Cost:

- **Mode B** adds `cost=<cumulative USD>` to the iteration result and `run-end` lines of `progress.log`, summed from each `claude -p` call's `total_cost_usd`. `config.totalBudgetUsd` stops the run with `total_budget_exceeded` once it is reached.
- **Mode A** records no cost. The session's running cost is the statusline's cost segment (or `/cost`), and `maxIterations` is the budget.

Useful queries:

```bash
state=.code-virtuoso/loop/state
jq -c 'select(.event == "step_verdict") | {itemId, stepId, action}' "$state/events.jsonl"
jq -r 'select(.event == "run_stopped") | .reason' "$state/events.jsonl" | tail -n 1
grep -o 'cost=[0-9.]*' "$state/progress.log" | tail -n 1
```

`/loop-virtuoso:status` prints the tails of both files with the item counts.

## Settings: harden

A plugin cannot set `permissions`, `attribution`, `sandbox`, `statusLine` or `env`. `/loop-virtuoso:harden` runs `scripts/harden.sh`, which proposes them as a diff to your own settings files:

```
harden.sh [--scope user|project] [--apply] [--with statusline,telemetry,sandbox]
```

| Scope | Claude Code settings | code-virtuoso config layer |
|---|---|---|
| `user` (default) | `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json` | `config.json` in the config home |
| `project` | `<git root>/.claude/settings.json` (committed, shared) | `<git root>/.code-virtuoso/config.json` |

What it adds:

| Key | Value |
|---|---|
| `attribution` | `{"commit": "", "pr": ""}` |
| `permissions.deny` | `Read(./.env)`, `Read(./.env.*)`, `Read(!.env.example)`, `Read(./secrets/**)`, `Read(./config/credentials.json)`, `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Edit(./.env)`, `Edit(./.env.*)` |
| `permissions.ask` | `Bash(git push *--force*)`, `Bash(git push -f*)`, `Bash(git push * -f*)`, `Bash(git branch -D *)`, `Bash(git reset --hard *)`, `Bash(composer require *)`, `Bash(composer remove *)`, `Bash(composer update *)` |
| `loop.guard` (config layer) | `{"blockSecrets": true, "protectTests": "ask"}`. `stopGate` is left for you to set per project, next to `ticket-delivery.commands` |
| `sandbox` (`--with sandbox`) | `enabled: true`, `allowUnsandboxedCommands: false`, `filesystem.denyRead: ["~/.ssh", "~/.aws"]`, `network.allowedDomains: ["github.com"]` |
| `env` (`--with telemetry`, user scope only) | `CLAUDE_CODE_ENABLE_TELEMETRY: "1"`, `OTEL_METRICS_EXPORTER` and `OTEL_LOGS_EXPORTER`: `"console"` |
| `statusLine` (`--with statusline`, user scope only) | `{"type": "command", "command": "<config home>/statusline.sh"}`, plus the copy of the script. Skipped with a note when you already have a `statusLine` |

The deny and ask rules follow the `hooks-and-guardrails` skill's `claude-code-settings.md`. A trailing ` *` also matches the bare command, so `Bash(git reset --hard *)` asks for `git reset --hard` too. Only force pushes ask, so an ordinary `git push` runs without a prompt. A `*` matches any text, spaces included, so the three push rules catch `--force`, `--force-with-lease` and `-f` in any argument position: `git push --force`, `git push origin main --force-with-lease`, `git push -f origin main`, `git push origin main -f`. Like every Bash rule they only match a command that starts with `git push`; `git -C . push -f` or a `+branch` refspec gets past them. An earlier harden added `Bash(git push *)`, which asks on every push; merging never removes it, so delete it by hand if you want plain pushes to stop prompting. The deny list leaves out that file's `Bash(curl *)` and `Bash(wget *)`: as user-wide rules they block every download in every project, and they are easy to get around anyway. The sandbox network allowlist is the control that holds. Domains outside the allowlist prompt instead of failing, so add the registries you use (`*.npmjs.org`, `repo.packagist.org`) when the prompts get in the way.

Merge rules:

- Nothing you set is removed or replaced. Objects merge key by key.
- An array gains only the entries it lacks. Your entries keep their order and the new ones follow, which keeps a `!` carve-out after the rule it narrows.
- A value you set that differs from the baseline stays, and harden prints a `note:` line naming it, for example `attribution.commit` or an `attribution: false`.
- A file that is not a JSON object stops the run with an error, so a broken file is never overwritten.

Dry run and apply:

- Without `--apply` it prints a unified diff per file and writes nothing. Files are compared as `jq .` prints them (2-space indent, your key order, new keys last), so a file with other formatting shows only the content changes, and is rewritten in that format when applied.
- `--apply` copies each changed file to `<file>.bak.<YYYYmmdd-HHMMSS>` next to it, then writes the merged result to a temp file in the same directory as the real file (the symlink target when the file is a symlink), checks that it parses, and renames it over the file. The file keeps its mode and the symlink stays a symlink. If any step fails, the original is left as it was and harden exits 1.
- An unchanged file is not touched, so a second apply writes nothing and makes no backup.
- The `/loop-virtuoso:harden` command always runs the dry run first and applies only after you approve the diff.

## Sources

- https://code.claude.com/docs/en/statusline (input fields, `statusLine` setting)
- https://code.claude.com/docs/en/monitoring-usage (telemetry variables, exporters, verification)
- https://code.claude.com/docs/en/settings-reference (`attribution`, `sandbox`, variables ignored in project `env`)
- https://code.claude.com/docs/en/permissions (rule syntax, trailing wildcard, `!` carve-outs)

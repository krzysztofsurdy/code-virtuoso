# Opt-in guard hooks, in full

The loop's own hooks (`guard-protected-paths.sh`, `stop-hook.sh`) only act while a loop session is active. The three guard hooks below cover the rest of the time: an ordinary interactive session in a project that has the plugin installed. Each one is off until the `loop.guard` namespace of the shared config turns it on. With no config, every guard exits 0 without output and has no effect.

## Contents

- [Configuration](#configuration)
- [`guard-secrets.sh`](#guard-secretssh)
- [`guard-tests.sh`](#guard-testssh)
- [`guard-stop.sh`](#guard-stopsh)
- [Coexisting with the loop's own hooks](#coexisting-with-the-loops-own-hooks)
- [Limits](#limits)
- [Settings and audit](#settings-and-audit)

## Configuration

Set the keys in any config layer (user `config.json`, project `.code-virtuoso/config.json`, or `.code-virtuoso/config.local.json`). Layers deep-merge as described in `spec/config-spec.md`. The exception is `stopGate`: see [`guard-stop.sh`](#guard-stopsh).

```json
{
  "loop": {
    "guard": {
      "blockSecrets": true,
      "protectTests": "ask",
      "testGlobs": ["tests/**", "**/*Test.php", "**/*_test.*", "**/*.spec.*", "**/test_*.py"],
      "stopGate": true
    }
  },
  "ticket-delivery": {
    "commands": { "lint": "make lint", "staticAnalysis": "make phpstan", "test": "make test" }
  }
}
```

| Key | Values | Default | Guard |
|---|---|---|---|
| `loop.guard.blockSecrets` | `true` / `false` | off | `hooks/guard-secrets.sh` |
| `loop.guard.protectTests` | `"ask"` / `"deny"` / `false` | off | `hooks/guard-tests.sh` |
| `loop.guard.testGlobs` | array of globs relative to the git root | the five globs shown above | `hooks/guard-tests.sh` |
| `loop.guard.stopGate` | `true` / `false`, user or local layer only | off | `hooks/guard-stop.sh` |
| `ticket-delivery.commands.{lint,staticAnalysis,test}` | shell commands | unset | `hooks/guard-stop.sh` |

Any other value counts as off. Globs use bash `case` matching, where `*` also matches `/`, so `tests/**` and `tests/*` are the same. A glob that starts with `**/` also matches at the git root: `**/*Test.php` covers `FooTest.php` and `src/FooTest.php`.

## `guard-secrets.sh`

`PreToolUse` on `Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit|Bash`. Active in and out of a loop.

- Blocks any of those tools aimed at `.env` and `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa` and the other `id_*` key names, anything under `.ssh/`, `.aws/` or `.gnupg/`, and `.netrc`, `.npmrc`, `.pypirc`.
- Allows template files: `.env.example`, `.env.sample`, `.env.template`, `.env.dist`.
- Checks the path fields of each tool: `file_path` or `notebook_path`, plus `path` and `glob` for Grep and `path` and `pattern` for Glob. A glob character before a secret name still counts as a boundary, so `*.env`, `**/.env` and `{.env,.npmrc}` are blocked.
- Blocks a Bash command that runs bare `printenv` or `env`, which would dump every secret in the environment. `env FOO=1 cmd` is allowed.
- Blocks by exiting 2 with the reason on stderr. Invalid hook input fails closed.

The matching is a copy of the `hooks-and-guardrails` playbook's `block-secret-reads.sh`. A parity test in `tests/test_guard.sh` runs the same inputs through both scripts, so a change to one without the other fails the suite. The playbook's Codex-only `apply_patch` case is not carried over.

## `guard-tests.sh`

`PreToolUse` on `Edit|Write|MultiEdit|NotebookEdit`.

- Matches the target path, made relative to the git root after symlink resolution (`scripts/lib/paths.sh`), against `testGlobs`. A symlink as the last component is followed too, so editing `alias.py -> tests/test_a.py` counts as editing `tests/test_a.py`. `guard-protected-paths.sh` resolves paths the same way.
- When `git config core.ignorecase` is `true` (the default on macOS), the glob match and the `HEAD` check ignore case, so `Tests/Test_A.py` is treated as `tests/test_a.py`.
- Acts only when the file already exists in `HEAD` (`git cat-file -e HEAD:<path>`, or a case-insensitive lookup in `git ls-tree -r HEAD`). New test files are always allowed, so writing tests first is never interrupted.
- Returns `permissionDecision: "ask"` (the user confirms each edit) or `"deny"` (the edit never happens) with a reason that names the file.
- Exits 0 outside a git repository and while a loop session is active.

## `guard-stop.sh`

`Stop` hook. When the session would end with uncommitted changes, it runs `ticket-delivery.commands.lint`, `.staticAnalysis` and `.test` (those that are set, in that order) from the git root.

`stopGate` runs shell commands, so it is read only from the user layer (`$(cv_config_home)/config.json`) and from `.code-virtuoso/config.local.json` when git does not track that file. A `stopGate` in the committed `.code-virtuoso/config.json` is ignored, so cloning a repository never turns the gate on. Once you turn it on, the commands can come from any layer.

- The first failing command blocks the stop with `{"decision":"block","reason":...}`. The reason names the command key, the command, its exit status, and the last 40 lines of output.
- All commands passing prints nothing and the session ends.
- Skipped outside a git repository, on a clean working tree (questions and read-only turns are not slowed down), with no commands configured, and while a loop session is active.
- A red check blocks at most once per stop attempt. When the hook input has `stop_hook_active: true` (Claude Code is already continuing because of a Stop hook), the gate exits 0, so a command that can never pass does not keep the session alive.
- Skipped within 10 seconds of a `run_stopped` event in `.code-virtuoso/loop/state/events.jsonl`, so the gate does not run right after the loop's final turn removed the session file.

## Coexisting with the loop's own hooks

| Situation | Loop hooks | Guard hooks |
|---|---|---|
| No loop session | Exit 0 | Act as configured |
| Loop session active | `guard-protected-paths.sh` denies protected paths, `stop-hook.sh` runs the verify gate | `guard-tests.sh` and `guard-stop.sh` exit 0; `guard-secrets.sh` still acts |

A loop session means `<git root>/.code-virtuoso/loop/state/session.local.json` exists, the same check the loop hooks use. Inside a loop, `protectedPaths` and the verify gate replace `protectTests` and `stopGate`: they are stricter (always deny, plus the git-diff audit) and are tied to the step being graded.

## Limits

- `guard-tests.sh` watches tool calls, not the files. A Bash command that writes a test file (a redirect, `sed -i`, a script) is not caught outside a loop. Inside a loop, the verify gate's git-diff audit (`scripts/lib/verify-gate.sh`, see `write-boundary.md`) catches it whatever tool made the change.
- `guard-secrets.sh` sees command text and tool arguments only. A script that opens `.env` itself, or a path built at run time, passes. Pair it with `permissions.deny` rules and OS sandboxing.
- `guard-stop.sh` trusts the configured commands. A command that exits 0 on failure passes the gate.
- The `run_stopped` check is best effort. The event carries no session id, so a loop that stopped in another session of the same repository in the last 10 seconds also skips the gate. Claude Code runs the Stop hooks in parallel, so the gate can still run once if `stop-hook.sh` removes the session file before the gate checks it and the run ended without a `run_stopped` event (corrupted state).
- `guard-tests.sh` and `guard-stop.sh` exit 0 when `jq` is not installed: they are opt-in, so a missing `jq` turns them off instead of failing every edit and stop. `guard-secrets.sh` still blocks hook input that is not valid JSON.

## Settings and audit

The guard hooks cover what a plugin can enforce. Two commands cover the rest of the setup.

### Harden

`/loop-virtuoso:harden` proposes the settings a plugin cannot ship (`permissions`, `attribution`, `sandbox`, `statusLine`, `env`) plus the `loop.guard` defaults `blockSecrets: true` and `protectTests: "ask"`, as a diff you approve before anything is written. It leaves `stopGate` for you to set per project, next to `ticket-delivery.commands`. Baseline, merge rules and options: `observability.md`, section "Settings: harden".

### Doctor

`/loop-virtuoso:doctor` runs `scripts/doctor.sh [--json]`, a read-only audit of `${CLAUDE_CONFIG_DIR:-~/.claude}` and `~/.claude.json`. It never writes a file and exits 0 whether or not it finds anything (2 on bad usage or an internal error).

| Check id | Severity | Finds |
|---|---|---|
| `duplicate-skill` | medium | One skill name defined more than once across `~/.claude/skills`, `skills/synced/` and the enabled plugins |
| `duplicate-agent` | medium | One agent name defined more than once across `~/.claude/agents` and the enabled plugins |
| `skill-listing` | medium over budget, low above 80% of it | The listing of model-invocable skills (name plus description and `when_to_use`, each capped at 1,536 characters) against the budget |
| `claude-md-size` | medium | A global CLAUDE.md over 200 lines |
| `claude-md-ref` | medium | A `-> use /name` or `` `/name` `` reference in the global CLAUDE.md that resolves to no installed skill or command, or to a skill with `disable-model-invocation: true`. Built-in commands are skipped |
| `mcp-secret` | high | A literal value for a secret-like key (`key`, `token`, `secret`, `passw`, `auth`, `credential`) in an MCP server's `env` or `headers`, top-level or per project. Values that reference `${VAR}` are skipped |
| `settings-attribution`, `settings-deny` | medium | No `attribution` key; no `permissions.deny` rules |
| `settings-ask`, `settings-statusline`, `settings-telemetry` | low | No `permissions.ask` rules; no `statusLine`; `env.CLAUDE_CODE_ENABLE_TELEMETRY` not `1` or `true` |
| `loop-guard` | low | None of `blockSecrets`, `protectTests`, `stopGate` turned on in the user config layer |
| `orphan-cache` | low | A `plugins/cache/<marketplace>/<plugin>/<version>/` directory that `installed_plugins.json` does not reference |
| `invalid-json` | medium | `settings.json`, `installed_plugins.json`, `known_marketplaces.json`, `~/.claude.json` or the user `config.json` that is not valid JSON; the file is skipped |

- **Listing budget.** The budget is 1% of the context window. The script assumes a 200k-token window and about 4 characters per token, so about 8,000 characters. `/context` shows the real figure.
- **Secrets by name only.** An `mcp-secret` finding names the server and the key, never the value, so the report is safe to paste. Rotate the key after moving it to an environment variable.
- **Settings scope.** The `settings-*` checks read the user `settings.json` only; project settings are not audited.
- **`--json` shape.** `{"configDir", "listing": {"skills", "chars", "budget"}, "findings": [{"check", "severity", "what", "where", "fix"}], "summary": {"high", "medium", "low"}}`, with findings sorted high to low.

The `/loop-virtuoso:doctor` command relays the report verbatim, offers `harden` for `settings-*` and `loop-guard` findings, and never deletes skills, agents or caches without asking.

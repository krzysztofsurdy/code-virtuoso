# Opt-in guard hooks, in full

The loop's own hooks (`guard-protected-paths.sh`, `stop-hook.sh`) only act while a loop session is active. The three guard hooks below cover the rest of the time: an ordinary interactive session in a project that has the plugin installed. Each one is off until the `loop.guard` namespace of the shared config turns it on. With no config, every guard exits 0 without output and has no effect.

## Configuration

Set the keys in any config layer (user `config.json`, project `.code-virtuoso/config.json`, or `.code-virtuoso/config.local.json`). Layers deep-merge as described in `spec/config-spec.md`.

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
| `loop.guard.stopGate` | `true` / `false` | off | `hooks/guard-stop.sh` |
| `ticket-delivery.commands.{lint,staticAnalysis,test}` | shell commands | unset | `hooks/guard-stop.sh` |

Any other value counts as off. Globs use bash `case` matching, where `*` also matches `/`, so `tests/**` and `tests/*` are the same. A glob that starts with `**/` also matches at the git root: `**/*Test.php` covers `FooTest.php` and `src/FooTest.php`.

## `guard-secrets.sh`

`PreToolUse` on `Read|Grep|Glob|Edit|Write|MultiEdit|NotebookEdit|Bash`. Active in and out of a loop.

- Blocks any of those tools aimed at `.env` and `.env.*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa` and the other `id_*` key names, anything under `.ssh/`, `.aws/` or `.gnupg/`, and `.netrc`, `.npmrc`, `.pypirc`.
- Allows template files: `.env.example`, `.env.sample`, `.env.template`, `.env.dist`.
- Blocks a Bash command that runs bare `printenv` or `env`, which would dump every secret in the environment. `env FOO=1 cmd` is allowed.
- Blocks by exiting 2 with the reason on stderr. Invalid hook input fails closed.

The matching is a copy of the `hooks-and-guardrails` playbook's `block-secret-reads.sh`. A parity test in `tests/test_guard.sh` runs the same inputs through both scripts, so a change to one without the other fails the suite. The playbook's Codex-only `apply_patch` case is not carried over.

## `guard-tests.sh`

`PreToolUse` on `Edit|Write|MultiEdit|NotebookEdit`.

- Matches the target path, made relative to the git root after symlink resolution (`scripts/lib/paths.sh`), against `testGlobs`.
- Acts only when the file already exists in `HEAD` (`git cat-file -e HEAD:<path>`). New test files are always allowed, so writing tests first is never interrupted.
- Returns `permissionDecision: "ask"` (the user confirms each edit) or `"deny"` (the edit never happens) with a reason that names the file.
- Exits 0 outside a git repository and while a loop session is active.

## `guard-stop.sh`

`Stop` hook. When the session would end with uncommitted changes, it runs `ticket-delivery.commands.lint`, `.staticAnalysis` and `.test` (those that are set, in that order) from the git root.

- The first failing command blocks the stop with `{"decision":"block","reason":...}`. The reason names the command key, the command, its exit status, and the last 40 lines of output.
- All commands passing prints nothing and the session ends.
- Skipped outside a git repository, on a clean working tree (questions and read-only turns are not slowed down), with no commands configured, and while a loop session is active.
- Claude Code caps consecutive Stop hook continuations, so a command that can never pass does not keep the session alive forever.

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

## Settings and audit

The `harden` and `doctor` commands are documented in their own sections.

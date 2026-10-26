---
description: "Merge a guardrail baseline into Claude Code settings: dry-run diff first, apply only after approval"
argument-hint: "[--scope user|project] [--with statusline,telemetry,sandbox]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/harden.sh:*)"]
---

# Harden Claude Code settings

A plugin cannot set `permissions`, `attribution`, `sandbox`, `statusLine` or `env`, so this command proposes them as a diff to the user's own settings file.

1. Run the dry run, passing along the user's arguments but never `--apply`:

   ```
   ${CLAUDE_PLUGIN_ROOT}/scripts/harden.sh $ARGUMENTS
   ```

2. Show the output verbatim: every diff and every `note:` line. Don't summarize the diff or leave lines out. If the script prints an error, relay it and stop.
3. If every file reports `no change`, say the settings already have the baseline and stop.
4. Otherwise ask the user whether to apply exactly this diff. Wait for an explicit yes. Silence, a question back, or approval of something else is not a yes.
5. Only after that yes, re-run the same command with `--apply` added:

   ```
   ${CLAUDE_PLUGIN_ROOT}/scripts/harden.sh $ARGUMENTS --apply
   ```

   Relay its output, including the backup file path it prints for each changed file.

Never run `--apply` without the user's explicit approval of the diff in this conversation, and never edit the settings files yourself.

What the script does:

- **Targets.** `--scope user` (the default) writes `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json` and the user config layer `config.json` in the code-virtuoso config home. `--scope project` writes `<git root>/.claude/settings.json` and `<git root>/.code-virtuoso/config.json`.
- **Baseline.** Empty commit and PR attribution, deny rules for `.env` files and the `~/.ssh` and `~/.aws` keys, ask rules for `git push`, `git branch -D`, `git reset --hard` and `composer require|remove|update`, and the `loop.guard` defaults `blockSecrets: true` and `protectTests: "ask"`.
- **Merge.** It never removes or replaces a value the user set. Arrays gain only the entries they lack. A user value that differs from the baseline stays, with a `note:` line.
- **Options.** `--with sandbox` turns on the sandbox with a minimal network allowlist. `--with telemetry` turns on OpenTelemetry with the console exporter. `--with statusline` installs the loop statusline and sets `statusLine`, unless one is already set. Telemetry and statusline need `--scope user`.

Details: the `iteration-loop` skill's `references/observability.md`, section "Settings: harden".

# loop-virtuoso

A deterministic, backlog-driven autonomous execution loop for Claude Code. Feeds an agent one small backlog step at a time. Gates completion on an exit code and a write-boundary guard, not the agent's claim. Compile a spec into a backlog, point the loop at it; a step flips to `verified` only when a script - not a model - confirms it, and an item is done only when all its steps are.

## Installation

```
/plugin marketplace add krzysztofsurdy/code-virtuoso
/plugin install loop-virtuoso@code-virtuoso
```

The plugin ships from the [code-virtuoso](https://github.com/krzysztofsurdy/code-virtuoso) marketplace.

## Quickstart

1. **Compile a backlog.** Run `/loop-virtuoso:backlog-compiler` (or just describe the work and let Claude reach for the skill) on a PRD, ticket, or freeform feature description. It produces `.code-virtuoso/loop/backlog.json` - each item is one or more steps, each step sized to a single context window, ordered by dependency, with a literal `verifyCommand` per step.
2. **Run the loop.** Either:
   - `/loop-virtuoso:start` - session-supervised (Mode A), inside your current Claude Code session.
   - `scripts/run-batch.sh .code-virtuoso/loop/backlog.json` - unattended batch (Mode B), a fresh process per iteration.
3. **Check progress** with `/loop-virtuoso:status`, and stop early with `/loop-virtuoso:cancel` (backlog state is preserved either way).

## Why an exit code, not a claim

An agent that can write the files grading its own work will sometimes game the check - edit a test, a fixture, or the verify command instead of fixing the code. So the agent never makes the call. A script runs the step's literal `verifyCommand`, checks the exit code, and writes the `status`. The agent is never asked whether it succeeded. (The `iteration-loop` skill covers the mechanics in full.)

## Commands

| Command | What it does |
|---|---|
| `/loop-virtuoso:backlog-compiler [source]` | Compile a PRD, ticket, or feature description into `.code-virtuoso/loop/backlog.json`. Implemented as a skill, not a `commands/*.md` file, but invokable the same way. |
| `/loop-virtuoso:start [backlog]` | Start the session-supervised loop (Mode A) over the backlog (default `<git root>/.code-virtuoso/loop/backlog.json`). Refuses to start on a dirty tree or on the default branch; see "Start-of-run checks". |
| `/loop-virtuoso:status [backlog]` | Report verified/pending/blocked counts (item and step level), iteration vs. max, stall/violation counts, and the progress-log/events tail. Cost is Mode B-only, tracked in its own run output, not shown here. |
| `/loop-virtuoso:cancel` | Remove the session-local file to stop the loop and record a `run_stopped` event with reason `cancelled`; the backlog is left untouched. |
| `/loop-virtuoso:harden [--scope user\|project] [--with statusline,telemetry,sandbox]` | Show a dry-run diff of a guardrail baseline for your Claude Code settings and the `loop.guard` defaults; applies it only after you approve. See "Harden and the statusline". |
| `/loop-virtuoso:doctor` | Read-only audit of your Claude Code setup: duplicate skills and agents, skill listing size, dead CLAUDE.md skill references, plaintext MCP secrets (key names only), settings gaps, orphan plugin caches. |
| `/loop-virtuoso:eval-setup [suite] [-k N] [--arms setup,vanilla] [--max-cost-usd N]` | Measure your setup against vanilla Claude Code on a fixed task suite: pass@k, pass^k, delta, cost. Dry run first; real runs cost money. |
| `/loop-virtuoso:scaffold <devcontainer\|issue-to-pr\|pilot-backlog> [--force]` | Copy a starter template to the git root. Refuses to overwrite; `--force` backs up first. |
| `/loop-virtuoso:help` | Show a short overview of the plugin and its commands. |

## Two modes

| Mode A - session-supervised | Mode B - unattended batch |
|---|---|
| `/loop-virtuoso:start` | `scripts/run-batch.sh path/to/backlog.json` |
| Runs in your current session via a `Stop` hook | Fresh `claude -p` process per iteration |
| Watching it work, brief unattended stretches, backlogs of ~5-15 items | Large backlogs, overnight or CI runs; adds a cumulative cost cap |

Pick Mode A to supervise a modest backlog. Pick Mode B for large or unattended runs. Mode B is not a slash command - it spawns long-running detached processes that don't fit a single tool-call turn.

## Pipelines and participants

Steps are the default unit, and an item is usually a single step. When a backlog benefits from distinct roles owning distinct phases (e.g. implement, then an independent review), a step can name a `participant` defined in an optional `pipelines.json`:

- `agent` - delegate the step to an existing Claude Code subagent. Use the installed scoped name (`agents-virtuoso:reviewer`). A bare name such as `reviewer` is accepted and resolves to `agents-virtuoso:reviewer` when that plugin is installed and ships that agent.
- `persona` - an inline role with its own system prompt and tool list.

A `pipeline` is a named, ordered group of participants that `backlog-compiler` expands into steps; the engine only ever runs participants. (The name avoids a clash with Code Virtuoso agent teams.) With no `pipelines.json`, steps carry no participant and run with no role framing - the simple default. The `backlog-compiler` skill walks through producing both. Note the fidelity difference: Mode B honors a participant with real per-step CLI flags; Mode A can only role-play it within one session (see the `iteration-loop` skill).

`pipelines.json` can live in two places, checked in that order: the project file (`.code-virtuoso/loop/pipelines.json`, committed) first, then your user file (`${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json`). Define your usual roles once in the user file and reference them from any project's backlog; a project entry with the same name overrides the user one. See `references/pipelines-and-participants.md` in the `backlog-compiler` skill.

## Where things are stored

The loop follows the Code Virtuoso storage convention (`spec/config-spec.md` in the repository). Everything lives under `<git root>/.code-virtuoso/`:

| Path | In git | Holds |
|---|---|---|
| `loop/backlog.json` | committed | The plan: items, steps, `verifyCommand`s, config. It never changes during a run. |
| `loop/pipelines.json` | committed | Project participants and pipelines. |
| `loop/archive/<date>-<slug>/` | committed | A finished run: the final `backlog.json` plus a copy of its run state. |
| `loop/state/state.json` | ignored | Each step's `status`, `attempts` and `notes`. |
| `loop/state/session.local.json`, `events.jsonl`, `progress.log` | ignored | The Mode A session, the event log, the progress log. |
| `config.json`, `config.local.json` | committed / ignored | Shared settings; the loop reads the `loop` namespace. |

The loop writes `.code-virtuoso/.gitignore` (`*.local.json` and `loop/state/`) if it is missing, and appends any missing line to an existing one. Snapshots for the tamper check live outside the repository, in `${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso/loop/snapshots/`.

Settings come from the `loop` namespace of the merged config layers (user `config.json`, project `config.json`, project `config.local.json`), for example `maxIterations`, `permissionMode`, `allowedTools`, `allowedPaths` and `protectedPaths`. A key in the backlog's own `config` wins. `protectedPaths` from both places are combined, so a plan can never drop a protection the project set. If `ticket-delivery.commitFormat` is set (placeholders `{ticket}`, `{summary}`, `{item}`, `{step}`), checkpoint commits use it; the ticket id comes from `ticket-delivery.ticketIdPattern` matched against `backlog.branch`. Without a format, or when the format needs a ticket that cannot be found, the message is `loop-virtuoso: ITEM-001/step`. `scripts/branch-name.sh [--ticket ID] <title>` prints a branch name from `ticket-delivery.branchPattern`.

### Migrating from the earlier layout

On `/loop-virtuoso:start` (or `run-batch.sh`), an existing `.delivery-loop/` is moved to `.code-virtuoso/loop/`: the backlog is split into the plan and `state/state.json`, `teams.json` becomes `pipelines.json` (key `teams` renamed `pipelines`), logs move to `state/`, and `archive/` moves over. The command prints what moved. If your `.git/info/exclude` has a `.delivery-loop` line, remove it: the plan and archive are meant to be committed. A global `~/.claude/loop-virtuoso/teams.json` is copied to the user pipelines path when that file does not exist yet; the old file stays and can be deleted. After the migration nothing reads the old paths. If both layouts hold a backlog, the loop refuses to start until you remove one.

## Visibility

Every state transition is recorded by scripts, never the model:

- `.code-virtuoso/loop/state/progress.log` - human-readable, written the same way by both modes: a `run-start` line, a line when each iteration starts and when it ends, then `stop` and `run-end` lines. Mode B adds the running cost to the iteration and `run-end` lines.
- `.code-virtuoso/loop/state/events.jsonl` - machine-readable, one JSON object per transition (step verdict, item verified/blocked, loop stopped). `tail -f` or `jq` it for full detail.

## Start-of-run checks

Both modes run the same checks before the first iteration, and refuse to start if any fails:

- The backlog validates (`scripts/validate-backlog.sh`). This is a hard gate in both modes.
- The backlog lives at `<git root>/.code-virtuoso/loop/backlog.json`. The session file is always written to `<git root>/.code-virtuoso/loop/state/session.local.json`, so the hooks find it from any subdirectory.
- `backlog.branch` is set and is not the repository's default branch (`main`, `master`, or the branch `origin/HEAD` points at).
- The working tree has no modified or untracked files outside `.code-virtuoso/`. The loop commits checkpoints, so commit or stash your own work first.
- The current branch is `backlog.branch`. If it is not, the loop switches to that branch (or creates it from the current commit), which is only possible because the tree is clean.

Mode A also needs a Claude Code session id so the Stop hook only drives the session that started the loop.

## Archiving a run

Starting a run never moves its backlog (apart from the one-time migration above). The `backlog-compiler` skill runs `scripts/archive-run.sh <backlog> <new-branch>` before it writes a new backlog. That archives the old run into `.code-virtuoso/loop/archive/<date>-<branch>/` when the run finished (no pending items) or when the new branch differs from the old one. The plan (`backlog.json`) moves there, together with a copy of the run state (`state.json`, `progress.log`, `events.jsonl`, which are cleared from `loop/state/`); `pipelines.json` is copied, so your participants stay available for the next run. The archive is committed, so commit it with the branch. A run with pending items and an unchanged branch is left alone. You can also run the script by hand.

## Safety defaults

- **`acceptEdits` + a scoped `allowedTools` allowlist of specific binaries - not `bypassPermissions`, and not a bare interpreter.** Auto-approve edits; name exactly which commands the worker may run, each one a specific tool or subcommand (`vendor/bin/phpunit`, `npm run test`), never a general-purpose interpreter (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`). That distinction is the actual boundary, not the list's length - see `allowed-tools-by-stack.md`'s "Why no bare interpreters" for why one interpreter grant undoes everything below.
- **Write-boundary guard, three parts.** A content-tamper check compares `backlog.json`, `pipelines.json`, `config.json` and `config.local.json` under `.code-virtuoso/` against a snapshot taken before each step (a file that did not exist then must not appear), restoring or removing it and flagging any change - including a rewritten `verifyCommand` - before anything else runs; the snapshot lives outside the project directory, unreachable by the worker's Edit/Write tools. A `PreToolUse` hook denies `Edit`, `Write`, and `NotebookEdit` to `config.protectedPaths` before the edit happens. A post-iteration `git diff` audit checks every changed file against `protectedPaths` regardless of which tool changed it. A violation is counted once: the offending paths are reverted to their state at the start of the iteration (a new offending file is deleted), so the next iteration does not trip over the same change. None of this defends against a worker with a bare interpreter in its `allowedTools` - Bash isn't sandboxed to the project directory the way Edit/Write are, so arbitrary code execution reaches anywhere the OS user can, snapshot location included. A curated, interpreter-free allowlist is what makes these three parts a real guarantee rather than a convention; broadening past that requires running the worker in an OS-level sandbox instead (see `permission-modes.md`).
- **Checkpoint commits never take more than the loop may own.** After a passing or failing iteration the loop commits tracked changes plus new files that are allowed: not secret-like (`.env`, `.env.*`, `*.pem`, `*.key`, and similar) and, if `config.allowedPaths` is set, matching one of its globs. A new file that is outside `allowedPaths` or secret-like is a violation. Commit hooks always run; the loop never uses `--no-verify`, so pre-commit secret scanners still apply. Because the loop only starts from a clean tree, nothing you had lying around can be swept into a checkpoint.
- **Six stop reasons, plus two Mode-B-only additions** - the loop ends via exactly one, written to `.code-virtuoso/loop/state/progress.log`:
  - `complete` - no pending items remain and none are blocked; every item reached `verified`.
  - `blocked_out` - no pending items remain, but at least one is `blocked` (it exhausted `maxAttemptsPerItem` without its `verifyCommand` passing).
  - `max_iterations` - the iteration count hit `config.maxIterations`; backlog state is preserved, rerun to continue.
  - `stalled` - `maxStallIterations` consecutive iterations produced an empty git diff (no changes at all); preserved, investigate why.
  - `violation_limit` - `maxViolations` cumulative protected-path violations were recorded by the git-diff audit; preserved, tighten `protectedPaths`/`allowedTools`.
  - `corrupted` - the session-state file or backlog failed to parse; the broken state file is removed and the loop stops rather than guessing.
  - `total_budget_exceeded` *(Mode B only)* - cumulative `total_cost_usd` across the run hit `config.totalBudgetUsd`. This is reported even on a Claude subscription (it's a notional figure, not a separate charge), so the gate still works there - it just isn't the thing that actually limits a subscription plan.
  - `invocation_failed` *(Mode B only)* - a `claude -p` call returned no usable result. The most common real-world cause under a subscription is the plan's own usage/rate limit, which doesn't show up as a cost at all; rerun once the window resets.

`/loop-virtuoso:cancel` is not one of these: it records `run_stopped` with reason `cancelled` and removes the session file.

For the authoritative detail on stop reasons, the write-boundary guard, and the backlog schema, see the `iteration-loop` and `backlog-compiler` skills shipped with this plugin.

## Guard hooks (opt-in)

The loop's own hooks act only while a loop runs. Three more hooks cover ordinary sessions. Each is off until you turn it on in the `loop` namespace of a config layer, so installing or updating the plugin changes nothing by itself. `stopGate` runs shell commands, so it is read only from the user layer and an untracked `.code-virtuoso/config.local.json`, never from a committed project config:

```json
{ "loop": { "guard": { "blockSecrets": true, "protectTests": "ask", "stopGate": true } } }
```

| Key | Hook | Effect |
|---|---|---|
| `blockSecrets: true` | `guard-secrets.sh` (`PreToolUse`) | Blocks Read, Grep, Glob, Edit, Write, MultiEdit, NotebookEdit and Bash calls aimed at `.env` files, private keys, `.ssh/`, `.aws/`, `.gnupg/` and similar, and bare `printenv` or `env`. Template files such as `.env.example` stay readable. Also acts inside a loop. |
| `protectTests: "ask"` or `"deny"` | `guard-tests.sh` (`PreToolUse`) | Asks before, or denies, an edit to a file that matches `testGlobs` and already exists in `HEAD`. New test files are always allowed, so test-first work is never interrupted. |
| `testGlobs` | `guard-tests.sh` | Which files count as tests. Default: `tests/**`, `**/*Test.php`, `**/*_test.*`, `**/*.spec.*`, `**/test_*.py`. |
| `stopGate: true` | `guard-stop.sh` (`Stop`) | With uncommitted changes, runs `ticket-delivery.commands.lint`, `.staticAnalysis` and `.test` (those that are set) before the session ends, and blocks the stop with the last 40 lines of the first failing command. |

Inside a loop, `protectedPaths` and the verify gate take over from `protectTests` and `stopGate`, which then do nothing. The test guard sees tool calls only: a Bash command that rewrites a test file is caught by the loop's git-diff audit, not outside a loop. Full detail: `references/guardrails.md` in the `iteration-loop` skill.

## Harden and the statusline

A plugin cannot set `permissions`, `attribution`, `sandbox`, `statusLine` or `env`. `/loop-virtuoso:harden` runs `scripts/harden.sh`, which proposes them as a unified diff to your own settings and changes nothing until you approve:

- **Baseline:** empty commit and PR attribution, `permissions.deny` for `.env` files, `~/.ssh` and `~/.aws`, `permissions.ask` for force pushes, `git branch -D`, `git reset --hard` and `composer require|remove|update`, and `loop.guard` with `blockSecrets: true` and `protectTests: "ask"`.
- **Options:** `--with sandbox` (sandbox on, minimal network allowlist), `--with telemetry` (OpenTelemetry with the console exporter), `--with statusline` (installs the loop statusline). Telemetry and the statusline need `--scope user`.
- **Merge:** nothing you set is removed or replaced, arrays gain only the entries they lack, each changed file gets a `<file>.bak.<timestamp>` backup, and a second apply writes nothing.

`--scope user` (the default) writes `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json` and your user `config.json`; `--scope project` writes `<git root>/.claude/settings.json` and `.code-virtuoso/config.json`.

The statusline (`scripts/statusline.sh`) prints directory, branch, model, session cost, context use and, while a loop runs, `loop i/max`. `harden --with statusline` copies it into the code-virtuoso config home, so the `statusLine` path survives plugin updates. Detail: `references/observability.md` in the `iteration-loop` skill.

## Doctor

`/loop-virtuoso:doctor` runs `scripts/doctor.sh`, a read-only audit of `${CLAUDE_CONFIG_DIR:-~/.claude}` and `~/.claude.json`. It writes nothing. Each finding has a check id, a severity (high, medium, low), where it is, and the fix:

- duplicate skill and agent names across your own files, synced skills and enabled plugins;
- the skill listing size against an estimated budget of about 8,000 characters (1% of a 200k-token context);
- a global CLAUDE.md over 200 lines, and `/name` references to skills that are missing or have `disable-model-invocation: true`;
- plaintext secrets in MCP server `env` and `headers`, reported by server and key name only, never the value;
- settings gaps (attribution, deny and ask rules, statusline, telemetry, no `loop.guard` hook on) and plugin cache directories that nothing references.

`doctor.sh --json` prints the same report as JSON. Settings findings point to `/loop-virtuoso:harden`.

## Measuring your setup

`/loop-virtuoso:eval-setup` runs `scripts/eval-setup.sh`, which answers whether your CLAUDE.md, skills, plugins, hooks and MCP servers help on your own work. It runs every task in `.code-virtuoso/loop/evals/suite.json` k times in two arms: **setup** (a plain `claude -p`) and **vanilla** (the same call with `--safe-mode`, or `loop.evalSetup.vanillaArgs` when set). Each trial runs in a throwaway git worktree and is graded by the task's literal `verifyCommand`.

The report gives pass@k, pass^k and cost per task and arm, and the setup minus vanilla delta. Each run appends a line to `.code-virtuoso/loop/evals/history.jsonl`, so you can compare runs over time. A real run makes tasks x arms x k paid calls, so the command always does a `--dry-run` first and asks before running; `--max-cost-usd` caps the spend. How to pick tasks and read the results: `references/setup-evals.md` in the `iteration-loop` skill.

## Templates

`/loop-virtuoso:scaffold <kind>` copies a starter template to the git root:

| Kind | Writes |
|---|---|
| `devcontainer` | `.devcontainer/` with `devcontainer.json`, `Dockerfile` and `init-firewall.sh`: a non-root user, a default-deny egress firewall with an allowlist, no host credential mounts |
| `issue-to-pr` | `.github/workflows/claude-issue-to-pr.yml`: a labelled issue or an `@claude` mention becomes a draft pull request from a `claude/issue-<n>` branch |
| `pilot-backlog` | `.code-virtuoso/loop/backlog.json`: two low-risk items for a first `/loop-virtuoso:start` run |

It refuses to overwrite an existing file and then writes nothing. `--force` first copies each existing file to `<file>.bak.<timestamp>`. It never replaces the backlog while a loop is active.

## Fits with other Code Virtuoso skills

| Situation | Skill |
|---|---|
| You have a ticket to turn into a loop-ready backlog | `ticket-writer` produces the ticket; give it to `backlog-compiler` |
| A run ended with `complete` | `finishing-branch` to verify, commit the plan and archive, and open the pull request |
| You need branch and commit conventions | Save them once in `.code-virtuoso/config.json` (`ticket-delivery` namespace); the loop reads them |

## Self-review

This design went through five rounds of independent adversarial review before shipping, including a critical finding (a worker could rewrite its own `verifyCommand`) and its own fix's own bypass, both closed. See [`REVIEW.md`](REVIEW.md) for the honest account - what was found, what's fixed, and the two remaining trade-offs stated plainly rather than hidden.

## License

MIT

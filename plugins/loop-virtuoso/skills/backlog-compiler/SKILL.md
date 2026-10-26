---
name: backlog-compiler
description: Converts a PRD, ticket, or feature description into a .code-virtuoso/loop/backlog.json plan sized and ordered for autonomous loop execution. Use when preparing work for the iteration-loop skill, turning a written ticket into a loop-ready backlog, or when asked to turn a spec into a backlog.
user-invocable: true
argument-hint: "[path to PRD/ticket, or paste a description]"
---

# Backlog Compiler

Converts an existing spec (PRD, ticket, or freeform feature description) into `.code-virtuoso/loop/backlog.json` - the committed plan that `iteration-loop` executes one step at a time, with completion gated by an objective `verifyCommand`, never by self-report. Each item is a sequence of steps; a simple item is a single step.

## Step 0: Reuse saved project settings

Before asking the user anything, read the merged Code Virtuoso config (`spec/config-spec.md`): the user file (`$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json`), then `<git root>/.code-virtuoso/config.json`, then `<git root>/.code-virtuoso/config.local.json`. Later files win; objects merge, arrays and scalars replace. Missing files are normal.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
home="${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}"
files=(); for f in "$home/config.json" "$root/.code-virtuoso/config.json" "$root/.code-virtuoso/config.local.json"; do [ -f "$f" ] && files+=("$f"); done
[ ${#files[@]} -gt 0 ] && jq -s 'reduce .[] as $x ({}; . * $x)' "${files[@]}" || echo '{}'
```

Two namespaces matter here:

- `ticket-delivery`: `commands.test` and `commands.staticAnalysis` answer the test and static analysis questions below; `branchPattern`, `ticketIdPattern` and `mainBranch` shape the branch (Step 1). The legacy ticket-delivery supplement file is not read here; if the namespace is empty, save the values in the config file once.
- `loop`: defaults for `config` in Step 6 (`maxIterations`, `permissionMode`, `allowedTools`, `allowedPaths`, `protectedPaths`, and the other limits). Seed the backlog's `config` from these values instead of the table in Step 6. Never save a credential there.

For each answer the config does not give, ask the user directly:
1. What command runs the test suite for a single file/class (the answer becomes the basis for each step's `verifyCommand`)?
2. What command runs static analysis / type-checking, if any (append to `verifyCommand` with `&&`)?
3. Which directories or files must never be modified by the loop (test directories, CI config, fixtures) - these become `config.protectedPaths`?
4. Primary stack, to pick a sensible `config.allowedTools` base (see Step 6).

Offer to save answers that apply to the whole project (test command, protected paths) to `.code-virtuoso/config.json` so the next backlog does not ask again. Ask first, and write only the keys you own.

## Step 1: Archive a previous run if present

If `.code-virtuoso/loop/backlog.json` already exists:
1. Read its `branch` field.
2. Derive the new feature's branch from the current request. Run `scripts/branch-name.sh [--ticket <id>] "<title>"`: it applies `ticket-delivery.branchPattern` when the project set one (default `feat/{slug}`), and asks for a ticket id when the pattern needs one.
3. If they differ, or every item is already done, and `.code-virtuoso/loop/state/progress.log` has content beyond a header, archive the old run by running `scripts/archive-run.sh .code-virtuoso/loop/backlog.json <new-branch>` (do not copy by hand). It moves `backlog.json` and a copy of the run state (`state.json`, `progress.log`, `events.jsonl`) into `.code-virtuoso/loop/archive/YYYY-MM-DD-<old-slug>/`, clears `loop/state/`, and copies `pipelines.json` there, leaving the original in place so your participants carry over. Then start fresh. The archive is committed with the branch.
4. If the branch matches and items are still pending, you are continuing the same run: extend `items`, do not overwrite ones already `verified` or `blocked` (their status lives in `loop/state/state.json`, keyed by item and step id, so keep existing ids stable). The script leaves such a run alone.

Starting the loop never archives anything, so this step is the only place a finished run gets archived. Never write run state (`status`, `attempts`, `notes`) into the backlog: it is the plan, and it must not change during a run.

## Step 2: Size every item to one context window

**The single rule that matters most.** Each step must be small enough that a fresh agent invocation with no memory of prior iterations can read it, implement it, and pass its `verifyCommand` in one pass. A simple item is a single step, so for the common case this is the same as sizing the item.

Right-sized:
- Add one database column and its migration
- Add one UI component to an existing page
- Add or change one service method and its direct caller
- Add one filter/endpoint to an existing list/resource

Too big - split these:
- "Build the dashboard" → schema item, query/service item, one item per UI region
- "Add authentication" → schema item, middleware item, login UI item, session-handling item
- "Refactor the API" → one item per endpoint or per pattern, not one item for "the API"

Rule of thumb: if the item can't be described in 2-3 sentences, it's too big.

## Step 3: Order by dependency, not by document order

Earlier items must never depend on later ones. Canonical order: schema/migrations → backend services/endpoints → UI that consumes them → aggregating/summary views. Assign `priority` accordingly (lower number = earlier); `iteration-loop` always works the lowest-priority item that isn't fully verified, advancing through its steps in array order.

## Step 4: Express each item as one or more steps, each with a literal verifyCommand

An item is a sequence of `steps`. Each step is what one fresh agent invocation works in a single pass; the item is `verified` only when every step is. Most items are a single step - split into multiple steps only when the work has genuinely distinct phases worth handing to different participants (e.g. `implement` then `review`, or `implement` then `write-tests`). Don't over-split; one step is the default.

Item-level fields stay as before: `id`, `title`, `description`, `acceptanceCriteria`, `priority`. The `verifyCommand` and execution state live on each step:

```json
{
  "id": "implement",
  "participant": "backend-dev",
  "instructions": "What this step must do, in 2-3 sentences.",
  "verifyCommand": "vendor/bin/phpunit --filter=TaskStatusMigrationTest && vendor/bin/phpstan analyse",
}
```

`participant` is optional - omit it for a plain step with no role framing (see Step 5). Steps carry no `status`, `attempts` or `notes`: the loop keeps those in `loop/state/state.json`. Step `id`s are short slugs (`implement`, `review`), unique within their item.

Every acceptance criterion must be something a command can check, not something a model has to judge:

Good: "Add `status` column to `tasks`, default `'pending'`", "Migration runs cleanly", "Filter dropdown options are All/Active/Done"
Bad: "Works correctly", "Good UX", "Handles edge cases"

A step's `verifyCommand` is a literal, runnable shell command (chain with `&&` for multiple checks - test run first, then static analysis/typecheck). It is the *only* thing that can flip a step to `verified` - never the agent's own claim. If you can't write a command that checks a criterion, rewrite the criterion until you can.

Stack defaults if the user didn't specify one explicitly:
- PHP/Symfony: `vendor/bin/phpunit --filter=<Test> && vendor/bin/phpstan analyse`
- Node/TypeScript: `npx vitest run <pattern> && npx tsc --noEmit`
- Python: `pytest <path>::<test> && mypy <path>`

## Step 5: Assign participants and pipelines (optional)

A step can name a `participant` - a reusable role defined in the project file `.code-virtuoso/loop/pipelines.json` or in your user file (`${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json`). Before generating role-based steps, check whether either file exists. If neither does and the user wants roles, help them create a small one (a couple of participants is plenty - don't model an org chart).

A participant is one of two kinds:
- `agent` - delegate the step to an existing Claude Code subagent, by its installed scoped name: `{"kind": "agent", "agent": "agents-virtuoso:backend-dev"}`. A bare name (`backend-dev`) also works and resolves to `agents-virtuoso:backend-dev` when that agent is installed.
- `persona` - an inline custom role: `{"kind": "persona", "systemPrompt": "...", "allowedTools": [...]}`.

A `pipeline` is an ordered group of participant names, used only as a compile-time template you turn into an item's steps. The engine itself only ever runs participants; "pipeline" is not a runtime concept. (The word avoids a clash with Code Virtuoso agent teams.)

If no pipelines file exists, steps simply carry no `participant` and run with no role framing - that is the valid default. Full schema and worked examples: `references/pipelines-and-participants.md`.

## Step 6: Generate `config` with safe, realistic defaults

Start from the `loop` namespace of the merged config (Step 0) and fill what it lacks from this table. Every key the backlog sets wins over the shared config, except `protectedPaths`, which the loop combines with the shared list.

```json
{
  "maxIterations": 30,
  "maxAttemptsPerItem": 3,
  "maxStallIterations": 3,
  "maxViolations": 3,
  "protectedPaths": ["tests/**", "spec/**", "phpunit.xml*", ".github/workflows/**"],
  "permissionMode": "acceptEdits",
  "allowedTools": ["Read", "Edit", "Write", "Glob", "Grep",
    "Bash(composer install*)", "Bash(composer dump-autoload*)", "Bash(vendor/bin/* *)", "Bash(bin/console *)",
    "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(git add *)", "Bash(git commit *)"],
  "totalBudgetUsd": null,
  "perIterationBudgetUsd": null,
  "perIterationMaxTurns": 40
}
```

Adjust `protectedPaths` to the project's real test/fixture/CI locations from Step 0. `allowedPaths` is optional (for example `["src/**", "config/**"]`): when set, a new file outside those globs is a violation, and new files are only ever committed if they match. Without it any new, non-secret file outside `protectedPaths` is allowed. Secret-like names (`.env`, `*.pem`, `*.key`, and similar) are never committed as new files either way. Adjust `allowedTools` to the project's real stack - see `references/allowed-tools-by-stack.md` for Node and Python base sets. Never add a bare interpreter pattern (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) - that reference explains why one of those defeats the tamper-detection guarantee entirely, not just widens the surface a little.

**Do not weaken this by reaching for `bypassPermissions`.** The protected-paths guard (enforced by `iteration-loop`'s hooks and gate) and a narrow `allowedTools` list work together: the guard watches what changes, but it can only be trusted while the worker's Bash access is limited to specific binaries, because Bash is not sandboxed to the project directory. A broad allowlist, and above all a bare interpreter, lets the worker write around the guard. Only suggest `bypassPermissions` if the project genuinely needs shell access beyond what any reasonable allowlist can enumerate (e.g. Docker, package installs requiring network), and even then only with the sandboxing note in `references/permission-modes.md`.

## Step 7: Validate before saving

Run `scripts/validate-backlog.sh path/to/backlog.json` (or apply its checks by hand if the script is unavailable):
- [ ] Previous run archived if finished or the branch changed
- [ ] No `status`, `attempts` or `notes` in the plan (those are run state)
- [ ] Every step completable in one context window
- [ ] Items ordered by dependency, no forward references; steps within an item ordered by phase
- [ ] Every step has a non-empty, literal `verifyCommand`
- [ ] Acceptance criteria are objectively checkable, not vague
- [ ] No duplicate item `id` values; ids are sequential `ITEM-001`, `ITEM-002`, ...; step `id`s unique within their item
- [ ] Any `participant` named on a step exists in the project or user `pipelines.json`
- [ ] `config.protectedPaths` covers the project's real test/CI locations

## Output

Write the result to `.code-virtuoso/loop/backlog.json` (indented JSON, one trailing newline; create `.code-virtuoso/.gitignore` with `*.local.json` and `loop/state/` if it is missing). Set `branch` to the feature branch the work belongs on: the loop switches to it (creating it if needed) and refuses to run on `main`, `master`, or the repository's default branch. Tell the user the item count (and step count, if any items are multi-step), the `verifyCommand` pattern, and that `/loop-virtuoso:start` (session-supervised) or `scripts/run-batch.sh` (unattended) is next. The backlog is meant to be committed; the run state is not.

See `references/example-conversion.md` for a full worked example.

## Integration with other skills

| Situation | Skill |
|---|---|
| The work starts as a rough idea that needs a well-formed ticket first | `ticket-writer`, then feed the ticket to this skill |
| The loop ended with `complete` | `finishing-branch` to commit the plan and archive and open the pull request |
| You need to run or explain the loop | `iteration-loop` |

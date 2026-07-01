---
name: backlog-compiler
description: Converts a PRD, ticket, or feature description into a .delivery-loop/backlog.json file sized and ordered for autonomous loop execution. Use when preparing work for the iteration-loop skill, or when asked to turn a spec into a loop-ready backlog.
user-invocable: true
argument-hint: "[path to PRD/ticket, or paste a description]"
---

# Backlog Compiler

Converts an existing spec (PRD, ticket, or freeform feature description) into `.delivery-loop/backlog.json` — the structured backlog that `iteration-loop` executes one step at a time, with completion gated by an objective `verifyCommand`, never by self-report. Each item is a sequence of steps; a simple item is a single step.

## Step 0: Reuse known project context

Before asking the user anything, check whether the project already has a ticket-workflow supplement file (commonly `.supplement.md` next to a ticket-delivery-style skill) and read it if present. It may already answer the testing framework, TDD style, CI hooks to skip, and architecture questions this skill needs — reuse those answers instead of re-asking.

If nothing like that exists, ask directly:
1. What command runs the test suite for a single file/class (the answer becomes the basis for each step's `verifyCommand`)?
2. What command runs static analysis / type-checking, if any (append to `verifyCommand` with `&&`)?
3. Which directories or files must never be modified by the loop (test directories, CI config, fixtures) — these become `config.protectedPaths`?
4. Primary stack, to pick a sensible `config.allowedTools` base (see Step 6).

## Step 1: Archive a previous run if present

If `.delivery-loop/backlog.json` already exists:
1. Read its `branch` field.
2. Derive the new feature's branch slug from the current request.
3. If they differ and `.delivery-loop/progress.log` has content beyond a header, archive the old run: copy `backlog.json` and `progress.log` to `.delivery-loop/archive/YYYY-MM-DD-<old-slug>/`, then start fresh. (`scripts/archive-run.sh` does this mechanically — invoke it rather than copying by hand.)
4. If they match, you are continuing the same run — extend `items`, do not overwrite ones already `verified` or `blocked`.

## Step 2: Size every item to one context window

**The single rule that matters most.** Each step must be small enough that a fresh agent invocation with no memory of prior iterations can read it, implement it, and pass its `verifyCommand` in one pass. A simple item is a single step, so for the common case this is the same as sizing the item.

Right-sized:
- Add one database column and its migration
- Add one UI component to an existing page
- Add or change one service method and its direct caller
- Add one filter/endpoint to an existing list/resource

Too big — split these:
- "Build the dashboard" → schema item, query/service item, one item per UI region
- "Add authentication" → schema item, middleware item, login UI item, session-handling item
- "Refactor the API" → one item per endpoint or per pattern, not one item for "the API"

Rule of thumb: if the item can't be described in 2-3 sentences, it's too big.

## Step 3: Order by dependency, not by document order

Earlier items must never depend on later ones. Canonical order: schema/migrations → backend services/endpoints → UI that consumes them → aggregating/summary views. Assign `priority` accordingly (lower number = earlier); `iteration-loop` always works the lowest-priority item that isn't fully verified, advancing through its steps in array order.

## Step 4: Express each item as one or more steps, each with a literal verifyCommand

An item is a sequence of `steps`. Each step is what one fresh agent invocation works in a single pass; the item is `verified` only when every step is. Most items are a single step — split into multiple steps only when the work has genuinely distinct phases worth handing to different participants (e.g. `implement` then `review`, or `implement` then `write-tests`). Don't over-split; one step is the default.

Item-level fields stay as before: `id`, `title`, `description`, `acceptanceCriteria`, `priority`. The `verifyCommand` and execution state live on each step:

```json
{
  "id": "implement",
  "participant": "backend-dev",
  "instructions": "What this step must do, in 2-3 sentences.",
  "verifyCommand": "vendor/bin/phpunit --filter=TaskStatusMigrationTest && vendor/bin/phpstan analyse",
  "status": "pending",
  "attempts": 0,
  "notes": ""
}
```

`participant` is optional — omit it for a plain step with no role framing (see Step 5). `status`/`attempts`/`notes` always start as `"pending"`/`0`/`""`. Step `id`s are short slugs (`implement`, `review`), unique within their item.

Every acceptance criterion must be something a command can check, not something a model has to judge:

Good: "Add `status` column to `tasks`, default `'pending'`", "Migration runs cleanly", "Filter dropdown options are All/Active/Done"
Bad: "Works correctly", "Good UX", "Handles edge cases"

A step's `verifyCommand` is a literal, runnable shell command (chain with `&&` for multiple checks — test run first, then static analysis/typecheck). It is the *only* thing that can flip a step to `verified` — never the agent's own claim. If you can't write a command that checks a criterion, rewrite the criterion until you can.

Stack defaults if the user didn't specify one explicitly:
- PHP/Symfony: `vendor/bin/phpunit --filter=<Test> && vendor/bin/phpstan analyse`
- Node/TypeScript: `npx vitest run <pattern> && npx tsc --noEmit`
- Python: `pytest <path>::<test> && mypy <path>`

## Step 5: Assign participants and teams (optional)

A step can name a `participant` — a reusable role defined in `.delivery-loop/teams.json`. Before generating role-based steps, check whether that file exists. If it doesn't and the user wants roles, help them create a small one (a couple of participants is plenty — don't model an org chart).

A participant is one of two kinds:
- `agent` — delegate the step to an existing Claude Code subagent: `{"kind": "agent", "agent": "backend-dev"}`.
- `persona` — an inline custom role: `{"kind": "persona", "systemPrompt": "...", "allowedTools": [...]}`.

A `team` is an ordered group of participant names, used only as a compile-time template you turn into an item's steps. The engine itself only ever runs participants; "team" is not a runtime concept.

If `.delivery-loop/teams.json` is absent, steps simply carry no `participant` and run with no role framing — that is the valid default. Full schema and worked examples: `references/teams-and-participants.md`.

## Step 6: Generate `config` with safe, realistic defaults

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

Adjust `protectedPaths` to the project's real test/fixture/CI locations from Step 0. Adjust `allowedTools` to the project's real stack — see `references/allowed-tools-by-stack.md` for Node and Python base sets. Never add a bare interpreter pattern (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) — that reference explains why one of those defeats the tamper-detection guarantee entirely, not just widens the surface a little.

**Do not weaken this by reaching for `bypassPermissions`.** The protected-paths guard (enforced by `iteration-loop`'s hooks), not a narrow allowlist, is what actually keeps the loop from touching its own grading files — a broad-but-still-bounded Bash allowlist is safe under that guard. Only suggest `bypassPermissions` if the project genuinely needs shell access beyond what any reasonable allowlist can enumerate (e.g. Docker, package installs requiring network), and even then only with the sandboxing note in `references/permission-modes.md`.

## Step 7: Validate before saving

Run `scripts/validate-backlog.sh path/to/backlog.json` (or apply its checks by hand if the script is unavailable):
- [ ] Previous run archived if branch changed
- [ ] Every step completable in one context window
- [ ] Items ordered by dependency, no forward references; steps within an item ordered by phase
- [ ] Every step has a non-empty, literal `verifyCommand`
- [ ] Acceptance criteria are objectively checkable, not vague
- [ ] No duplicate item `id` values; ids are sequential `ITEM-001`, `ITEM-002`, ...; step `id`s unique within their item
- [ ] Any `participant` named on a step exists in `.delivery-loop/teams.json`
- [ ] `config.protectedPaths` covers the project's real test/CI locations

## Output

Write the result to `.delivery-loop/backlog.json`. Tell the user the item count (and step count, if any items are multi-step), the `verifyCommand` pattern, and that `/loop-virtuoso:start` (session-supervised) or `scripts/run-batch.sh` (unattended) is next.

See `references/example-conversion.md` for a full worked example.

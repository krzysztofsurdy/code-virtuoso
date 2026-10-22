# Placement guide

Where each kind of instruction belongs, how each tool scopes it, and how to move content that sits in the wrong place.

## Contents

- [Decision flow](#decision-flow)
- [Per-tool files and scoping](#per-tool-files-and-scoping)
- [What belongs in the always-on file](#what-belongs-in-the-always-on-file)
- [What to cut](#what-to-cut)
- [Before and after](#before-and-after)
- [One file for several tools](#one-file-for-several-tools)
- [Migration steps](#migration-steps)
- [Skill descriptions as context cost](#skill-descriptions-as-context-cost)

## Decision flow

Ask these in order and stop at the first yes.

1. Can the agent find this by reading the code, running a command or reading a config file? Do not write it down.
2. Must it hold every single time, with no exceptions? Enforce it with a hook, linter, formatter, type check or test. Add one line of text only if the agent needs to know why a check fails.
3. Does the agent need it on nearly every task in this repository? Put it in the always-on file, in one or two lines.
4. Does it apply to one language, directory or file type? Use a path-scoped rule or a nested instruction file.
5. Is it a repeatable workflow with steps the agent should run on request or on a clear trigger? Make it a skill.
6. Is it long reference material (architecture, API detail, history, runbooks)? Put it in `docs/` and add a one-line pointer in the always-on file saying when to read it.
7. Is it a one-time fact for this task? Say it in the prompt.

## Per-tool files and scoping

| Tool | Always-on | Path-scoped or nested | Notes |
|---|---|---|---|
| Claude Code | `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md` when no CLAUDE.md exists | `.claude/rules/*.md` with `paths:` frontmatter, nested `CLAUDE.md` in subdirectories | Rules without `paths:` load at launch like CLAUDE.md. Block-level HTML comments are stripped before injection, so they are free notes for maintainers. `@path` imports do not cut cost. |
| Codex | `AGENTS.md` per directory, `AGENTS.override.md` wins in the same directory | Files from the repository root down to the working directory are concatenated, closer files later | 32 KiB combined cap by default. One file per directory. |
| Cursor | `.cursor/rules/*.mdc` with `alwaysApply: true`, `AGENTS.md` | `globs` attaches on matching files, `description` lets the agent decide, no fields means manual `@rule` | Keep each rule under 500 lines and split into composable rules. Plain `.md` in the rules folder is ignored. |
| GitHub Copilot | `.github/copilot-instructions.md`, nearest `AGENTS.md` | `.github/instructions/*.instructions.md` with `applyTo` globs, optional `excludeAgent` | Path-specific files apply to the cloud agent and code review. Review reads the pull request head branch. |
| Gemini CLI | `GEMINI.md` (global, workspace, and just-in-time as tools touch files) | Subdirectory `GEMINI.md`, `@file.md` imports | `context.fileName` in settings can add `AGENTS.md`. `/memory show` prints the combined context. |

Facts sourced from the vendor docs in 2026-10: [Claude Code memory](https://code.claude.com/docs/en/memory), [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [Cursor rules](https://cursor.com/docs/context/rules), [Copilot instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot), [Gemini CLI GEMINI.md](https://geminicli.com/docs/cli/gemini-md/). Tool behavior changes quickly, so verify against the docs for the version in use.

Two scoping traps:

- Claude Code loads path-scoped rules into message history when the agent touches a matching file. A compaction summary can drop them. If a rule must survive compaction, remove `paths:` or move it to the root file.
- Claude Code reads `AGENTS.md` only when no `CLAUDE.md` exists at or above the working directory. A repository with both gets the CLAUDE.md files only, unless CLAUDE.md imports AGENTS.md.

## What belongs in the always-on file

| Keep | Example |
|---|---|
| Exact commands | `make test`, `make test-one T=path`, `make lint` |
| Non-obvious conventions | "Money is stored as integer cents. Never use floats." |
| Hard prohibitions with a reason | "Do not edit `generated/`. It is rebuilt by `make gen`." |
| Environment quirks | "Tests need `docker compose up db` first." |
| Pointers | "Read `docs/payments.md` before touching `src/payments/`." |
| Workflow rules the team cares about | "Branch names: `feat/PROJ-123_short_name`." |

ETH's study found agents follow specific instructions well. That is the content to keep. Commands and conventions the agent cannot infer pay for their tokens.

## What to cut

| Cut | Why |
|---|---|
| Repository overview, directory tree, stack list | The agent can read the tree. ETH found overviews did not help. |
| Style rules a formatter or linter enforces | The tool already reports violations, and text duplicates it. |
| Generic advice ("write clean code", "think carefully") | No behavior change, and models already do it. |
| Long API or framework tutorials | Fetch docs on demand (see `docs-lookup`) or link them. |
| Rules for a single package in the root file | Move to a nested or path-scoped file. |
| History and rationale paragraphs | Move to an ADR and link it. |
| Rules for tools or models the team no longer uses | Stale rules cost tokens and mislead. |
| Secrets, tokens, internal hostnames | Never belong in instruction files. They are committed and loaded into every session. |

## Before and after

Before (root file, 40 lines of the problem):

```markdown
# Project

This is a Symfony application. It has src/, tests/, config/ and public/.
src/ contains Controller, Entity, Repository and Service folders...
(20 lines of tree)

## Style
- Use 4 spaces. Use PSR-12. Always add return types. Be careful with nullability.

## Billing module
- Invoices are immutable once finalized.
- Use Money value objects. Never floats.
- Run `make test-billing` after changing anything here.
```

After:

```markdown
# Project

- Test: `make test`. One file: `make test-one T=tests/Foo/BarTest.php`
- Lint and format: `make fix` (PHP-CS-Fixer enforces PSR-12, do not hand-format)
- Billing rules live in `src/Billing/AGENTS.md`. Read it before editing that directory.
```

And `src/Billing/AGENTS.md` (or a path-scoped rule for `src/Billing/**`) holds the three billing lines. The style bullet is gone because the fixer enforces it. The tree is gone because the agent can list the directory.

## One file for several tools

Teams that use more than one agent should keep one source of truth.

| Approach | When |
|---|---|
| Write `AGENTS.md`, leave tool-specific files out | Every tool in use reads AGENTS.md (Codex, Cursor, Copilot and Claude Code without a CLAUDE.md all do) |
| `CLAUDE.md` containing `@AGENTS.md` plus a few Claude-only lines | Claude Code needs extras, or some sessions cannot read AGENTS.md directly |
| Symlink `CLAUDE.md` to `AGENTS.md` | Unix-only teams. Git checks a symlink out as a plain text file on Windows unless `core.symlinks` is enabled |
| Point Gemini CLI at AGENTS.md with `context.fileName` | Avoids a second copy for GEMINI.md |

Keep tool-specific files for tool-specific features only (Cursor globs, Copilot `applyTo`, Claude hooks). Never write the same rules into `AGENTS.md` and `CLAUDE.md`. An `@AGENTS.md` import avoids the second copy but does not lower context cost.

User-level files are separate per tool. Codex reads `~/.codex/AGENTS.md`. Claude Code documents `~/.claude/CLAUDE.md` as its user file and does not list a user-level `AGENTS.md`, so do not assume one reads the other.

## Migration steps

1. Measure. Count lines and bytes of every instruction file the agent loads. In Claude Code, run `/context` and `/doctor prompt-audit`. In Codex, add up the chain from the root.
2. Delete what the agent can discover, what a tool enforces, and what is stale.
3. Merge duplicates. Keep each rule in exactly one file.
4. Move scoped rules out of the root file into path-scoped rules or nested files.
5. Turn must-hold rules into hooks, linter rules or tests.
6. Replace long pasted material with a pointer.
7. Reorder so commands and hard prohibitions come first.
8. Run a few real tasks and compare with the old setup. If results are no worse, keep the smaller file.
9. Add a line back only when an observed failure justifies it, and note which failure in the commit message.

## Skill descriptions as context cost

Skill names and descriptions load every session, and bodies load when invoked. Many skills with long descriptions eat the listing budget, and overflow drops descriptions of the least-used skills first.

- Put the key use case first. Cut marketing words.
- Aim for 200 to 400 characters. The Claude Code cap is 1,536 for `description` plus `when_to_use`.
- Merge skills that always trigger together. Remove skills nobody invokes (`/skill-doctor` shows usage in Claude Code).
- For knowledge the agent needs on almost every task, prefer a compact always-on index over a skill. Vercel's eval showed agents often never invoke a skill they are not told to use.
- Do not copy skill descriptions into the instruction file as a routing table. It duplicates text the agent already receives and goes stale.
- For manual-only workflows, mark the skill so it stays out of the listing (`disable-model-invocation: true` in Claude Code), and invoke it by name.

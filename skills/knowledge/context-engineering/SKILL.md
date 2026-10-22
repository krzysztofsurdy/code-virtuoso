---
name: context-engineering
description: "How to budget and structure what a coding agent sees. Use when asked to trim, split or write AGENTS.md, CLAUDE.md, rules files or skill descriptions (for example 'CLAUDE.md is too long'), when an agent ignores instructions, forgets rules or drifts in long sessions, and when planning compaction or progress notes."
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Context engineering

An agent's context window is a budget, not storage. Every token it reads competes for attention with every other token, and reliability falls as the window fills (context rot). The job is to give the agent the smallest set of high-signal tokens for the step it is on, and to load everything else only when needed.

## Core Principles

| Principle | Meaning |
|---|---|
| **Smallest high-signal set** | Each line in an always-loaded file must change behavior. If the agent would do the right thing without it, delete it. |
| **Load by need, not by default** | Always-on files cost tokens on every turn. Path-scoped rules, skills and docs cost tokens only when used. |
| **Instructions, not overviews** | Agents follow specific rules well. Repository tours and architecture summaries mostly add cost. |
| **Point, do not paste** | Give a path or a command and let the agent read it. Pasted copies go stale. |
| **Write state outside the window** | Progress that matters lives in a file, not in conversation history that compaction will summarize. |
| **Enforce with tools, advise with text** | A rule that must hold every time belongs in a hook, linter or test. Text is guidance the agent may drop. |
| **One source of truth** | Write each rule in one file. Project rules go in `AGENTS.md`, and tool files import it or hold only tool-specific lines. |
| **Measure before adding** | Context files can lower success and raise cost. Add one only for a failure you have seen. |

## Evidence that more context can hurt

| Source | Finding |
|---|---|
| ETH Zurich and LogicStar, [arXiv 2602.11988](https://arxiv.org/abs/2602.11988) (2026) | Repository context files did not generally improve task success and raised inference cost by more than 20% on average, for both generated and developer-written files. Agents followed specific instructions, but repository overviews did not help. Useful for non-standard practices. |
| Vercel, [AGENTS.md outperforms skills](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) (2026-01-27) | On framework-API tasks, a passive 8 KB docs index in AGENTS.md passed 100%. Skills left on default behavior passed 53% (same as no docs) because the agent never invoked them in 56% of cases. |
| Chroma, [context rot](https://trychroma.com/research/context-rot) | Model reliability drops as input length grows, even on simple tasks. |
| Thoughtworks Radar vol. 34 (2026-04) | Adopt context engineering and curated shared instructions. Caution on agent instruction bloat. |

Read these together. Vercel's result is not "skills are bad". It says knowledge the agent needs on nearly every task belongs in always-on context as a compact index, and skills fit explicit, user-triggered workflows. ETH's result says the always-on file must stay short and specific. The two agree: put little in always-on context, and make all of it count.

## What goes where

Use the cheapest layer that still loads when the agent needs the content. Full decision table and examples are in [placement-guide](references/placement-guide.md).

| Layer | Loads | Put here |
|---|---|---|
| Always-on file (AGENTS.md, CLAUDE.md, GEMINI.md, copilot-instructions.md) | Every session | Build, test and lint commands. Non-obvious conventions. Hard prohibitions. Pointers to deeper docs. |
| Path-scoped rules (`.claude/rules/` with `paths:`, `.cursor/rules`, Copilot `.github/instructions/`) | When matching files are touched | Rules for one language, directory or file type. |
| Nested instruction files in subdirectories | When the agent works there | Rules for one package or service in a monorepo. |
| Skills | Description always, body when invoked | Repeatable workflows and reference material the agent should pull in on a trigger. |
| On-demand docs (`docs/`, ADRs, runbooks) | When the agent reads them | Architecture, history, long procedures, API detail. |
| Hooks, linters, CI, tests | Every time the event fires | Rules that must never be skipped. |
| Tool output | When a command runs | Facts the agent can discover itself. Do not copy these into instruction files. |

## Size budgets

| Item | Budget | Notes |
|---|---|---|
| CLAUDE.md | Under about 200 lines per file | Anthropic guidance. Longer files reduce adherence. Imports with `@path` organize a file but do not reduce cost, because imported files also load at launch ([memory docs](https://code.claude.com/docs/en/memory)). |
| Codex AGENTS.md chain | 32 KiB combined (`project_doc_max_bytes`) | Codex stops adding files once the limit is reached, so deep files can be silently left out. Raise the setting or split into nested directories ([Codex docs](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). |
| Claude Code skill listing | 1% of the context window, scaled with the model | Overflow drops descriptions of the least-used skills first. Raise with `skillListingBudgetFraction` (for example `0.02`) or a fixed character count via `SLASH_COMMAND_TOOL_CHAR_BUDGET`. Set rarely used personal or project skills to `"name-only"` in `skillOverrides` (plugin skills are managed through `/plugin` instead). |
| One skill entry | 1,536 characters for `description` plus `when_to_use` | Configurable with `skillListingMaxDescChars`. Put the key use case first. Aim for 200 to 400 characters ([skills docs](https://code.claude.com/docs/en/skills)). |
| Skill body | Under 500 lines, key rules at the top | After compaction only the first 5,000 tokens of each invoked skill return, with 25,000 tokens shared across skills ([context window docs](https://code.claude.com/docs/en/context-window)). |

Other tools have their own caps and defaults. Check the vendor docs for the tool in use before assuming these numbers carry over. Use `/context` in Claude Code for a live breakdown, and `/doctor prompt-audit` to find outdated or conflicting instruction files.

## Signs of instruction bloat

- The agent ignores a rule that is clearly written. Often a longer file buried it.
- The same rule appears in two files, or in the file and in a linter config.
- Rules that explain things the agent can see: directory trees, tech stack lists, a README summary.
- Rules written for an older model ("think step by step", "be careful") or for a tool the team dropped.
- Two files that disagree (one says tabs, the other spaces).
- Style rules a formatter already enforces.
- Rules for one package that load for the whole repository.
- Emphasis inflation: many lines marked IMPORTANT, NEVER or CRITICAL. When everything shouts, nothing stands out.
- A rule that exists because of an old incident nobody remembers.
- A skill routing table ("When X, use /skill") or an agent roster copied into the instruction file. Every skill and agent description already carries its trigger and reaches the model on its own, so the copy only adds size and goes stale. Entries for skills that are not installed point nowhere. Replace the table with one generic line ("Before acting, check the available skills and invoke any whose description matches the task") plus rules for the few skills that need a custom trigger, each checked against the installed set.
- The same project rules in both `AGENTS.md` and `CLAUDE.md`, or in a tool file and a global file. Keep one copy and import or point to it.

Fix by deleting first, then moving, then rewriting. For each line ask: what mistake would the agent make without this? If the answer is "none", delete it.

## Skill listing overflow

Agents load every skill name and description into context each turn, within a fixed budget. With many installed skills the budget runs out.

| | |
|---|---|
| **Symptoms** | Skills appear as bare names with no description. Skills that should match a request are never picked. The agent does the work itself instead of invoking the skill. |
| **Why** | In Claude Code the listing is capped at 1% of the context window and 1,536 characters per skill. Past the cap, descriptions of the least-used skills are dropped first. The name stays, but the trigger text the agent matches against is gone. |
| **Diagnose** | `/context` shows the Skills row, sized after the budget is applied. `/doctor` estimates the listing's cost and biggest contributors. `/skill-doctor` (Claude Code 2.1.252 or later) shows each skill's cost and how often it is invoked. Count installed skills: user, project, and plugin caches. A warning also goes to the debug log (`--debug`). |
| **Fix** | Disable unused plugins and skills (`/plugin` for plugin skills). Set low-value personal or project skills to `"name-only"` or `"off"` in `skillOverrides`, or mark them `disable-model-invocation: true` and invoke them by name. Trim descriptions and put the key use case first. As a last step, raise the budget with `skillListingBudgetFraction` (for example `0.02`) or `SLASH_COMMAND_TOOL_CHAR_BUDGET`, which spends more context on every turn. |

Sources: [skills docs, descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short), [override skill visibility](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings), [settings reference](https://code.claude.com/docs/en/settings-reference#skilllistingbudgetfraction). Other tools cap their listings differently, so check their docs.

## Instruction drift

Always-on instruction files load once at session start. As the conversation grows with file reads and tool output, they make up a smaller share of what the agent sees, and rules from early in the session are followed less (see context rot above). Symptoms: the agent follows the file for the first prompts, then stops using a convention, a persona, or a prohibition.

| Fix | How |
|---|---|
| Keep the file short and rules-only | A short file holds a larger share of attention. No overviews, no skill tables, no copies. Target under about 200 lines for CLAUDE.md. |
| Remind on every prompt | A `UserPromptSubmit` hook runs before each prompt, and its plain-text output is added as context the model can see ([hooks reference](https://code.claude.com/docs/en/hooks)). Have it print two or three rules that keep failing. Keep it to a few lines, since it costs tokens each turn. Setup is in the `hooks-and-guardrails` skill. |
| Enforce what must hold | Move must-never-fail rules to hooks, linters, or tests. |
| One session per task | Start a clean session (`/clear`) between unrelated tasks. |
| Compact with a focus | `/compact focus on ...` between phases. Project-root CLAUDE.md is re-read from disk after compaction ([what survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)), but conversation-only instructions and not-yet-reloaded scoped rules are lost. |

## One source of truth for instructions

Several tools means several files, and copies drift apart. Write project rules once in `AGENTS.md`. Claude Code reads `AGENTS.md` by itself only when no `CLAUDE.md` exists (v2.1.277 or later). If a `CLAUDE.md` is needed, make its first line `@AGENTS.md` and add only Claude-specific lines below. Never paste the same rules into both. The import avoids a second copy, but the imported text still loads at launch, so it does not lower cost ([memory docs](https://code.claude.com/docs/en/memory#agents-md)). For user-level files there is no shared standard: Codex reads `~/.codex/AGENTS.md`, and Claude Code documents `~/.claude/CLAUDE.md`. Keep each short. See [placement-guide](references/placement-guide.md#one-file-for-several-tools).

## Signs of context rot in a session

- The agent repeats a question you already answered or redoes finished work.
- It forgets a constraint stated early in the session.
- Quality drops after many large file reads or long tool outputs.
- It cites files or functions that do not exist.

Respond by compacting with a focus, writing state to a file, or starting a clean session, in that order of effort. Do not keep pushing in a degraded window.

## Compaction hygiene

Compaction replaces history with a summary. Plan for what it keeps and drops. Details and a notes template are in [long-task-notes](references/long-task-notes.md).

1. Put the most important instructions at the top of any file that gets re-injected. Truncation keeps the start.
2. Compact on your own schedule, between phases, with a focus: `/compact focus on the auth bug and the failing test list`. The automatic pass guesses what matters.
3. Clear between unrelated tasks (`/clear`). Old conversation crowds out the files you need next and costs tokens on every message.
4. Keep rules that must survive in always-on files. Path-scoped rules and nested files load into message history, so a compaction summary can drop them until the agent touches a matching file again.
5. Re-invoke a skill after compaction if the task depends on its full text.
6. Do not rely on chat history for decisions. Write them to a file.

Other agents compact differently. Check the tool's docs for what survives.

## Offload big reads to subagents

A subagent works in its own window. It may read tens of thousands of tokens and return a summary of about 1,000 to 2,000 tokens. Use one when the answer is small but the search is large: tracing a code path, auditing a directory, reading a long log, comparing many files.

- Ask for a condensed answer with file paths and line numbers, so the main agent can verify.
- Give the subagent a narrow question and the files to start from.
- Do not use one for work that needs the main conversation's context or for a three-file lookup you can do directly.

## Long tasks

For work that spans many sessions or compactions, keep a progress file and a task list in the repository, update them at each step, and begin every session by reading them. See [long-task-notes](references/long-task-notes.md) for the file layouts, the one-feature-per-session pattern, and handoff notes.

## Writing an instruction file: checklist

- [ ] Every line passes the test "what mistake does this prevent?"
- [ ] Commands are exact and runnable (build, test, lint, single-test)
- [ ] Only non-obvious conventions are listed, not what the code or a linter shows
- [ ] No repository overview, directory tree or stack list
- [ ] Rules scoped to part of the repo live in path-scoped rules or nested files
- [ ] Long reference material is linked, not pasted
- [ ] Hard requirements are backed by a hook, linter or test
- [ ] No duplicate or contradicting rules across files, and no skill routing table or agent roster
- [ ] Every skill the file names is installed
- [ ] Under the size budget for the tool in use
- [ ] A recent failure justifies each added rule

## Reference Files

| Reference | Contents |
|---|---|
| [placement-guide](references/placement-guide.md) | Decision flow for where each kind of instruction goes, per-tool file names and scoping, before and after examples, migration steps |
| [long-task-notes](references/long-task-notes.md) | Progress file and task list layouts, one-feature-per-session pattern, handoff notes, compaction checklist |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Fetching version-correct library docs instead of pasting them | `docs-lookup` |
| Running several agents with separate windows, or executing a plan task by task with fresh subagents | `agent-orchestration` |
| Proving work is complete before closing a long task | `verification-before-completion` |
| Generating rules files for a specific agent tool | `agentic-rules-writer` |
| Adding a reminder hook, deny rules or other enforcement | `hooks-and-guardrails` |
| Reviewing instruction files for secrets, hidden characters or injection | `security` |
| Auditing a repository's instruction files in one pass | `instruction-auditor` agent |

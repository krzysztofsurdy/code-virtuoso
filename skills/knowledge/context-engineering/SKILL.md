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
| Claude Code skill listing | 1% of the context window, scaled with the model | Overflow drops descriptions of the least-used skills first. Raise with `skillListingBudgetFraction` (for example `0.02`) or a fixed character count via `SLASH_COMMAND_TOOL_CHAR_BUDGET`. Set rarely used skills to `"name-only"` in `skillOverrides`. |
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

Fix by deleting first, then moving, then rewriting. For each line ask: what mistake would the agent make without this? If the answer is "none", delete it.

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
- [ ] No duplicate or contradicting rules across files
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
| Reviewing instruction files for secrets, hidden characters or injection | `security` |
| Auditing a repository's instruction files in one pass | `instruction-auditor` agent |

---
name: using-ecosystem
description: Ecosystem discovery advisor. Use when the user asks which skill, agent, or workflow fits a task, how to delegate, or what tools are installed. Reads the installed skills and agents at runtime. Triggers include 'which skill', 'which agent', 'orient me'.
user-invocable: true
argument-hint: "[optional: situation or topic]"
---

# Using ecosystem

Find the right skill, agent, or workflow for the situation at hand. The map below says what Code Virtuoso ships. Installs vary, so confirm with a scan before recommending anything.

## Core principles

| Principle | Meaning |
|---|---|
| **Scan, don't assume** | The matrix names what the repository ships. What the user has installed may be a subset, so check before you recommend. |
| **Match situation, not topic** | Pick the item whose description matches what the user is doing, not the one whose title loosely fits. |
| **Agents act, skills inform** | Delegate work to an agent. Consult a skill for procedure or reference. |
| **Narrower wins** | When two items overlap, pick the one with the tighter trigger match. |
| **Workflow only for multi-role work** | A workflow costs several agents' worth of tokens. If one agent can do the job, use one. |
| **Chain when work crosses domains** | Multi-step tasks often need two or three agents in sequence. |

## Step 1: Scan what is installed

Run the commands in [discovery-commands](references/discovery-commands.md) to list installed skills, agents, and workflows, then read each `name` and `description`. Skip this only when the user asks what the library offers in general.

## Step 2: Classify the situation

| Signal | Use |
|---|---|
| Needs a step-by-step procedure for a recurring job | Playbook skill |
| Needs a specific output (ticket, PR message, report, rules file) | Tool skill |
| Needs principles or patterns for a topic | Knowledge skill |
| Needs framework or AI-engineering guidance | Framework or AI skill |
| Needs one scoped task done (investigate, review, implement) | Specialist agent |
| Needs ongoing ownership of a domain (requirements, design, QA) | Role agent |
| Needs several roles to coordinate (feature delivery, multi-angle review, a decision with trade-offs) | Workflow |
| Needs a long backlog run unattended | `loop-virtuoso` plugin |

## Step 3: Match and recommend

1. Look the situation up in the decision matrix below, then confirm the item appeared in the scan.
2. Read the candidate's `description` and match on its trigger phrases.
3. Skills stack. Recommend two or three together when the task crosses topics, such as `tdd` with `security`.
4. If nothing installed fits, say so and name the plugin or skill that would, with its install route (see [Installing](#installing)).

### Decision matrix

| Situation | Use |
|---|---|
| A vague idea, no written spec | `brainstorming`, then `spec-driven-development` |
| An approved spec to turn into a plan and tasks | `spec-driven-development` |
| A ticket to carry through to a PR | `ticket-delivery` |
| Implementing a change or fixing a bug | `tdd`, or the `implementer` agent in a worktree |
| Unfamiliar code to understand | `investigator` agent |
| A diff to review | `reviewer` agent. For a significant change use the `review-squad` workflow. For a fresh-eyes pass use `cold-reviewer` |
| A design decision or ADR | `architect` agent. For a contested choice use the `war-room` workflow |
| A feature from requirements to QA sign-off | `development-team` workflow, or `product-manager`, `architect`, `backend-dev`, `frontend-dev`, `qa-engineer` in sequence |
| Plans that may not line up, or a plan that broke mid-work | `plan-auditor` agent |
| Proof a change meets its acceptance criteria | `acceptance-verifier` agent |
| Code smells and hotspots | `refactor-scout` agent, with `refactoring` for technique detail |
| Missing tests | `test-gap-analyzer` agent |
| A database migration | `migration-planner` agent, with `database-design` |
| Dependency health | `dependency-auditor` agent. For Composer use `composer-dependencies` |
| Changelog, API docs, migration guide | `doc-writer` agent |
| Review comments or failing CI on an open PR | `pr-feedback` |
| Ready to merge, open a PR, or clean up | `finishing-branch`, with `pr-message-writer` |
| Pausing mid-task or resuming | `handoff` |
| Several worktrees or parallel sessions | `worktree-ops` |
| Splitting work across agents | `agent-orchestration` |
| Instruction files that get ignored or keep growing | `context-engineering`, with the `instruction-auditor` agent |
| Hardening an agent setup | `hooks-and-guardrails`, with `agent-security` |
| Library API questions | `docs-lookup` |
| A question that needs sourced evidence: best practice, a comparison, "is this still recommended" | `research` skill, or the `researcher` agent for a separate context |
| Designing an LLM agent or workflow | `agent-design`, plus `llm-evals`, `llm-observability`, `mcp-server-development` |
| Building with the Vercel AI SDK or LangChain | `vercel-ai-sdk` or `langchain-components` |
| Symfony, Django, or PHP version work | `symfony-components`, `symfony-upgrade`, `django-components`, `php-upgrade` |
| Writing a ticket, report, or stakeholder update | `ticket-writer`, `report-writer`, `stakeholder-update-writer` |
| Writing agent rules files, agents, skills, or plugins | `agentic-rules-writer`, `agent-creator`, `skill-writer`, `plugin-creator` |
| Running a compiled backlog with an objective gate | `loop-virtuoso` plugin (Claude Code) |
| Claiming work is done | `verification-before-completion` |

## Step 4: Chain when needed

Common chains are in [chaining-patterns](references/chaining-patterns.md). They are templates: skip steps that do not apply. If a workflow matches the chain, run the workflow instead.

## Step 5: Compass (what next?)

When the user has just finished something and asks "what next?":

1. Ask what they completed and what output they have.
2. Read [compass](references/compass.md) for the likely next step.
3. Confirm the next step is installed.
4. Give one recommendation with a one-line reason, or two or three options if the path forks.
5. If nothing chains naturally, say so.

Compass is conversational. Ask the user; do not scan the filesystem to guess what happened.

## What the library contains

| Layer | Location | Purpose |
|---|---|---|
| **Skills** | `skills/{knowledge,tools,playbooks,frameworks,ai}/` | Reference material, tools, procedures, framework guidance, AI engineering |
| **Agents** | `agents/*.md` | Specialist and role sub-agents. Role agents read their templates from `roles/<name>/` |
| **Workflows** | `workflows/*.js` | Claude Code scripts for the review squad, development team, and war room |
| **loop-virtuoso** | `plugins/loop-virtuoso/` | Claude Code plugin that runs a backlog one verified step at a time |
| **Codex agents** | `codex/agents/*.toml` | The same agents as Codex custom agents, installed by `scripts/install-codex-agents.sh` |

### Skill categories

| Category | Holds | How it runs |
|---|---|---|
| `knowledge` | Principles and reference | Some load automatically. The textbook ones (`solid`, `design-patterns`, `clean-architecture`, `refactoring`, `testing`, `api-design`, `database-design`, `cicd`, `performance`, `microservices`, `scrum`) run only when named, for example `/solid` |
| `tools` | Outputs and interactive generators | By name. The CI wrappers (`review-pr`, `review-pr-cold`, `scan-refactors`, `find-test-gaps`, `audit-dependencies`, `plan-migration`, `verify-acceptance`) are for headless runs |
| `playbooks` | Step-by-step procedures | By name or when the task matches |
| `frameworks` | Symfony, Django, LangChain, PHP, Vercel AI SDK | When the framework is in play |
| `ai` | Agent design, evals, observability, MCP servers | When building LLM features |

### Agent tiers

| Tier | Scope | Examples |
|---|---|---|
| Specialist | One repeatable task, stateless | `investigator`, `researcher`, `reviewer`, `refactor-scout`, `plan-auditor` |
| Role | A domain of responsibility, some keep project memory | `architect`, `product-manager`, `backend-dev`, `qa-engineer` |

## Installing

| Harness | Route |
|---|---|
| Claude Code | `/plugin marketplace add krzysztofsurdy/code-virtuoso`, then install the plugins you want. Install `loop-virtuoso` for the delivery loop |
| Codex | `codex plugin marketplace add krzysztofsurdy/code-virtuoso` for skills, and `scripts/install-codex-agents.sh` for agents. See `codex/README.md` |
| Other tools | Copy `skills/` and `agents/` to where the tool reads them, or run `npx skills add krzysztofsurdy/code-virtuoso` |

## Quality checklist

- [ ] Did the recommendation come from a scan of what is installed, not from memory?
- [ ] Did it match on trigger phrases, not just the name?
- [ ] Is there a narrower item that fits better?
- [ ] Did it pick an agent for actionable work and a skill for reference?
- [ ] Did it use a workflow only when several roles must coordinate?
- [ ] Did it avoid presenting something uninstalled as available?

## Critical rules

1. **Confirm before recommending.** The matrix is the shipped set, not the installed set.
2. **Situation over title.** Match what the user is doing.
3. **Specialist for scoped tasks, role for domain work, workflow for multi-role delivery.**
4. **Chain over stretch.** Combine two items rather than forcing one beyond its fit.
5. **Respect agent boundaries.** Read-only agents do not edit files. Dev agents run in worktrees.

## Reference files

| Reference | Contents |
|---|---|
| [discovery-commands](references/discovery-commands.md) | Commands to list installed skills, agents, and workflows in Claude Code, Codex, and other tools |
| [chaining-patterns](references/chaining-patterns.md) | Multi-step chain templates with when-to-use guidance |
| [compass](references/compass.md) | "What next?" map for post-task navigation |

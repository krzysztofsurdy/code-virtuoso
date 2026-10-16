---
name: agent-creator
description: Interactive tool to design a sub-agent definition (specialist, role, or team-lead) with the right frontmatter, tools, isolation, memory, and system prompt. Use when asked to create a sub-agent, write an agent file, or scaffold a role agent.
user-invocable: true
argument-hint: "[optional: archetype - specialist, role, team-lead]"
---

# Agent Creator

Create a sub-agent that earns its context window. Most agents fail because the definition is vague, not because the model is weak: the trigger is unclear, the tool list sprawls, the body mixes persona and procedure, and there is no output contract. This skill walks through a six-phase design that produces a focused, least-privileged agent with predictable output.

## Core Principles

| Principle | Meaning |
|---|---|
| **One job, one agent** | An agent that does two things does neither well. Split the responsibility before writing. |
| **Least privilege** | Grant the smallest tool set that lets the agent finish its job. Read-only by default. |
| **Trigger-first description** | The `description` field is the only thing read before delegation. Include keywords and "when to use". |
| **Contract over conversation** | Define explicit input, process, and output. Agents are not chat sessions. |
| **Isolation when writing** | If the agent edits files, run it in a worktree so the orchestrator can review before merging. |
| **Portable body, platform frontmatter** | Keep the system prompt agent-agnostic. Adapt frontmatter fields per target platform. |

---

## Agent vs skill

Confirm an agent is the right primitive before creating one.

| Use a Skill | Use an Agent |
|---|---|
| Reference material (patterns, checklists, schemas) | Work to perform (investigate, review, implement) |
| Loaded into an existing session | Runs in its own context window |
| Passive knowledge | Active actor with tools and a workflow |
| "Where do I learn about X" | "Do X for me and return a result" |

If the answer is reference material, stop and use the `skill-creator` skill instead. If the answer is work, continue.

---

## Archetype selection

Agents fall into three archetypes. Pick one before designing.

| Archetype | Scope | Memory | Modifies files | Typical examples |
|---|---|---|---|---|
| **Specialist** | Single, repeatable task type | Stateless | Rarely (doc writer, implementer) | Investigator, Reviewer, Refactor Scout, Dependency Auditor, Test Gap Analyzer |
| **Role** | Entire domain of responsibility | Often persistent (project-level) | Dev roles yes, others no | Product Manager, Architect, Backend Dev, QA Engineer, Project Manager |
| **Team-Lead** | Coordinates multiple workers in parallel | Shared task list | No (delegates) | Orchestrator, release-train lead, review dispatcher |

### Decision tree

1. Does the agent do **one repeatable task type** (review this PR, investigate this area, audit dependencies)? -> **Specialist**
2. Does the agent **own a domain** across many task types and benefit from remembering context across sessions (requirements, architecture decisions, risk register)? -> **Role**
3. Does the agent need to **spawn and coordinate other agents** working in parallel (research teams, multi-layer refactors)? -> **Team-Lead**

If the user provided an archetype as an argument, use it. Otherwise present a selectable menu using `AskUserQuestion` (or the platform's equivalent interactive prompt) with the three options from the table above.

See [references/archetypes.md](references/archetypes.md) for worked examples of each archetype and the anti-patterns to avoid.

---

## Workflow

This skill uses guided phases. Each phase is a separate file, loaded one at a time. Every phase ends with a gate: wait for user confirmation before proceeding. Do not skip or merge phases.

| Phase | File | What it covers |
|---|---|---|
| 1 | [Purpose and trigger](phases/01-purpose-and-trigger.md) | What the agent does, when to delegate, out-of-scope, output shape, archetype |
| 2 | [Name and identity](phases/02-name-and-identity.md) | Kebab-case name, collision check, user confirmation |
| 3 | [Capabilities](phases/03-capabilities.md) | Tool permissions, isolation, memory, preloaded skills |
| 4 | [System prompt](phases/04-system-prompt.md) | Five-section contract: Input, Process, Rules, Output |
| 5 | [Placement and scope](phases/05-placement-and-scope.md) | Where the file lives: project, personal, plugin, session |
| 6 | [Validate and write](phases/06-validate-and-write.md) | Checklist, file creation, marketplace registration |

Start by loading Phase 1. After the user confirms each phase, load the next. Never load multiple phases at once and never skip one.

---

## Reference Files

| Reference | Contents |
|---|---|
| [archetypes.md](references/archetypes.md) | Worked examples of specialist, role, and team-lead agents, plus anti-patterns |
| [frontmatter-fields.md](references/frontmatter-fields.md) | Full field reference, portable vs platform-specific, and examples |
| [tool-selection.md](references/tool-selection.md) | Least-privilege tool allowlists, per-archetype defaults, and denylist patterns |
| [system-prompts.md](references/system-prompts.md) | System prompt patterns: role-input-process-rules-output contract, worked examples |
| [platforms.md](references/platforms.md) | Scope paths, platform-specific frontmatter fields, and agent-team considerations |
| [validation.md](references/validation.md) | Pre-publish checklist and common rejection reasons |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Creating a reference skill instead of an agent | `skill-creator` |
| Writing AI rules files for an agent platform | `agentic-rules-writer` |
| Designing how multiple agents interact in a workflow | See `archetypes.md` team-lead section |
| Authoring a ticket or PRD that spawns the agent | `ticket-writer` |

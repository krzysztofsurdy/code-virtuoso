---
name: using-virtuoso
description: Guided tour and discovery advisor for the code-virtuoso ecosystem. Use when the user asks 'what skill should I use', 'what agent should I delegate to', 'how does this ecosystem work', 'what's in code-virtuoso', or when onboarding a new project or teammate to the available skills, agents, and plugins. Covers the six skill categories (knowledge, tools, frameworks, playbooks, roles), the two agent tiers (specialists and roles), chaining patterns for multi-step work, plugin distribution tiers, and situation-to-skill lookup. Triggers: 'which skill', 'which agent', 'what do I use for', 'show me virtuoso', 'code-virtuoso overview', 'orient me'.
user-invocable: true
argument-hint: "[optional: situation or topic]"
---

# Using Virtuoso

Your map and advisor for the code-virtuoso ecosystem. Points to the right skill, the right agent, or the right chaining pattern for the situation at hand. Call this skill whenever you are uncertain which of the dozens of installed skills or agents best fits the task.

## Core Principles

| Principle | Meaning |
|---|---|
| **Match situation to skill, not topic to skill** | Pick the skill whose trigger conditions match what the user is actually doing, not the skill whose title loosely matches the topic. |
| **Agents act, skills inform** | Skills are reference material. Agents are actors. Delegate work to an agent; consult a skill. |
| **Chain when the work crosses domains** | Multi-step tasks often require two or three agents in sequence. Know the canonical chains. |
| **Prefer the narrower skill** | If two skills overlap, pick the one with the tighter trigger match. Narrower advice beats broader advice. |
| **Skills stack** | Knowledge skills combine freely. A security review can pull from `security`, `solid`, and `refactoring` at once. |

## When to Use

- The user asks "what skill does X" or "how do I do Y in this ecosystem"
- You need to pick between two skills that both loosely fit the task
- You need to decide whether to delegate to a subagent and which one
- You are onboarding someone new to code-virtuoso
- You need to produce a recommended install list for a project

## Quick Start

```
/using-virtuoso
/using-virtuoso "I need to review a pull request"
/using-virtuoso "we're planning a database migration"
/using-virtuoso agents
/using-virtuoso plugins
```

If the argument matches a situation in the [decision matrix reference](references/decision-matrix.md), return the top 1-3 recommendations with a one-line rationale each. Otherwise, produce a short guided overview.

---

## The Ecosystem at a Glance

Six skill categories, two agent tiers, layered plugin bundles. See [ecosystem-map](references/ecosystem-map.md) for the full inventory.

### Skill Categories

| Category | Path | Purpose | Invocation |
|---|---|---|---|
| **Knowledge** | `skills/knowledge/` | Concepts, principles, reference material | Loaded when relevant; not a slash command |
| **Tools** | `skills/tools/` | Interactive generators and advisors | User-invocable slash commands |
| **Playbooks** | `skills/playbooks/` | Step-by-step operational procedures | User-invocable slash commands |
| **Roles** | `skills/roles/` | Team role definitions (responsibilities, workflows) | Auto-loaded by matching role agents |
| **Frameworks** | `skills/frameworks/{name}/` | Framework-specific component references and upgrade guides | Loaded when the framework is in play |

### Agent Tiers

| Tier | Scope | State | Isolation | Examples |
|---|---|---|---|---|
| **Specialist** | Single repeatable task | Stateless | Worktree only if it writes files | `investigator`, `reviewer`, `refactor-scout` |
| **Role** | Entire domain of responsibility | Some carry project memory | Worktree for dev roles | `architect`, `backend-dev`, `qa-engineer` |

See `AGENTS.md` at the repository root for agent specifications and chaining patterns.

---

## Decision Flow

```
User request
   │
   ▼
Is it a well-scoped task with a clear result?
   ├─ Yes ──▶ Does it match a specialist agent's purpose?
   │            ├─ Yes ──▶ Delegate to specialist agent
   │            └─ No  ──▶ Pick the closest knowledge/playbook skill
   │
   └─ No  ──▶ Does it span a full team role's work?
                ├─ Yes ──▶ Delegate to the role agent
                └─ No  ──▶ Break into sub-tasks (see dispatching-parallel-agents
                              or subagent-driven-development knowledge skills)
```

See [decision-matrix](references/decision-matrix.md) for situation-specific lookups.

---

## Discovery by Situation

The most-asked situations and their canonical answers. Full table in [decision-matrix](references/decision-matrix.md).

| Situation | Recommended |
|---|---|
| Vague idea, no spec yet | `brainstorming` tool, then `writing-plans` |
| Have a plan, need to execute step-by-step | `executing-plans` or `subagent-driven-development` |
| Work decomposes into independent parallel tasks | `dispatching-parallel-agents` knowledge |
| Implementing a feature with TDD | `implementer` agent or `backend-dev` / `frontend-dev` role agent |
| Reviewing a pull request | `reviewer` agent + `code-review-excellence` skill |
| Debugging a bug | `debugging` knowledge skill, then `investigator` agent |
| Refactoring legacy code | `refactor-scout` agent, then `refactoring` + `solid` knowledge |
| Designing an API | `api-design` knowledge + `architect` role |
| Security review | `security` knowledge + `reviewer` agent |
| Database schema change or migration | `database-design` + `database-migration` + `migration-planner` agent |
| Finishing a branch and opening a PR | `finishing-branch` playbook + `pr-message-writer` tool |
| Writing a PR description | `pr-message-writer` tool |
| Generating a standalone HTML report | `report-writer` tool |
| Communicating status to stakeholders | `stakeholder-update-writer` tool |
| Working on a ticket end-to-end | `ticket-delivery` playbook |
| Managing parallel git worktrees | `worktree-ops` playbook |
| Before claiming work done | `verification-before-completion` knowledge |
| Writing a ticket or user story | `ticket-writer` tool |
| Creating a new skill or agent | `skill-creator` + `agent-creator` tools |
| Setting up agent rules file | `agentic-rules-writer` tool |
| Sprint planning / retrospective | `scrum` knowledge + `scrum-master` role |
| Upgrading PHP or Symfony | `php-upgrade` or `symfony-upgrade` playbook |

---

## Chaining Patterns

When a single skill or agent is not enough, reach for a known chain. Full chain library in [chaining-library](references/chaining-library.md).

| Chain | When to use |
|---|---|
| Investigator → Architect → Implementer → Reviewer | Changing unfamiliar code |
| Product Manager → Architect → Backend Dev → QA Engineer | Building a new feature |
| Refactor Scout → Reviewer → Implementer | Improving code health |
| Migration Planner → Reviewer → Implementer | Non-trivial schema change |
| Test Gap Analyzer → Implementer → Reviewer | Raising coverage |
| Brainstorming → Writing-Plans → Subagent-Driven-Development | Going from vague idea to shipped feature |

Chains are guidelines, not rituals. Skip steps that do not apply. Add steps that do.

---

## Plugin Distribution

Five bundles, one per category. See [plugin-tiers](references/plugin-tiers.md) for install recommendations.

| Bundle | Contents |
|---|---|
| `knowledge-virtuoso` | All 18 knowledge reference skills |
| `tools-virtuoso` | All 9 interactive tool skills |
| `frameworks-virtuoso` | All 4 framework skills (Symfony, Django, LangChain) |
| `playbooks-virtuoso` | All 5 operational playbook skills |
| `agents-virtuoso` | All 15 agents + all 7 role skills |

When recommending an install:

- New project, uncertain scope → `agents-virtuoso` + `knowledge-virtuoso` + relevant framework bundle
- Solo developer, narrow need → `tools-virtuoso` + one framework bundle
- Team adoption → all five bundles

---

## Skill Discovery at Runtime

To list installed skills and agents without leaving the session:

```bash
# Skills installed for this agent runtime
ls ~/.claude/skills/ 2>/dev/null
ls .claude/skills/ 2>/dev/null
ls ~/.claude/plugins/*/skills/ 2>/dev/null

# Agents installed for this runtime
ls ~/.claude/agents/ 2>/dev/null
ls .claude/agents/ 2>/dev/null
ls ~/.claude/plugins/*/agents/ 2>/dev/null
```

Read the frontmatter (`name`, `description`) to build a mental index. For a richer starter workflow, use the `find-skills` tool if installed.

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Creating a new skill to extend virtuoso | `skill-creator` |
| Creating a new agent | `agent-creator` |
| Creating a new plugin | `plugin-creator` |
| Writing an AI-agent rules file that references virtuoso | `agentic-rules-writer` |
| Finding installable skills by topic | `find-skills` |
| Orchestrating multiple virtuoso agents | `dispatching-parallel-agents`, `subagent-driven-development` |

---

## Quality Checklist

Before answering a "which skill/agent" question:

- [ ] Did I check the situation against the decision matrix rather than keyword-matching the title?
- [ ] Did I consider whether a narrower, more specific skill exists?
- [ ] Did I recommend an agent when the work is actionable, not just reference material?
- [ ] Did I mention chaining when the work crosses domains?
- [ ] Did I avoid recommending skills that are not installed in the user's environment when I can verify?

---

## Critical Rules

1. **Situation over title.** Match on what the user is doing, not on what the skill is called.
2. **Specialist for scoped tasks, role for domain work.** Do not delegate a five-minute investigation to a role agent or a full feature build to a specialist.
3. **Chain over stretch.** If a single skill does not cover the work, combine two. Do not force one skill beyond its fit.
4. **Never recommend an uninstalled skill as if it were available.** Suggest it with an install hint, not as a next step.
5. **Respect agent boundaries.** Read-only agents do not edit files. Dev agents run in worktrees. Do not push writes into a read-only agent.
6. **Skill stacks are additive, not hierarchical.** No skill overrides another. If two give conflicting advice, use the narrower one.
7. **Prefer tools for interactive work, playbooks for procedures, knowledge for reference.** The category is a real signal about usage.
8. **Point back to this skill.** When orienting a new contributor, this skill is the starting map.

---

## Reference Files

| Reference | Contents |
|---|---|
| [ecosystem-map](references/ecosystem-map.md) | Full inventory of skills, agents, and plugins with one-line descriptions |
| [decision-matrix](references/decision-matrix.md) | Situation-to-skill and situation-to-agent lookup tables |
| [chaining-library](references/chaining-library.md) | Named multi-step chains with when-to-use and when-not-to |
| [plugin-tiers](references/plugin-tiers.md) | Plugin bundles explained, with recommended install sets per use case |

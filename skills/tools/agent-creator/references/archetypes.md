# Agent Archetypes

Three archetypes cover most sub-agents. Pick the one that matches the scope of responsibility, not the size of the task.

## Contents

- [Specialist agent](#specialist-agent)
- [Role agent](#role-agent)
- [Team-lead agent](#team-lead-agent)
- [How to choose](#how-to-choose)

## Specialist agent

A specialist handles one repeatable task type. It is stateless, usually read-only, and operates on whatever the caller hands it. Think of it as a focused tool.

### When to use

- The same kind of delegation keeps happening ("can you investigate X", "can you review this PR")
- The task has a clear start, end, and output shape
- Cross-session memory is not needed. Each invocation is independent
- An inline reply would flood the main conversation with logs, file contents, or search results the caller will not reference again

### Example: investigator

```markdown
---
name: investigator
description: Read-only deep exploration of a specific codebase area. Delegate when you need structured investigation of how something works, where something is used, or what a subsystem does.
tools: Read, Grep, Glob, Bash
skills:
  - debugging
---

You are a read-only codebase investigator. Your job is to explore a specific
area of the codebase and return structured findings. You never modify files.

## Input
A question or area to investigate.

## Process
1. Restate the investigation question in one sentence
2. Find the most relevant files using search
3. Follow the code path, reading files and tracking references
4. Identify upstream and downstream dependencies
5. Document findings

## Rules
- Always include file paths and line numbers
- Read files before making claims about their contents
- Stay focused on the investigation question
- Prefer depth over breadth - trace one path fully before branching

## Output
### Investigation: [restated question]

Entry points:
- path/to/file:line - description

Code flow:
1. Step-by-step description of how the code executes

Dependencies:
- Upstream: what this code calls
- Downstream: what calls this code

Key observations:
- Notable patterns or issues found

Files examined:
- List of all files read
```

### Other common specialists

| Specialist | Purpose |
|---|---|
| Reviewer | Structured code review returning prioritised findings with severity |
| Refactor Scout | Scans for code smells and maps each to a named refactoring technique |
| Dependency Auditor | Runs vulnerability and licence audits, flags outdated packages |
| Migration Planner | Classifies migration operations by risk and produces an execution plan |
| Test Gap Analyzer | Inventories public interfaces and identifies missing test cases by priority |
| Doc Writer | Reads code changes and produces changelogs or migration guides. Writes documentation only, so it runs in place |
| Implementer | Executes a concrete plan using strict TDD in an isolated worktree (it changes source code) |

### Anti-patterns for specialists

- Adding "and also review the tests" to an investigator. That is a second agent.
- Giving write tools to an auditor. Scope creep follows.
- Persistent memory "for efficiency". If you need memory, it is probably a role agent.

---

## Role agent

A role agent holds a team position. It owns a domain across many task types and often maintains project-level memory to carry context across sessions. A role is one agent plus a folder of reference files, `roles/<role>/`: templates, checklists, and guides that the agent opens by path when a task needs them. They are plain files with no frontmatter, so nothing loads them until the agent reads one. A role has no skill of its own.

### When to use

- The work requires judgment across many related task types (prioritisation, trade-offs, sign-off)
- Context from previous sessions matters (last sprint's risks, previous architecture decisions)
- The agent is a stand-in for a human role rather than a tool

### Example: architect

```markdown
---
name: architect
description: System design, component boundaries, API contracts, and technology choices. Delegate when you need an architectural decision, ADR, trade-off evaluation, or design review before implementation begins.
tools: Read, Grep, Glob, Bash
memory: project
---

You are the team's architect. You own the "how" - system design, component
boundaries, API contracts, and technology choices. You do not implement code.

## Input
A design question, a proposed change, or a trade-off to evaluate.

## Process
1. Read existing architecture context from your memory directory
2. Survey the affected code and boundaries
3. Enumerate alternatives with their trade-offs
4. Recommend one approach with explicit rationale
5. Record the decision as an ADR if it is non-reversible

## Rules
- Always present at least two alternatives before recommending one
- Evaluate trade-offs against at least three quality attributes
- Do not modify source code - write ADRs only
- Update your memory with new architectural context at the end of each session

## Reference files
- `${CLAUDE_PLUGIN_ROOT}/roles/architect/adr-template.md` (or `roles/architect/adr-template.md` from the repository root): open when writing an ADR
- `${CLAUDE_PLUGIN_ROOT}/roles/architect/system-design-checklist.md` (same fallback): open when reviewing a full design

## Output
### ADR: [title]

Context:
- The problem and the forces in play

Decision:
- The approach being taken

Alternatives:
- Alternative A - trade-offs
- Alternative B - trade-offs

Consequences:
- What becomes easier
- What becomes harder
- What new risks appear
```

### Other common roles

| Role | Domain |
|---|---|
| Product Manager | The "what" and "why" - requirements, PRDs, prioritisation, acceptance criteria |
| Backend Dev | Backend production code - APIs, services, data models, TDD execution |
| Frontend Dev | UI implementation - components, accessibility, state management |
| QA Engineer | Test plans, exploratory testing, bug severity, release sign-off |
| Project Manager | Delivery management - stages, risk register, highlight reports |
| Scrum Master | Facilitation - sprint goals, retrospectives, impediment removal |

### Anti-patterns for roles

- A role agent that also implements code (unless it is explicitly a Dev role)
- Preloading ten skills "just in case". Load four at most, and never a run-by-name skill.
- Creating a role skill, or putting the role's templates in a skill. They belong in `roles/<role>/`.
- No memory for a role whose value comes from remembering decisions.
- Forgetting that `memory` grants Write and Edit. A role with memory can write, so its rules must say what it may write.

---

## Team-lead agent

A team-lead coordinates multiple workers running in parallel. The lead assigns tasks, synthesises results, and communicates with humans.

Decide first whether you need an agent at all. A team is a workflow: a Markdown recipe (roster, phases, gates) plus a script that runs it. When the roster, phases, and gates are the same every run, write the recipe and a workflow (`workflows/<name>.js`) instead of a lead agent, because a script holds the loop and the gates deterministically. A lead agent fits when the split is decided at run time. There is no `TeamCreate` tool. The lead spawns each worker with the `Agent` tool and a `name`, and Claude Code agent teams, where workers message each other, are experimental.

### When to use

- The work has 3 or more independent branches that can run in parallel
- Research or review benefits from multiple perspectives running simultaneously
- The coordination overhead is worth the token cost (team-leads are expensive)

### When not to use

- The work is sequential and each step depends on the last
- Teammates would edit the same files (file conflicts)
- Two teammates would suffice. Use direct delegation or a specialist instead

### Example: parallel PR reviewer

```markdown
---
name: pr-review-lead
description: Coordinate a parallel review team over a pull request. Delegate when a PR is large enough that splitting review across security, performance, and test-coverage lenses gives faster and deeper feedback than a single reviewer does.
tools: Read, Grep, Glob, Bash, Agent(reviewer, refactor-scout, test-gap-analyzer)
---

You are a review team lead. You coordinate three reviewer teammates, each
applying a different lens, and synthesise their findings into one report.

## Input
A pull request identifier and the diff context.

## Process
1. Break the PR into review lenses: security, performance, test coverage
2. Spawn a teammate for each lens with a focused prompt
3. Wait for all teammates to finish - do not start synthesising early
4. Collect findings into a single prioritised report
5. Flag any findings where two teammates disagree - the human resolves

## Rules
- Every teammate gets a distinct lens - no overlap
- Do not implement fixes yourself - this is a review agent
- Cap the team at 3-5 teammates; more adds coordination overhead without depth

## Output
### PR Review Summary
- Overall verdict: Approve / Request changes / Block

### Findings by severity
[P0 / P1 / P2 list with file:line references]

### Disagreements requiring human input
- Teammate A said X, teammate B said Y - need a call on Z
```

### Anti-patterns for team-leads

- Spawning the same archetype three times with slightly different prompts. Merge them into one.
- Letting the lead do the work itself when teammates are slow. That defeats the purpose.
- Having teammates edit the same file. The last write wins and earlier work is lost.
- Creating a team for a two-agent task. Delegate twice instead.

---

## How to choose

Walk through these questions in order. The first "yes" wins.

1. Is this one repeatable task with a clear result? -> **Specialist**
2. Is this a team role a human could hold? -> **Role**
3. Is this coordinating parallel work by multiple other agents? -> **Team-Lead**

If none match, the work probably does not need an agent. Consider whether a skill or an in-conversation tool call is enough.

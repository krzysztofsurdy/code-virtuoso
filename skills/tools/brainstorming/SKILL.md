---
name: brainstorming
description: "Interactive pre-implementation design exploration. Use when the user has a vague idea, feature request, or problem statement but no written spec. Asks focused questions one at a time to surface goals, non-goals, constraints, success criteria, and risks, then produces a written spec and hard-gates implementation until approved. Use before writing any code, before planning, and before answering 'how should I build X'. Triggers: 'I want to build', 'I'm thinking about', 'help me figure out', 'let's brainstorm', 'help me spec out'."
user-invocable: true
argument-hint: "[optional: one-line topic]"
---

# Brainstorming

Structured pre-implementation design exploration. Transforms a vague idea into a written spec through focused, one-at-a-time questioning before any code is written, any plan is created, or any architecture is decided. The spec is the deliverable -- everything else follows from it.

**No code until the spec is written and approved.**

## When to Use

- The user says "I want to build X" but has no written requirements
- A feature request exists as a sentence or two with no detail
- The user asks "how should I build X" before defining what X actually is
- Someone says "let's brainstorm" or "help me figure this out"
- A problem statement exists but the solution space is unexplored

## Quick Start

```
/brainstorming user authentication for a SaaS app
/brainstorming migrate our monolith to services
/brainstorming                                     # asks what to explore
```

If `$ARGUMENTS` is provided, use it as the initial topic and skip straight to Phase 1. If no argument, ask: "What idea, feature, or problem would you like to explore?"

---

## Workflow

This skill uses **guided phases** -- each phase is a separate file loaded one at a time. Every phase ends with a gate where you must wait for user confirmation before proceeding. Do not skip phases or merge them.

| Phase | File | What it covers |
|---|---|---|
| 1 | [Intake](phases/01-intake.md) | Read context, classify maturity, summarize understanding |
| 2 | [Divergence](phases/02-divergence.md) | Expand problem space with one-at-a-time questions across 7 categories |
| 3 | [Convergence](phases/03-convergence.md) | Narrow to concrete scope, lock must-haves and non-goals |
| 4 | [Spec Writing](phases/04-spec-writing.md) | Write full spec from gathered material, run quality checklist |
| 5 | [Approval](phases/05-approval.md) | Get explicit user approval, hard-gate implementation |

**Start by loading Phase 1.** After the user confirms each phase, load the next. Never load multiple phases at once. Never skip a phase.

---

## Critical Rules

1. **No code until the spec is approved.** Not pseudocode, not scaffolding, not "just a quick example."
2. **One question per message.** Compound questions produce shallow answers.
3. **Open questions before closed questions.** Explore before narrowing.
4. **Challenge assumptions, not people.** "Is X a hard requirement, or an assumption we should test?"
5. **The user defines scope, not the agent.** Surface possibilities through questions, let the user decide.
6. **Non-goals are as important as goals.** A spec without explicit non-goals has undefined boundaries.
7. **Acceptance criteria must be testable.** "It should be fast" is not testable. "Under 200ms at p95" is.
8. **Scale depth to complexity.** Simple features get short specs. System redesigns get thorough ones.
9. **Resolve contradictions before locking scope.**
10. **The spec is a living document until approved.**

---

## Question Technique

| Principle | Meaning |
|---|---|
| **One at a time** | One question, one message |
| **Open before closed** | "What" and "why" first; "which" and "would you prefer" later |
| **Challenge assumptions** | When something is stated as obvious, ask what would happen if it were not true |
| **Surface constraints early** | Constraints eliminate solution space -- the sooner known, the less rework |
| **Offer options when narrowing** | Present 2-3 concrete choices instead of open-ended questions during convergence |
| **Name the silence** | If an important topic has not come up, ask about it explicitly |

See [question-playbook](references/question-playbook.md) for the full catalog.

---

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Solution jumping | Stay in divergence until goals and constraints are clear |
| Compound questions | One question per message |
| Leading questions | Ask neutral: "What scale needs exist?" not "Should we use microservices?" |
| Premature implementation | Hard-gate: no code until spec is approved |
| Fake consensus | Probe: "Can you walk me through how you'd use this?" |
| Scope creep during convergence | Park in "future considerations", re-lock scope |

See [anti-patterns](references/anti-patterns.md) for the full guide.

---

## Reference Files

| Reference | Contents |
|---|---|
| [question-playbook](references/question-playbook.md) | Full catalog of question types with example phrasings |
| [spec-template](references/spec-template.md) | Output template the spec must follow |
| [anti-patterns](references/anti-patterns.md) | Failure modes that derail brainstorming |
| [when-to-exit](references/when-to-exit.md) | Criteria for "done" vs. "needs more rounds" |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Spec approved, ready for planning | `writing-plans` |
| Complex requirements, need stakeholder analysis | `product-manager` role |
| Spec reveals architectural decisions needed | `architect` role |
| Spec approved, ready for direct TDD | `test-driven-development` |
| Acceptance criteria need test plan detail | `qa-engineer` role |
| API design decisions | `api-design` |
| Database schema decisions | `database-design` |

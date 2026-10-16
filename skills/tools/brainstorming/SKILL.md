---
name: brainstorming
description: Interactive design exploration before implementation. Use when the user has a vague idea or feature request and no written spec. Asks one focused question at a time, writes a spec, and blocks implementation until approved. Triggers include 'I want to build', 'let's brainstorm', 'help me spec out'.
user-invocable: true
argument-hint: "[optional: one-line topic]"
---

# Brainstorming

Structured pre-implementation design exploration. It turns a vague idea into a written spec through focused, one-at-a-time questions, before any code is written, any plan is made, or any architecture is chosen. The spec is the deliverable, and everything else follows from it.

**No code until the spec is written and approved.**

## When to use

- The user says "I want to build X" but has no written requirements
- A feature request exists as a sentence or two with no detail
- The user asks "how should I build X" before defining what X actually is
- Someone says "let's brainstorm" or "help me figure this out"
- A problem statement exists but the solution space is unexplored

## Quick start

```
/brainstorming user authentication for a SaaS app
/brainstorming migrate our monolith to services
/brainstorming                                     # asks what to explore
```

If `$ARGUMENTS` is provided, use it as the initial topic and skip straight to Phase 1. If no argument, ask: "What idea, feature, or problem would you like to explore?"

---

## Workflow

This skill runs in guided phases. Each phase is a separate file, loaded one at a time. Every phase ends with a gate: wait for user confirmation before you proceed. Do not skip phases or merge them.

| Phase | File | What it covers |
|---|---|---|
| 1 | [Intake](phases/01-intake.md) | Read context, classify maturity, summarize understanding |
| 2 | [Divergence](phases/02-divergence.md) | Expand problem space with one-at-a-time questions across 7 categories |
| 3 | [Convergence](phases/03-convergence.md) | Narrow to concrete scope, lock must-haves and non-goals |
| 4 | [Spec writing](phases/04-spec-writing.md) | Write the full spec from the gathered material, run the quality checklist |
| 5 | [Approval](phases/05-approval.md) | Get explicit user approval, hard-gate implementation |

Start by loading Phase 1. After the user confirms each phase, load the next. Never load more than one phase at a time, and never skip one.

---

## Critical rules

1. **No code until the spec is approved.** That includes pseudocode, scaffolding, and "just a quick example."
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

## Question technique

| Principle | Meaning |
|---|---|
| **One at a time** | One question, one message |
| **Open before closed** | "What" and "why" first; "which" and "would you prefer" later |
| **Challenge assumptions** | When something is stated as obvious, ask what would happen if it were not true |
| **Surface constraints early** | Constraints eliminate solution space - the sooner known, the less rework |
| **Offer options when narrowing** | Present 2-3 concrete choices instead of open-ended questions during convergence |
| **Name the silence** | If an important topic has not come up, ask about it explicitly |

See [question-playbook](references/question-playbook.md) for the full catalog.

---

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Solution jumping | Stay in divergence until goals and constraints are clear |
| Compound questions | One question per message |
| Leading questions | Ask neutral: "What scale needs exist?" not "Should we use microservices?" |
| Premature implementation | Hard-gate: no code until spec is approved |
| Fake consensus | Probe: "Can you walk me through how you'd use this?" |
| Scope creep during convergence | Park in "future considerations", re-lock scope |

See [anti-patterns](references/anti-patterns.md) for the full guide.

---

## Reference files

| Reference | Contents |
|---|---|
| [question-playbook](references/question-playbook.md) | Full catalog of question types with example phrasings |
| [spec-template](references/spec-template.md) | Output template the spec must follow |
| [anti-patterns](references/anti-patterns.md) | Failure modes that derail brainstorming |
| [when-to-exit](references/when-to-exit.md) | Criteria for "done" versus "needs more rounds" |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Spec approved, next step: turn it into a plan and tasks and build it | `spec-driven-development` |
| Spec approved, deliver it end to end from a ticket to a PR | `ticket-delivery` |
| Complex requirements, need stakeholder analysis | `product-manager` role |
| Spec reveals architectural decisions needed | `architect` role |
| Spec approved and small enough to build directly | `tdd`, or the `implementer` agent |
| Acceptance criteria need test plan detail | `qa-engineer` role |
| API design decisions | `api-design` |
| Database schema decisions | `database-design` |

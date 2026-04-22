# Phase 4: Spec Writing

**Progress: Phase 4 of 5**

## Purpose

Produce a written spec from everything gathered in Phases 1-3.

## Steps

1. Write the spec using the [spec template](../references/spec-template.md). Every section is mandatory unless explicitly inapplicable (state "N/A -- [reason]").

   | Section | Contents |
   |---|---|
   | Problem | What is broken, missing, or needed -- stated as a problem, not a solution |
   | Goal | The desired outcome in one or two sentences |
   | Non-goals | What this spec explicitly does NOT cover |
   | Constraints | Technical, time, team, budget, or regulatory limits |
   | Users & stakeholders | Who benefits, who is affected, who decides |
   | Acceptance criteria | Testable conditions that define "done" |
   | Risks | What could go wrong, with likelihood and mitigation |
   | Open questions | Anything still unresolved that does not block the spec |
   | First-cut approach | High-level direction (not a design, not architecture) |

2. Run the quality checklist before presenting:
   - [ ] Problem is stated as a problem, not a solution
   - [ ] Goal is concrete and outcome-oriented
   - [ ] Non-goals explicitly exclude at least one plausible scope item
   - [ ] Constraints are real limits, not preferences
   - [ ] Every acceptance criterion is testable
   - [ ] Risks include at least one non-obvious risk
   - [ ] Open questions are genuinely open
   - [ ] First-cut approach describes shape, not implementation
   - [ ] Spec is understandable by an outsider
   - [ ] No internal contradictions

## Rules

- The spec must be understandable by someone who was not in the conversation
- No implementation details -- the spec describes WHAT, not HOW
- No technology choices unless they are genuine constraints
- Acceptance criteria must be testable
- Scale depth to complexity

## Gate

**Advances when:** The spec is complete, passes the quality checklist, and is ready for user review.
**Returns to this phase when:** The quality checklist reveals gaps.

Present the full spec and ask: "Does this spec accurately capture what you want to build? Reply **approve** to proceed, or tell me what needs to change."

Do NOT proceed to Phase 5 until this question is asked.

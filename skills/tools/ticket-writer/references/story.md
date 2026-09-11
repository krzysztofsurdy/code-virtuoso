# Story

A story captures one piece of user-visible value that a team can deliver inside a sprint. The test is simple: after the story is done, some real person can do something they could not do before.

## Contents

- [Required fields](#required-fields)
- [Optional fields](#optional-fields)
- [The INVEST checklist](#the-invest-checklist)
- [Acceptance criteria in Given/When/Then](#acceptance-criteria-in-givenwhenthen)
- [Questionnaire](#questionnaire)
- [Output template](#output-template)
- [Quality checks](#quality-checks)
- [Common anti-patterns](#common-anti-patterns)

## Required fields

| Field | Purpose |
|---|---|
| Title | Short, imperative. Names the capability the user gains. |
| User persona | The concrete role that benefits. "User" is too vague - pick "returning customer", "admin", "first-time visitor". |
| User story sentence | `As a <persona>, I want <capability>, so that <benefit>.` All three clauses matter. The `so that` forces you to name the real outcome. |
| Acceptance criteria | Observable pass/fail conditions in Given/When/Then form. At least one happy path and one edge or error path. |
| Definition of Done | Team-level checklist the story must meet before it closes (tests, docs, review, deployed). |

## Optional fields

| Field | When to include |
|---|---|
| Parent epic link | Whenever the story rolls up to an epic (almost always) |
| Priority | When the backlog is large enough that order matters |
| Estimate | After the team refines it. Do not pre-fill from the reporter's guess |
| Technical notes | When the implementation has a non-obvious constraint (e.g., must reuse a specific service) |
| Dependencies | When other tickets must land first |
| UX / design link | When a mock or prototype exists |

## The INVEST checklist

Walk through every story before it leaves refinement.

| Letter | Meaning | Failure smell |
|---|---|---|
| Independent | Can be built without waiting on another story | "Blocked by" appears on three sibling stories |
| Negotiable | The how is open for discussion | The title names a specific class or framework |
| Valuable | A real user notices the change | The benefit clause is empty or circular |
| Estimable | The team can ballpark the effort | Refinement ends with "we need another spike" |
| Small | Fits comfortably in one sprint | Acceptance criteria list has ten items |
| Testable | A reviewer can verify it objectively | Criteria say "works well" or "is fast" |

If a story fails any letter, reshape it before committing the ticket.

## Acceptance criteria in Given/When/Then

Keep each scenario focused on one path. Avoid nesting `And` clauses beyond two or three. If the setup gets complex, the story is doing too much.

Pattern:

```
Scenario: <short descriptive name>
  Given <precondition>
  And <additional precondition>
  When <action performed by the persona>
  Then <observable outcome>
  And <additional observable outcome>
```

Guidelines:

- Start preconditions from the persona's point of view, not the database state.
- Put the action in the persona's hands ("the customer submits the form"), not the system's.
- Assert outcomes the persona can see or that an external observer can verify, not private implementation state.
- Cover at least one non-happy path (invalid input, empty state, permission denied).

## Questionnaire

Ask these in this order. Batch items 1-3 in a single prompt when the tool supports it.

1. **Persona**: who benefits? (free text; offer common ones if the project has them)
2. **Capability**: what can they do after this ships? (free text, one sentence)
3. **Benefit**: why does it matter to them? (free text, one sentence)
4. **Happy path acceptance**: describe the main success flow (free text, converted to Given/When/Then)
5. **Edge or error path**: pick one scenario: invalid input / empty state / permission denied / concurrency / timeout / other (free text)
6. **Parent epic**: link or "none"
7. **Priority**: P0 / P1 / P2 / P3 / skip
8. **Notes or constraints**: free text, optional

## Output template

```markdown
# <Imperative title, e.g. "Add password reset via email">

## User Story
As a <persona>, I want <capability>, so that <benefit>.

## Acceptance Criteria

**Scenario: <happy path name>**
- Given <precondition>
- When <action>
- Then <outcome>

**Scenario: <edge or error path name>**
- Given <precondition>
- When <action>
- Then <outcome>

## Definition of Done
- [ ] Code merged to main branch
- [ ] Automated tests cover all acceptance scenarios
- [ ] Documentation updated where applicable
- [ ] Reviewed by at least one peer
- [ ] Deployed to the staging environment
- [ ] Product owner has accepted the demo

## Notes
<Technical constraints, links to mocks, dependencies - omit if empty>

## Links
- Parent epic: <link or placeholder>
- Design: <link or placeholder>
- Depends on: <list or placeholder>
```

## Quality checks

Before handing the ticket over, check that:

- The title is imperative and names a user capability, not an internal component.
- Every acceptance criterion is observable from outside the system.
- No acceptance criterion uses the words "properly", "correctly", "well", or "fast" without a measurable threshold.
- The story fits in a sprint. If unsure, split it.
- The `so that` clause names a real user or business benefit, not a restatement of the capability.

## Common anti-patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| "As a user, I want the system to be fast" | Not testable, no persona | Name the persona and set a measurable threshold |
| Acceptance criteria names a class or file | Leaks implementation into the spec | Describe observable behaviour instead |
| Five happy paths, no edge cases | Misses real-world failure | Add at least one non-happy scenario |
| Story depends on three others | Violates Independent | Resequence or merge |
| "Implement the payment module" | That's an epic, not a story | Break it into sprint-sized stories |

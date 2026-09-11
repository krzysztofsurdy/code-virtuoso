# Issue

An issue is the catch-all ticket type for work that is not a user story, a bug, or part of an epic or initiative. Use it for chores, spikes, tech debt, questions, documentation tasks, or maintenance work: anything real that needs tracking but does not fit another type.

## Contents

- [When to use issue](#when-to-use-issue)
- [Required fields](#required-fields)
- [Optional fields](#optional-fields)
- [Sub-type specifics](#sub-type-specifics)
- [Questionnaire](#questionnaire)
- [Output template](#output-template)
- [Quality checks](#quality-checks)
- [Common anti-patterns](#common-anti-patterns)

## When to use issue

| Sub-type | Typical trigger |
|---|---|
| Chore | Housekeeping: upgrade a minor dependency, rotate a credential, clean up stale data. |
| Spike | Time-boxed investigation whose output is knowledge, not shipped code. |
| Tech debt | A known shortcut in the code that should be paid down. |
| Question | A decision the team needs to make, tracked for visibility. |
| Documentation | A standalone doc task: new guide, updated README, ADR write-up. |
| Maintenance | Run a periodic task, rebuild an index, scheduled audit. |

If the work delivers user-visible value, it is a story. If it is a deviation from intended behaviour, it is a bug. If it is much larger than a sprint, it is an epic. Everything else is an issue.

## Required fields

| Field | Purpose |
|---|---|
| Title | Imperative, names the outcome of the issue. |
| Sub-type | Chore / spike / tech debt / question / documentation / maintenance. |
| Description | What the work is and why it is needed. |
| Expected outcome | What exists after the issue closes (artifact, decision, ADR, cleaner code). |

## Optional fields

| Field | When to include |
|---|---|
| Acceptance checklist | When there are multiple concrete sub-outcomes |
| Time box | Mandatory for spikes; optional elsewhere |
| Parent link | If the issue supports a story or epic |
| Priority | When ordering in the backlog matters |
| Dependencies | When other work must complete first |
| Owner | If pre-assigned |

## Sub-type specifics

### Chore

- Describe the target state clearly ("dependency X upgraded to version Y").
- Note any expected side effects (config changes, cache invalidation, migration).
- Include a verification step so the chore is demonstrably done.

### Spike

- Every spike is time-boxed. State the box in hours or days up front.
- Declare the research question in a single sentence.
- Name the artifact the spike produces: a decision memo, a proof of concept commit, an ADR, or a follow-up ticket set.
- Do not use a spike to deliver production code. If the output ends up shippable, convert the spike into a story at the end.

### Tech debt

- Describe the shortcut that exists today and the cost of leaving it.
- Propose the target state, but keep it negotiable.
- If the change is risky, mark a follow-up test strategy.

### Question

- Capture the question, the options on the table, and who needs to weigh in.
- Close the ticket when the decision is recorded (link the ADR or message thread).

### Documentation

- Name the audience and the artifact (README, onboarding guide, ADR, runbook).
- List the topics that must be covered.
- Include an acceptance step where a reader unfamiliar with the system confirms the doc works.

### Maintenance

- Describe the recurring context (quarterly key rotation, weekly index rebuild).
- Record the commands or runbook link needed to execute it.

## Questionnaire

1. **Sub-type**: chore / spike / tech debt / question / documentation / maintenance
2. **Title**: imperative, free text
3. **Description**: what and why, free text
4. **Expected outcome**: what exists when it is done, free text
5. **Time box**: required if spike, optional otherwise
6. **Acceptance checklist**: optional bullet list
7. **Parent link**: optional
8. **Priority**: P0 / P1 / P2 / P3 / skip
9. **Dependencies**: optional

## Output template

```markdown
# <Imperative title>

**Type:** Issue - <sub-type>

## Description
<What needs doing and why.>

## Expected Outcome
<What exists or is decided when this ticket closes.>

## Acceptance
- [ ] <concrete item 1>
- [ ] <concrete item 2>

## Time Box
<Only for spikes: e.g., 2 days>

## Links
- Parent: <link or placeholder>
- Depends on: <list or placeholder>
- Related: <list or placeholder>
```

## Quality checks

- The sub-type is declared and matches the actual work.
- The expected outcome is concrete: a file, a decision, a clean build, a doc.
- If the issue is a spike, the time box is present.
- If the issue is a question, the options and deciders are listed.
- The title is specific enough that a teammate can skim the backlog and understand what the work is.

## Common anti-patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| Using issue when the work is a real story | Hides user-facing value from the backlog | Reclassify as a story |
| "Improve performance" as an issue | No scope, no metric, no exit criteria | Convert to a story or spike with a concrete target |
| Open-ended spike with no time box | A spike can run forever and absorb sprint capacity | Set a time box |
| Question ticket with no deciders named | Sits open waiting for no one | Name the deciders and a response-by date |
| Tech debt ticket listing every smell | Too big to act on | Split by area or by risk |

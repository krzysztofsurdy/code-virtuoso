# Subtask

A subtask is a technical slice of a parent story. It exists so one developer can pick up a concrete, bounded piece of work and finish it in hours to a couple of days. If a subtask can stand on its own without a parent, it is probably a story or an issue in disguise.

## Contents

- [Required fields](#required-fields)
- [Optional fields](#optional-fields)
- [Parent linkage rules](#parent-linkage-rules)
- [How to split a story into subtasks](#how-to-split-a-story-into-subtasks)
- [Acceptance criteria for subtasks](#acceptance-criteria-for-subtasks)
- [Questionnaire](#questionnaire)
- [Output template](#output-template)
- [Quality checks](#quality-checks)
- [Common anti-patterns](#common-anti-patterns)

## Required fields

| Field | Purpose |
|---|---|
| Title | Imperative, names the technical action ("Add database index on orders.customer_id") |
| Parent story link | The story this subtask advances. Without a parent, reclassify. |
| Acceptance criteria | Technical pass/fail conditions. May reference code paths, API responses, or measurable thresholds. |
| Definition of Done | The subtask's own DoD, which is a subset of the parent story's DoD scoped to this slice. |

## Optional fields

| Field | When to include |
|---|---|
| Estimate | When the team estimates at the subtask level (not all do) |
| Technical notes | Approach, libraries, or gotchas |
| Dependencies | Other subtasks or external blockers |
| Assignee | If known at creation time |
| Test plan | When the tests are non-obvious (performance, concurrency, migration) |

## Parent linkage rules

A subtask without a parent story is a warning sign. Enforce these rules:

- Every subtask points to exactly one parent story.
- The parent must be open; closed parents mean the subtask is stale or belongs elsewhere.
- Subtasks do not chain. A subtask should not have its own subtasks; if the work is that deep, the parent is too big.
- A subtask's scope fits inside its parent's scope. Anything outside belongs on a separate ticket.

## How to split a story into subtasks

Pick one axis and stick to it. Mixed axes create overlapping tickets.

| Split axis | Example |
|---|---|
| Layer | Database migration, API endpoint, UI component |
| Capability | Happy path first, then validation, then error handling |
| Platform | Web implementation, mobile implementation |
| Acceptance criterion | One subtask per acceptance scenario |

Target: 2-5 subtasks per story. More than 5 usually means the story is too large; fewer than 2 means no split is warranted.

## Acceptance criteria for subtasks

Subtask criteria can describe code-level or system-level behaviour, which is the main difference from stories:

- "Endpoint `POST /api/orders` returns 201 with the created order body when the payload is valid."
- "A failed payment logs a `payment.failed` event and does not mark the order as paid."
- "The migration is reversible via the framework's standard rollback command."

Still write them as observable outcomes, not as activity lists.

## Questionnaire

1. **Parent story**: link or ID (required)
2. **What this subtask covers**: free text, one sentence
3. **Split axis**: layer / capability / platform / acceptance criterion / other
4. **Technical acceptance**: what must be true when it's done? (free text, converted to checklist)
5. **Approach notes**: libraries, services, or patterns to reuse (optional)
6. **Test plan**: unit / integration / manual / none (optional)
7. **Estimate**: hours, points, or skip
8. **Dependencies**: other subtasks or blockers (optional)

## Output template

```markdown
# <Imperative technical title>

## Parent
Story: <link to parent>

## Scope
<One-sentence description of what this slice covers.>

## Technical Acceptance
- [ ] <observable outcome 1>
- [ ] <observable outcome 2>
- [ ] <observable outcome 3>

## Definition of Done
- [ ] Implementation complete
- [ ] Automated tests added and passing
- [ ] Peer review approved
- [ ] No open questions in this ticket

## Approach Notes
<Libraries, patterns, or constraints - omit if empty>

## Test Plan
<Unit / integration / manual steps - omit if trivial>

## Links
- Parent story: <link>
- Depends on: <list or placeholder>
```

## Quality checks

- The subtask has exactly one open parent story.
- The scope is narrower than the parent story's scope.
- Acceptance items are observable (by running a test, hitting an endpoint, or inspecting a log).
- The subtask is sized for one developer and one to two days at most.
- No subtask duplicates another subtask under the same parent.

## Common anti-patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| No parent link | Orphan subtasks drift out of sprint scope | Attach a parent or convert to an issue |
| Subtask larger than the parent | Hierarchy is upside-down | Merge the subtask into the parent, or split parent into stories |
| Multiple subtasks with identical titles | Poor slicing: the split axis was wrong | Redo the split on a single axis |
| Subtask body repeats the parent story verbatim | Wastes reviewer time | Summarise only the technical slice |
| "Refactor the service" as a subtask | Too vague, no observable outcome | Name the specific change and why it is needed |

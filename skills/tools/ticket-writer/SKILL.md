---
name: ticket-writer
description: Interactive tool that writes a ticket of the right type (story, subtask, bug, epic, or initiative) with its own structure and quality checks, ready to paste into any tracker. Use when asked to write a ticket, draft a user story, file a bug, or scope an epic.
user-invocable: true
argument-hint: "[optional: type - story, subtask, issue, bug, epic, initiative]"
---

# Ticket writer

Pick the right ticket type, then fill in only the fields that type needs. A story is not a bug, and an epic is not an initiative. Each type has its own audience, scope, and definition of done. Mixing them produces vague tickets that nobody can act on and that bloat the backlog.

## Core Principles

| Principle | Meaning |
|---|---|
| **Type drives structure** | The type decides the required fields. Never use a single template for everything |
| **Outcomes over outputs** | Describe the change the work creates, not the activity performed |
| **Small enough to finish** | Stories and subtasks fit a sprint; epics fit a quarter; initiatives span multiple quarters |
| **Testable acceptance** | Every story, subtask, and bug has acceptance criteria that a reviewer can verify |
| **Context, not prose** | Prefer tables, lists, and labelled sections over paragraphs, because readers skim |
| **One ask per ticket** | If a ticket has two unrelated goals, split it |

---

## Type hierarchy and selection

Tickets form a hierarchy. Pick the highest level where the work still has a single, coherent purpose.

```
Initiative  (multi-quarter strategic outcome)
  Epic      (quarter-scale goal, one product area)
    Story   (sprint-scale user-visible value)
      Subtask  (implementation slice of a story)
    Bug     (defect against current behaviour)
    Issue   (anything else - chore, spike, question)
```

### When to use each type

| Type | Audience | Scope | Typical duration | Key question |
|---|---|---|---|---|
| **Initiative** | Execs, product leadership | Cross-team strategic goal | 1-4 quarters | What outcome do we want for the business or users? |
| **Epic** | Product, engineering, design | Single product area, multiple stories | 1 quarter | What capability or experience are we delivering? |
| **Story** | Dev team, QA, PM | One user-facing change | Fits in a sprint | As a [user], what can I now do? |
| **Subtask** | One developer | Technical slice of a story | Hours to 1-2 days | What specific implementation step does this cover? |
| **Bug** | Dev team, QA | A deviation from intended behaviour | Fix-sized | What is broken, and how do I reproduce it? |
| **Issue** | Dev team | Chore, spike, question, tech debt, docs | Variable | What needs attention that isn't user-facing work? |

### Type decision tree

1. Is this a deviation from intended behaviour? -> **Bug**
2. Is this a strategic goal spanning multiple teams or quarters? -> **Initiative**
3. Is this a large body of work that needs to be broken down but belongs to one product area? -> **Epic**
4. Is this user-visible value that fits in a sprint? -> **Story**
5. Is this an implementation slice of an existing story? -> **Subtask**
6. None of the above (chore, spike, investigation, tech debt, question)? -> **Issue**

---

## Workflow

### Phase 1: Type selection

If the user provided a type as an argument, use it. Otherwise present a selectable menu (use `AskUserQuestion` or the platform's equivalent interactive prompt) listing the six types with their one-line descriptions from the table above. Never dump the full table as plain text. Keep the menu compact.

If the user's intent is clear from context (e.g., they said "write a bug report" or "create an epic for checkout redesign"), skip the menu and confirm the inferred type with a single yes/no prompt.

### Phase 2: Load the type-specific reference

Read the matching reference file for the selected type:

| Type | Reference |
|---|---|
| Story | [references/story.md](references/story.md) |
| Subtask | [references/subtask.md](references/subtask.md) |
| Issue | [references/issue.md](references/issue.md) |
| Bug | [references/bug.md](references/bug.md) |
| Epic | [references/epic.md](references/epic.md) |
| Initiative | [references/initiative.md](references/initiative.md) |

Each reference contains:
- The required fields
- The optional fields
- A field-by-field questionnaire (questions, options, follow-ups)
- The output template
- Quality checks specific to that type

### Phase 3: Run the Questionnaire

Ask only the questions the reference lists for the selected type. Rules:

1. **Batch compatible questions** (3-4 per prompt) when using an interactive menu tool. Use free-text prompts only when the answer is truly free-form (title, description, reproduction steps).
2. **Skip optional fields silently** if the user says "skip" or leaves them blank. Do not add empty placeholders.
3. **Follow up on ambiguous answers.** If the user says "it's slow", ask "slow compared to what, and by how much?"
4. **Never invent facts.** If the user cannot provide environment info, reproduction steps, or metrics, leave those fields out and note the gap in a `## Open Questions` section rather than fabricating values.

### Phase 4: Assemble the ticket

Use the type's output template. Apply these formatting rules to every type:

- **Title:** Imperative mood for stories/subtasks/issues ("Add password reset via email"), descriptive for bugs ("Payment confirmation email not sent after successful charge"), outcome-oriented for epics/initiatives ("Reduce checkout abandonment by 30%").
- **Body:** Markdown with section headings. No emojis unless the user explicitly requests them.
- **Labels:** Suggest labels based on type and content (e.g., `bug`, `severity:high`, `area:checkout`).
- **Links:** Leave placeholders for parent epic / related tickets / PRs rather than inventing IDs.

### Phase 5: Quality check

Before showing the final output, run the checks listed in the type's reference file. Common failures to catch:

| Symptom | Fix |
|---|---|
| Acceptance criteria describe implementation ("implement X service") | Rewrite in terms of observable outcomes ("when user does X, system does Y") |
| Bug has no steps to reproduce | Mark as "Open Questions" and ask the user to provide them |
| Epic has no success metric | Add a metric or downgrade to a story |
| Story doesn't name a user ("we need to...") | Rewrite with a concrete persona ("As a returning customer, I want...") |
| Initiative lists features instead of outcomes | Reframe key results as measurable changes, not shipped features |
| Subtask is larger than its parent story | Split the story or merge the subtasks |

### Phase 6: Deliver

Show the final ticket to the user in a code block so they can copy-paste it. Then offer:
1. Edit a field
2. Change the type (if the content no longer fits)
3. Write a related ticket (e.g., a story under the epic just written)
4. Done

---

## Quick reference: field matrix

Which fields are required (R), optional (O), or not used (-) per type.

| Field | Story | Subtask | Issue | Bug | Epic | Initiative |
|---|---|---|---|---|---|---|
| Title | R | R | R | R | R | R |
| User persona | R | - | O | O | O | O |
| User story sentence | R | - | O | - | O | - |
| Problem statement | O | - | O | R | R | R |
| Acceptance criteria (Given/When/Then) | R | R | O | R | O | - |
| Steps to reproduce | - | - | - | R | - | - |
| Expected / actual behaviour | - | - | - | R | - | - |
| Environment | - | - | - | R | - | - |
| Severity | - | - | - | R | - | - |
| Priority | O | O | O | R | O | O |
| Scope / out of scope | O | - | O | - | R | R |
| Success metrics | - | - | - | - | R | R |
| Key results | - | - | - | - | O | R |
| Objective | - | - | - | - | O | R |
| Milestones | - | - | - | - | O | R |
| Parent link | O | R | O | O | O | - |
| Child list | - | - | - | - | O | O |
| Definition of done | R | R | O | R | O | - |
| Technical notes | O | O | O | O | O | - |
| Estimate | O | O | O | O | O | - |
| Dependencies | O | O | O | O | O | O |

---

## Integration with other skills

| Situation | Recommended Skill |
|---|---|
| Writing the PRD that the stories will flow from | `product-manager` |
| Designing the architecture behind an epic | `architect` |
| Writing acceptance criteria and test plans for a story | `qa-engineer` |
| Planning sprints and setting sprint goals | `scrum` |
| Tracking initiatives as part of a delivery plan | `project-manager` |
| Writing the commit and PR for a story once implemented | `pr-message-writer` |
| Kicking off the ticket workflow after writing | `ticket-delivery` |

---

## Reference files

| Reference | Contents |
|---|---|
| [story.md](references/story.md) | User story fields, INVEST checklist, Given/When/Then acceptance criteria, template and example |
| [subtask.md](references/subtask.md) | Subtask fields, parent linkage rules, technical acceptance criteria, Definition of Done guidance |
| [issue.md](references/issue.md) | Generic issue template for chores, spikes, tech debt, questions, and docs tasks |
| [bug.md](references/bug.md) | Bug report fields, severity vs priority matrix, environment capture, reproduction steps |
| [epic.md](references/epic.md) | Epic fields, problem statement, success metrics, in/out of scope, milestones, child stories |
| [initiative.md](references/initiative.md) | Initiative fields, OKR alignment, objective and key results, outcome vs output, epic roll-up |

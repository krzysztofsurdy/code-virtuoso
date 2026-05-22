# Epic

An epic is a quarter-scale body of work that ties several stories together under one coherent goal. An epic is not "a big story" - it is a container with its own narrative, its own success measure, and its own scope boundaries. If you cannot name how you will know it worked, it is not ready to be an epic.

## Required Fields

| Field | Purpose |
|---|---|
| Title | Outcome-oriented ("Reduce checkout abandonment"), not activity-oriented ("Refactor checkout"). |
| Problem statement | What is wrong or missing today, stated in user and business terms. |
| Goal | What will be true when the epic closes. |
| Success metrics | Measurable outcomes that prove the goal was reached. |
| Scope | The user journeys, surfaces, or capabilities included. |
| Out of scope | Things people might assume are included but are not. Being explicit here prevents drift. |

## Optional Fields

| Field | When to include |
|---|---|
| Parent initiative | When the epic rolls up to a broader strategic push |
| Key stakeholders | Product owner, tech lead, design lead, exec sponsor |
| Milestones | Useful when the epic has internal phases or dependent releases |
| Child stories | Start as a placeholder list; grow as stories are refined |
| Assumptions | What must remain true for this plan to work |
| Risks | What could derail it and what the mitigation is |
| Dependencies | Other teams, platforms, or external contracts |
| Rollout plan | Feature flagging, phased release, kill-switch |
| Budget or capacity | If constrained |

## Writing the Problem Statement

The problem statement sets up everything else. Keep it to one short paragraph structured around three questions:

1. **What is happening today?** Describe the current state in user terms, ideally with a number ("50% of mobile visitors abandon the checkout at the shipping step").
2. **Why is it a problem?** Name the cost, whether it is revenue, trust, support load, or strategic position.
3. **What changes if we solve it?** Preview the target state without prescribing the solution.

A common failure mode is to write a goal statement dressed up as a problem ("We need to improve checkout"). Push past it by asking what is wrong now.

## Picking Success Metrics

Pick outcome metrics, not output metrics. A feature shipped is an output; a change in user behaviour is an outcome.

| Good metric | Bad metric |
|---|---|
| Mobile checkout completion rises from 50% to 70% | Mobile checkout redesign is launched |
| Support tickets about billing drop by 40% | Billing FAQ is updated |
| p95 signup-to-first-action drops from 3 days to 1 day | New onboarding emails are sent |

Guidelines:

- One primary metric and at most two counter-metrics (guardrails).
- Include the baseline and the target. A metric with no baseline is aspirational, not measurable.
- State the measurement window ("measured over the 30 days after rollout").
- If a metric cannot be measured with the current instrumentation, add a prerequisite story to add it.

## Scope and Out of Scope

Both lists are required. The out-of-scope list is where most of the alignment value lives - it prevents scope creep during execution.

Example:

```
In scope:
- Web checkout flow (desktop and mobile)
- Address autocomplete on shipping step
- New progress indicator component

Out of scope:
- Apple Pay / Google Pay integration
- Logged-out guest checkout
- Back-office address validation rules
```

When a new request arrives mid-epic, the out-of-scope list is the first place to check. If the request is not on either list, the product owner makes an explicit scope call before it is accepted.

## Breaking an Epic into Stories

An epic typically contains five to twenty stories. Use these slicing patterns:

| Slice | Example |
|---|---|
| User journey step | Shipping, payment, confirmation - each its own story |
| User segment | New customer vs returning customer flows |
| Platform | Web, iOS, Android |
| Capability layer | Data model, API, UI, analytics |
| Happy path first | Ship the 80% path, then add edge cases as follow-up stories |

Write the first two or three stories at epic creation time to sanity-check scope. Refine the rest lazily.

## Milestones

Milestones are optional but useful when the epic has internal phases or external dependencies. Use them for demoable checkpoints, not busywork gates.

Examples:

- "Beta available to 5% of mobile traffic"
- "Analytics instrumentation live and validated"
- "Legal review complete for PII changes"

## Questionnaire

1. **Title** - outcome-oriented, free text
2. **Problem statement** - current state, cost, target state, free text
3. **Goal** - one sentence, free text
4. **Primary success metric** - name, baseline, target, window
5. **Counter-metrics / guardrails** - optional, up to two
6. **In scope** - bullet list
7. **Out of scope** - bullet list
8. **Parent initiative** - optional link
9. **Stakeholders** - product, engineering, design, exec sponsor
10. **Milestones** - optional, dated
11. **Initial child stories** - rough list; leave room to refine
12. **Assumptions** - optional
13. **Risks** - optional, with mitigation
14. **Dependencies** - optional
15. **Rollout plan** - optional

## Output Template

```markdown
# <Outcome-oriented title>

## Problem
<What is happening today, why it hurts, what changes when we fix it.>

## Goal
<One sentence describing the end state.>

## Success Metrics
- Primary: <metric> - baseline <x>, target <y>, measured over <window>
- Guardrail: <metric that must not degrade>

## In Scope
- <item>
- <item>

## Out of Scope
- <item>
- <item>

## Stakeholders
- Product owner: <name>
- Tech lead: <name>
- Design lead: <name>
- Exec sponsor: <name or omit>

## Milestones
- <date or sequence>: <milestone>
- <date or sequence>: <milestone>

## Child Stories
- <story title or link>
- <story title or link>

## Assumptions
<List or omit>

## Risks
- <risk> - mitigation: <>

## Dependencies
<List or omit>

## Rollout Plan
<Phased release, flagging, kill-switch - omit if trivial>

## Links
- Parent initiative: <link or placeholder>
- Related epics: <list>
```

## Quality Checks

- The title names an outcome, not an activity.
- The problem statement is grounded in current-state data where available.
- Success metrics have baselines, targets, and measurement windows.
- At least one item is listed in both "In scope" and "Out of scope".
- A tech lead could start breaking this into stories without another meeting.
- The epic is sized for a quarter. Anything multi-quarter belongs in an initiative.

## Common Anti-Patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| Title names a refactor or tech effort | Hides user or business value | Reframe around the outcome the effort enables |
| "Launch X" as the only success metric | That is an output, not an outcome | Measure user or business impact, not delivery |
| Missing out-of-scope list | Invites scope creep mid-quarter | Add explicit exclusions |
| Twenty stories, none refined | Feels like planning but delivers nothing | Refine the first few stories to pressure-test scope |
| Epic lives for six months | Likely an initiative in disguise | Split into initiative + multiple epics |
| Problem statement is the goal restated | No diagnosis | Describe current state with numbers |

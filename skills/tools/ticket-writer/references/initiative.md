# Initiative

An initiative is a multi-quarter strategic push that groups several epics under one business or product objective. Where an epic answers "what capability are we delivering?", an initiative answers "what change in the business or user behaviour are we trying to cause?". Initiatives live closer to strategy than to execution.

## Required Fields

| Field | Purpose |
|---|---|
| Title | Names the outcome the business wants ("Become the default grocery app in the Nordics"). |
| Objective | One crisp sentence describing the desired end state. Qualitative and ambitious. |
| Key results | Two to five measurable outcomes that, if all hit, prove the objective was achieved. |
| Problem statement | Why this matters now: the strategic rationale, the evidence, and the risk of not doing it. |
| Scope | The product areas, markets, or surfaces the initiative covers. |
| Out of scope | Things that could be assumed but are not. |
| Horizon | The quarters the initiative spans. |

## Optional Fields

| Field | When to include |
|---|---|
| Child epics | Start as a placeholder list; grow as the initiative plans out |
| Executive sponsor | When cross-team coordination is needed |
| Stakeholders | Product, engineering, design, finance, legal, marketing |
| Guiding principles | Constraints the plan must respect (privacy, accessibility, latency budget) |
| Dependencies | Other initiatives, platform investments, external partners |
| Assumptions | What must remain true for the plan to hold |
| Risks | Strategic risks with mitigation plans |
| Budget and staffing | Headcount, capacity, external spend |
| Check-in cadence | How often progress is reviewed |

## Objective and Key Results

Initiatives are the right level to anchor OKRs. Keep them aligned but not identical.

**Objective**
- One sentence.
- Qualitative and memorable.
- Describes the end state, not the work.
- Avoid numbers - those live in the key results.

**Key results**
- Two to five per objective.
- Each is a measurable change in behaviour, adoption, retention, revenue, cost, or risk.
- Each has a baseline, a target, and a measurement window.
- At least one should be a guardrail or counter-metric (something that must not get worse while the others move).

Examples of bad vs good key results:

| Bad | Good |
|---|---|
| Launch the new mobile app | Weekly active mobile users rise from 20% to 35% of the total base by end of Q3 |
| Improve reliability | p95 API latency stays under 250 ms while error rate drops from 1.2% to 0.3% |
| Grow revenue | Monthly recurring revenue in the SMB segment grows from $400k to $600k by Q4 |

## Outcome over Output

Initiatives live or die on this distinction. Outputs are things the team ships. Outcomes are things that change because of what the team ships. A dashboard shipped is an output; a support team resolving tickets twice as fast is an outcome.

Heuristics:

- If a key result can be completed by checking a delivery box, it is an output. Rewrite it.
- If a key result depends on real users doing something different, it is an outcome.
- When the direct outcome is hard to measure, use a leading indicator and name it as such.

## Scope and Horizon

Initiatives usually span one to four quarters. Beyond that, you are looking at a strategic theme, not an initiative.

Scope examples:

```
In scope:
- Core ordering flow on web and mobile
- Search and browse experience
- Post-purchase notifications

Out of scope:
- Back-office fulfilment tooling
- B2B wholesale channel
- International expansion beyond the current three markets
```

The out-of-scope list protects the initiative from absorbing adjacent work during planning reviews.

## Child Epics

An initiative typically contains three to ten epics. A few guidelines:

- Start with three epic placeholders that represent the biggest bets. Their titles should read like the pillars of a plan.
- Each child epic should contribute to at least one key result. If an epic does not, either add a key result it supports or drop the epic.
- Keep the children at the same altitude. If one of them feels much smaller than the others, it is probably a story under a different epic.

## Questionnaire

1. **Title** - outcome-oriented, free text
2. **Objective** - one sentence, qualitative, free text
3. **Key results** - two to five, each with metric, baseline, target, window
4. **Problem statement** - strategic rationale, free text
5. **Horizon** - quarters covered (e.g., Q3 2026 - Q2 2027)
6. **In scope** - bullet list
7. **Out of scope** - bullet list
8. **Executive sponsor** - optional
9. **Stakeholders** - optional, roles and names
10. **Guiding principles** - optional
11. **Initial child epics** - three to five placeholders
12. **Dependencies** - optional
13. **Assumptions** - optional
14. **Risks** - optional, with mitigation
15. **Budget and staffing** - optional
16. **Check-in cadence** - optional

## Output Template

```markdown
# <Outcome-oriented title>

## Objective
<One sentence describing the end state.>

## Key Results
1. <KR - metric, baseline, target, window>
2. <KR - metric, baseline, target, window>
3. <KR - metric, baseline, target, window>

## Problem
<Strategic rationale: why now, what the evidence says, what happens if we do not act.>

## Horizon
<Start quarter - end quarter>

## In Scope
- <item>

## Out of Scope
- <item>

## Stakeholders
- Executive sponsor: <name or omit>
- Product lead: <name>
- Engineering lead: <name>
- Design lead: <name>
- Other: <name + role>

## Guiding Principles
<Constraints the plan must respect - omit if none>

## Child Epics
- <epic title or link>
- <epic title or link>
- <epic title or link>

## Dependencies
<Other initiatives, platforms, partners - omit if none>

## Assumptions
<List or omit>

## Risks
- <risk> - mitigation: <>

## Budget and Staffing
<Headcount, spend, external partners - omit if not applicable>

## Check-ins
<Cadence and forum - omit if standard>
```

## Quality Checks

- The objective is qualitative and forward-looking.
- Every key result is a behaviour or business change, not a shipped feature.
- Each key result has a baseline, a target, and a window.
- At least one key result is a guardrail.
- The child epics, taken together, plausibly move the key results.
- The scope is not larger than four quarters - if it is, split it.
- An exec reading only the title and objective can guess what the team is going to build.

## Common Anti-Patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| Key result = "launch feature X" | That is an output, the initiative could ship it and fail | Reframe as a behaviour change |
| Objective loaded with numbers | Makes the objective unmemorable and conflates it with a KR | Move numbers to key results |
| No guardrails | The team might win the headline metric while hurting another | Add a counter-metric |
| Ten child epics, all urgent | Real prioritisation has not happened | Cut to three to five; push the rest to later cycles |
| Initiative runs more than a year | Becomes a theme, not a plan | Split into sequenced initiatives |
| No out-of-scope list | Planning reviews keep expanding scope | Add explicit exclusions |
| Objective restates the team's charter | Not actionable | Name a specific change the initiative will cause |

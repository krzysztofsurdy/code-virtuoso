---
name: scrum
description: Scrum framework fundamentals: roles, events, artifacts, sprint goal writing, and retrospectives. Use to plan a sprint, write a sprint goal, or facilitate a Scrum event.
allowed-tools: Read Grep Glob Bash
user-invocable: true
disable-model-invocation: true
---

# Scrum

A lightweight framework for delivering complex products through iterative, incremental work. Scrum is founded on empiricism (knowledge from experience) and lean thinking (reduce waste, focus on essentials). Teams work in fixed-length iterations called Sprints, inspecting and adapting continuously.

## Three pillars

| Pillar | Meaning |
|---|---|
| **Transparency** | The process and work must be visible to those performing and receiving the work |
| **Inspection** | Scrum artifacts and progress must be inspected frequently to detect problems |
| **Adaptation** | When inspection reveals deviation, adjust immediately |

## Five values

Commitment, Focus, Openness, Respect, Courage. The Scrum Team commits to achieving goals, focuses on Sprint work, is open about challenges, respects each other as capable people, and has courage to do the right thing.

---

## Sprint Goal

The Sprint Goal is the single objective for the Sprint. It is the commitment of the Sprint Backlog. It gives the Scrum Team focus and coherence, so they work together rather than on separate initiatives.

### Quick template (Focus / Impact / Confirmation)

```
Our focus is on [outcome].
We believe it delivers [impact] to [stakeholder/customer].
This will be confirmed when [measurable event happens].
```

**Example:** "Our focus is on sending a basic notification email containing a report link. We believe it delivers confidence to our finance team. This will be confirmed when we have an email in an inbox with a working link."

### SMART criteria

| Criterion | Applied to Sprint Goals |
|---|---|
| **Specific** | Define exactly what the team will achieve, not a vague direction |
| **Measurable** | Include a way to confirm completion objectively |
| **Achievable** | The team can realistically deliver within the Sprint timebox |
| **Relevant** | Connects to the Product Goal and delivers stakeholder value |
| **Time-bound** | Bounded by the Sprint duration |

### Anti-patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Task list disguised as goal | "Complete stories #101, #102, #103" provides no strategic focus | State the outcome those stories achieve |
| Vague aspiration | "Improve the system" gives no direction or measurable outcome | Be specific: what improves, for whom, how will you know |
| Multiple unrelated objectives | "Build auth AND redesign dashboard" splits focus | Pick one objective; if truly independent, they belong in separate sprints |
| Dictated by PO alone | Team has no ownership or buy-in | Craft the goal collaboratively during Sprint Planning |
| Never referenced after planning | Goal becomes forgotten wallpaper | Reference the goal daily in the Daily Scrum |
| Too ambitious | Team cannot deliver, loses motivation | Base on actual velocity and capacity |

See [Sprint Goals Reference](references/sprint-goals.md) for 5 complete templates with examples and the FOCUS evaluation checklist.

---

## Scrum Events

All events are timeboxed. Shorter Sprints use proportionally shorter event timeboxes. Every event is a chance to inspect and adapt.

| Event | Timebox (1-month Sprint) | Purpose | Key Output |
|---|---|---|---|
| **Sprint** | Max 1 month | Container for all work and events | Usable Increment |
| **Sprint Planning** | Max 8 hours | Define the Sprint Goal and Sprint Backlog | Sprint Goal + selected backlog items + delivery plan |
| **Daily Scrum** | 15 minutes | Inspect progress toward Sprint Goal | Actionable plan for next 24 hours |
| **Sprint Review** | Max 4 hours | Inspect the Increment and adapt the Product Backlog | Feedback, updated Product Backlog |
| **Sprint Retrospective** | Max 3 hours | Inspect the team's process and plan improvements | Improvement actions for next Sprint |

### Sprint Planning: three topics

1. **Why is this Sprint valuable?** - Product Owner proposes how to increase value; team defines Sprint Goal
2. **What can be done this Sprint?** - Developers select Product Backlog items based on capacity and velocity
3. **How will the chosen work get done?** - Developers decompose items into tasks (typically one day or less)

See [Scrum Events Reference](references/scrum-events.md) for detailed facilitation guidance, formats, and tips.

---

## Scrum Roles

| Role | Accountability | Key Responsibilities |
|---|---|---|
| **Scrum Master** | Scrum framework effectiveness | Facilitates events, removes impediments, coaches team and organization on Scrum |
| **Product Owner** | Product value maximization | Manages Product Backlog, communicates Product Goal, ensures backlog transparency |
| **Developers** | Creating a usable Increment each Sprint | Self-managing, cross-functional, accountable for quality and Definition of Done |

The Scrum Team is a small, cohesive unit (typically 10 or fewer people) with no sub-teams or hierarchies. Everyone is accountable for creating a valuable, useful Increment every Sprint.

See [Scrum Roles Reference](references/scrum-roles.md) for detailed responsibilities and facilitation techniques.

---

## Scrum Artifacts

Each artifact contains a commitment that provides transparency and focus:

| Artifact | Commitment | Purpose |
|---|---|---|
| **Product Backlog** | Product Goal | Ordered list of everything needed to improve the product |
| **Sprint Backlog** | Sprint Goal | Selected items + Sprint Goal + delivery plan |
| **Increment** | Definition of Done | Concrete stepping stone toward the Product Goal |

### Definition of Done

A formal description of the state of the Increment when it meets quality standards. If a Product Backlog item does not meet the Definition of Done, it cannot be released or presented at the Sprint Review. It returns to the Product Backlog for future consideration.

The Definition of Done creates transparency by giving everyone a shared understanding of what "complete" means. It is a minimum quality bar - individual items may have additional acceptance criteria.

---

## Sprint Goal quality checklist

Before committing to a Sprint Goal, verify:

- [ ] **Single objective**: one clear outcome, not a list of tasks
- [ ] **Outcome-oriented**: describes what the team achieves, not what they do
- [ ] **Measurable**: includes a way to confirm completion
- [ ] **Achievable**: realistic given team capacity and velocity
- [ ] **Valuable**: connects to the Product Goal and matters to stakeholders
- [ ] **Collaboratively crafted**: team contributed, not just the PO
- [ ] **Visible**: will be referenced daily and displayed prominently
- [ ] **Flexible execution**: the goal is fixed but the work to achieve it can adapt

---

## Integration with Team Roles

| Situation | Recommended Skill |
|---|---|
| Writing user stories with acceptance criteria | `testing` |
| Planning API work in a sprint | `api-design` |
| Sprint involves architecture decisions | `clean-architecture` |
| Sprint retrospective reveals code quality issues | `refactoring` |

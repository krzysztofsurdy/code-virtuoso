# Question playbook

Catalog of question types organized by brainstorming phase and purpose. Each category includes the intent behind the question type, example phrasings, and guidance on when to use open or closed variants.

## Contents

- [General principles](#general-principles)
- [Goal-seeking questions](#goal-seeking-questions)
- [User and stakeholder questions](#user-and-stakeholder-questions)
- [Constraint-surfacing questions](#constraint-surfacing-questions)
- [Scope-narrowing questions](#scope-narrowing-questions)
- [Risk-surfacing questions](#risk-surfacing-questions)
- [Success-criteria questions](#success-criteria-questions)
- [Assumption-challenging questions](#assumption-challenging-questions)
- [Phase-specific guidance](#phase-specific-guidance)

---

## General principles

- **One question per message.** Never combine two questions into one. Compound questions produce partial answers.
- **Open before closed.** Start each category with exploratory questions ("what," "why," "how"), then narrow with choice questions ("which of these," "would you prefer") only after the space is understood.
- **Follow the energy.** When the user gives a long, enthusiastic answer, follow up on what excited them. When they give a short answer, the topic may be settled, so move on.
- **Name what is missing.** If an important topic has not surfaced naturally, bring it up explicitly rather than hoping the user will volunteer it.

---

## Goal-seeking questions

**Intent**: Define the core problem and desired outcome. Separate the problem from the solution.

### Open (use first)

| Question | When to use |
|---|---|
| "What problem are you trying to solve?" | Opening question for raw ideas |
| "What does success look like when this is done?" | When goals are vague or unstated |
| "Why does this matter now? What changed?" | To understand urgency and motivation |
| "What happens if we do nothing?" | To test whether the problem is real |
| "Who asked for this, and what triggered the request?" | To surface the origin and real stakeholder need |
| "What would change for your users if this worked perfectly?" | To shift focus from feature to outcome |
| "What are you hoping to stop doing once this exists?" | To surface pain points behind feature requests |

### Closed (use to narrow)

| Question | When to use |
|---|---|
| "Is the primary goal [A] or [B]?" | When two goals are competing and need ranking |
| "Is this a new capability, an improvement to an existing one, or a replacement?" | To classify the project type |
| "Does this need to be done by [date], or is the timeline flexible?" | To surface time constraints early |

---

## User and stakeholder questions

**Intent**: Identify who benefits, who is affected, who decides, and what their actual needs are.

### Open

| Question | When to use |
|---|---|
| "Who will use this day-to-day?" | To identify primary users |
| "Who else is affected, even if they never touch it directly?" | To surface secondary stakeholders (ops, support, billing) |
| "What does the typical user know and not know?" | To calibrate complexity and UX assumptions |
| "Are there different types of users with different needs?" | To surface role-based requirements |
| "Who has the final say on whether this is done correctly?" | To identify the approval authority |

### Closed

| Question | When to use |
|---|---|
| "Is this for internal users, external users, or both?" | Early classification |
| "Are the users technical or non-technical?" | To calibrate abstraction level |
| "Is there an existing workflow this replaces, or is this entirely new?" | To understand migration needs |

---

## Constraint-surfacing questions

**Intent**: Uncover limits that eliminate solution space. Technical, time, budget, team, regulatory, or organizational constraints.

### Open

| Question | When to use |
|---|---|
| "What constraints exist that would rule out certain approaches?" | General constraint sweep |
| "What does the existing system look like that this has to integrate with?" | For brownfield projects |
| "What technology decisions have already been made that we cannot change?" | To identify locked-in choices |
| "What is the team's current capacity and expertise?" | To match scope to reality |
| "Are there regulatory, compliance, or security requirements?" | For domains like finance, health, government |
| "What is the budget - time, money, or both?" | To set realistic boundaries |
| "What has been tried before, and why did it fail or get abandoned?" | To avoid repeating known failures |

### Closed

| Question | When to use |
|---|---|
| "Does this need to work with [specific system/API/database]?" | When integration points are suspected |
| "Is there a hard deadline, or is this best-effort?" | To distinguish real from aspirational timelines |
| "Can we start from scratch, or must we preserve backward compatibility?" | To determine migration complexity |

---

## Scope-narrowing questions

**Intent**: Distinguish what must be built from what could be built. Draw explicit boundaries.

### Open

| Question | When to use |
|---|---|
| "If you could only ship one thing from this, what would it be?" | To find the core value proposition |
| "What is the minimum version of this that would be useful?" | To define MVP scope |
| "What parts of this could wait for a second phase?" | To create a natural phase boundary |
| "What features are you tempted to include but could live without?" | To surface nice-to-haves the user is attached to |

### Closed

| Question | When to use |
|---|---|
| "Would you rather ship [smaller scope] next week or [larger scope] next month?" | To force a trade-off decision |
| "Is [specific feature] a must-have for the first version?" | To validate individual scope items |
| "Should we explicitly exclude [feature] from this scope?" | To confirm non-goals |

---

## Risk-surfacing questions

**Intent**: Identify what could go wrong, what would block progress, and what the consequences of failure are.

### Open

| Question | When to use |
|---|---|
| "What is the worst thing that could happen if this goes wrong?" | To calibrate risk tolerance |
| "What part of this are you most uncertain about?" | To find the riskiest area |
| "What dependencies does this have on other teams, systems, or timelines?" | To surface external blockers |
| "What assumptions are we making that could turn out to be wrong?" | Direct assumption challenge |
| "If this takes twice as long as expected, what would you cut?" | To test scope resilience |
| "What would make you abandon this project entirely?" | To surface kill criteria |

### Closed

| Question | When to use |
|---|---|
| "Is [specific dependency] definitely available, or is that uncertain?" | To validate a specific assumption |
| "If [specific risk] happens, would you rather [mitigation A] or [mitigation B]?" | To pre-decide risk responses |
| "Is there a fallback plan if the primary approach does not work?" | To check for plan B |

---

## Success-criteria questions

**Intent**: Define measurable, testable conditions that determine whether the project is done and working.

### Open

| Question | When to use |
|---|---|
| "How will you know this is working correctly?" | Fundamental success definition |
| "What would you test first after this is deployed?" | To surface the most important behavior |
| "What numbers or metrics would tell you this was worth building?" | For measurable outcomes |
| "What would a user do to verify this works?" | To think in terms of user actions |
| "What does 'done' mean for this project?" | When completion criteria are ambiguous |

### Closed

| Question | When to use |
|---|---|
| "Is [specific metric] the right way to measure success?" | To validate a proposed criterion |
| "Would you accept [specific trade-off] if it meant shipping sooner?" | To test quality versus speed preferences |
| "Does 'done' include documentation, or just working code?" | To define deliverable scope |

---

## Assumption-challenging questions

**Intent**: Test beliefs that have been stated as facts. Surface hidden assumptions before they become embedded in the spec.

### Techniques

| Technique | Example |
|---|---|
| **Inversion** | "What if the opposite were true? What if users do not want real-time updates?" |
| **Scaling** | "Does this still work with 10x the users? With 100x?" |
| **Removal** | "What if we removed [feature] entirely - what breaks?" |
| **Origin probe** | "Where did the requirement for [X] come from? Is it based on data or intuition?" |
| **Constraint flip** | "You said it must be [X]. What would change if that constraint did not exist?" |
| **Historical challenge** | "Has [assumption] been validated, or is it inherited from a previous project?" |

### When to challenge

- When something is stated as "obvious" or "everyone knows"
- When a requirement sounds like a solution disguised as a need ("we need a message queue" versus "we need reliable async processing")
- When two stated requirements seem to contradict each other
- When the user skips over a topic quickly, as if it is settled

### When not to challenge

- When the user has clearly thought through the topic and has evidence
- When a constraint comes from an authority the user cannot change (legal, regulatory)
- When challenging would feel adversarial rather than collaborative - reframe as curiosity instead

---

## Phase-specific guidance

### During intake (Phase 1)

Stick to goal-seeking and user/stakeholder questions. You are understanding the starting point, not exploring the solution space yet.

### During divergence (Phase 2)

Work through all categories. This is where the full question catalog applies. Spend the most time here. The quality of the spec depends on the quality of the divergence phase.

### During convergence (Phase 3)

Switch to closed and choice questions. The exploration is over. Now you are locking things down. Present options, force trade-offs, confirm boundaries.

### During spec writing (Phase 4)

Ask only gap-filling questions: "I am writing the acceptance criteria for [feature]. Can you confirm that [specific condition] is correct?" These are targeted, specific, and should not open new scope.

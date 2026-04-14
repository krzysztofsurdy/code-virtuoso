---
name: brainstorming
description: Interactive pre-implementation design exploration. Use when the user has a vague idea, feature request, or problem statement but no written spec. Asks focused questions one at a time to surface goals, non-goals, constraints, success criteria, and risks, then produces a written spec and hard-gates implementation until approved. Use before writing any code, before planning, and before answering 'how should I build X'. Triggers: 'I want to build', 'I'm thinking about', 'help me figure out', 'let's brainstorm', 'help me spec out'.
user-invocable: true
argument-hint: "[optional: one-line topic]"
---

# Brainstorming

Structured pre-implementation design exploration. Transforms a vague idea into a written spec through focused, one-at-a-time questioning before any code is written, any plan is created, or any architecture is decided. The spec is the deliverable -- everything else follows from it.

**No code until the spec is written and approved.**

## When to Use

- The user says "I want to build X" but has no written requirements
- A feature request exists as a sentence or two with no detail
- The user asks "how should I build X" before defining what X actually is
- Someone says "let's brainstorm" or "help me figure this out"
- A problem statement exists but the solution space is unexplored
- The user jumps straight to implementation details without stating goals
- A project feels "too simple to need a design" -- it still needs one, just shorter

## Quick Start

```
/brainstorming user authentication for a SaaS app
/brainstorming migrate our monolith to services
/brainstorming                                     # asks what to explore
```

If `$ARGUMENTS` is provided, use it as the initial topic and skip straight to Phase 1. If no argument, ask: "What idea, feature, or problem would you like to explore?" using `AskUserQuestion` (or the agent's equivalent interactive prompt tool).

---

## Phase 1: Intake

**Purpose**: Establish what the user is bringing to the table and what state it is in.

1. Read any provided context -- files, tickets, prior conversations, existing docs
2. Identify what already exists: is this greenfield, an extension, a replacement, or a fix?
3. Classify the input maturity:
   - **Raw idea** -- a sentence or feeling, no structure yet
   - **Rough concept** -- some goals stated, many unknowns remain
   - **Partial spec** -- some sections already defined, gaps need filling
4. Acknowledge what you understood and state what is still unknown

**Output**: One-paragraph summary of the current state, followed by the first question.

**Rules**:
- Do NOT propose solutions during intake
- Do NOT ask more than one question at a time
- Do NOT assume anything the user has not stated

---

## Phase 2: Divergence

**Purpose**: Expand the problem space. Surface goals, users, constraints, edge cases, and risks that the user has not yet considered.

Work through these question categories in order. Ask one question at a time. Skip categories where the answer is already known from Phase 1 context.

| Category | Purpose | Example |
|---|---|---|
| Goal-seeking | Define the core problem and desired outcome | "What does success look like when this is done?" |
| User/stakeholder | Identify who benefits and who is affected | "Who will use this, and what do they need from it?" |
| Constraint-surfacing | Uncover technical, time, budget, or team limits | "What constraints exist that would rule out certain approaches?" |
| Scope-narrowing | Distinguish must-haves from nice-to-haves | "If you could only ship one thing, what would it be?" |
| Risk-surfacing | Identify what could go wrong or block progress | "What is the worst thing that could happen if this goes wrong?" |
| Success-criteria | Define measurable conditions for done | "How will you know this is working correctly?" |
| Assumption-challenging | Test unstated beliefs | "You mentioned X -- is that a hard requirement or an assumption?" |

See [question-playbook](references/question-playbook.md) for the full catalog of question types with example phrasings.

**Rules**:
- One question per message, always
- Open questions before closed questions -- explore before narrowing
- When the user states something as fact, probe whether it is a requirement or an assumption
- Do NOT offer solutions, architectures, or technology choices during divergence
- Track emerging themes and contradictions silently -- surface contradictions as questions, not corrections

**Output**: Running mental model of the problem space (not shown to user yet).

---

## Phase 3: Convergence

**Purpose**: Narrow from the expanded problem space to a concrete, bounded scope.

1. Summarize what you have learned so far in 3-5 bullet points
2. Present the summary to the user and ask: "Does this capture the core of what you want to build?"
3. Resolve any open contradictions by asking the user to choose
4. Confirm explicit non-goals: "To make sure we agree on boundaries -- these are things we are NOT building: [list]. Correct?"
5. Lock the scope: must-haves vs. nice-to-haves vs. out-of-scope

**Rules**:
- Do NOT proceed to Phase 4 with unresolved contradictions
- Do NOT add scope the user did not request
- If the user introduces new scope during convergence, acknowledge it and loop back to the relevant divergence category

**Output**: Agreed scope statement with explicit boundaries.

---

## Phase 4: Spec Writing

**Purpose**: Produce a written spec from everything gathered in Phases 1-3.

Write the spec using the [spec template](references/spec-template.md). Every section is mandatory unless explicitly inapplicable (state "N/A -- [reason]" for skipped sections).

| Section | Contents |
|---|---|
| Problem | What is broken, missing, or needed -- stated as a problem, not a solution |
| Goal | The desired outcome in one or two sentences |
| Non-goals | What this spec explicitly does NOT cover |
| Constraints | Technical, time, team, budget, or regulatory limits |
| Users & stakeholders | Who benefits, who is affected, who decides |
| Acceptance criteria | Testable conditions that define "done" -- use Given/When/Then or equivalent |
| Risks | What could go wrong, with likelihood and mitigation |
| Open questions | Anything still unresolved that does not block the spec |
| First-cut approach | High-level direction (not a design, not architecture -- just the shape of the solution) |

**Rules**:
- The spec must be understandable by someone who was not in the conversation
- No implementation details -- the spec describes WHAT, not HOW
- No technology choices unless they are genuine constraints
- Acceptance criteria must be testable -- "it should feel fast" is not testable; "page loads in under 2 seconds" is
- Scale depth to complexity: a simple feature gets a one-page spec; a system redesign gets a thorough one

**Output**: Complete spec document.

---

## Phase 5: Approval Gate

**Purpose**: Get explicit user approval before anything proceeds.

1. Present the full spec to the user
2. Ask: "Does this spec accurately capture what you want to build? Reply **approve** to proceed, or tell me what needs to change."
3. Wait for explicit approval

**What blocks the gate**:
- User says "change X" or "what about Y" -- loop back to the relevant phase
- Unresolved open questions that the user wants answered first
- User introduces new scope -- return to Phase 2 for that scope, then re-converge

**What advances the gate**:
- User says "approve", "looks good", "ship it", "yes", or equivalent affirmative
- All must-have acceptance criteria are present and testable
- No unresolved contradictions remain

**After approval**:
- The spec is the contract. Implementation must satisfy the acceptance criteria in the spec.
- Hand off to the appropriate next step (planning, architecture, or implementation skill)
- Do NOT write code, scaffold projects, create files, or take any implementation action

---

## Question Technique

Effective brainstorming depends on question quality. Follow these principles:

| Principle | Meaning |
|---|---|
| **One at a time** | Never ask compound questions. One question, one message. |
| **Open before closed** | Start with "what" and "why" questions; narrow with "which" and "would you prefer" later. |
| **Challenge assumptions** | When something is stated as obvious, ask what would happen if it were not true. |
| **Surface constraints early** | Constraints eliminate solution space -- the sooner they are known, the less rework. |
| **Offer options when narrowing** | Present 2-3 concrete choices instead of open-ended "what do you think" during convergence. |
| **Name the silence** | If an important topic has not come up, ask about it explicitly. |

See [question-playbook](references/question-playbook.md) for the full catalog with examples.

---

## Anti-Patterns

Common failure modes that derail brainstorming. See [anti-patterns](references/anti-patterns.md) for the full guide.

| Anti-Pattern | What Goes Wrong | Fix |
|---|---|---|
| Solution jumping | Proposing architecture before understanding the problem | Stay in divergence until goals and constraints are clear |
| Compound questions | Asking 3 things at once, getting a vague answer | One question per message, always |
| Leading questions | "Don't you think we should use microservices?" | Ask neutral: "What scale and deployment needs exist?" |
| Premature implementation | Writing code or scaffolding before spec approval | Hard-gate: no code until spec is approved |
| Fake consensus | User says "sure" without engaging -- spec has gaps | Probe: "Can you walk me through how you'd use this?" |
| Scope creep during convergence | New ideas keep appearing, scope never locks | Acknowledge, park in "future considerations", re-lock scope |
| Skipping for "simple" projects | "It's just a small thing, no need for a spec" | Every project gets a spec -- simple ones just get a short spec |

---

## Approval Gate Details

The approval gate is the hardest rule in this skill. No exceptions.

**Before approval, you may**:
- Ask questions
- Summarize findings
- Write and revise the spec
- Discuss trade-offs at a conceptual level

**Before approval, you must NOT**:
- Write any code (not even pseudocode presented as "just an example")
- Create project files or directories
- Choose specific technologies, libraries, or frameworks
- Produce architecture diagrams or system designs
- Invoke any implementation, planning, or code-generation skill

**After approval, you should**:
- Hand off the spec to the next appropriate workflow (planning, architecture, implementation)
- The spec becomes the source of truth for that workflow

---

## Quality Checklist

Before presenting the spec for approval:

- [ ] Problem is stated as a problem, not a solution
- [ ] Goal is concrete and outcome-oriented
- [ ] Non-goals explicitly exclude at least one plausible scope item
- [ ] Constraints are real limits, not preferences
- [ ] Every acceptance criterion is testable by a human or automated test
- [ ] Risks include at least one non-obvious risk
- [ ] Open questions are genuinely open (not things you could resolve by asking)
- [ ] First-cut approach describes shape, not implementation
- [ ] Spec is understandable by someone who was not in the brainstorming session
- [ ] No internal contradictions between sections
- [ ] Depth is proportional to complexity -- not over-specified, not under-specified

---

## Critical Rules

1. **No code until the spec is approved.** This is the iron law. Not pseudocode, not scaffolding, not "just a quick example." The spec is the first deliverable, period.

2. **One question per message.** Compound questions produce shallow answers. Ask one focused question, wait for the answer, then ask the next.

3. **Open questions before closed questions.** Explore the space before narrowing it. "What matters most?" before "Would you prefer A or B?"

4. **Challenge assumptions, not people.** When something seems assumed, ask about it neutrally: "Is X a hard requirement, or is it an assumption we should test?"

5. **The user defines scope, not the agent.** Never add requirements the user did not state. Surface possibilities through questions, but let the user decide what is in and what is out.

6. **Non-goals are as important as goals.** A spec without explicit non-goals has undefined boundaries. Always define what you are NOT building.

7. **Acceptance criteria must be testable.** "It should be fast" is not a criterion. "Response time under 200ms at p95" is. If you cannot test it, rewrite it.

8. **Scale depth to complexity.** A two-hour feature gets a half-page spec. A quarter-long project gets a thorough one. Never over-specify simple things or under-specify complex ones.

9. **Resolve contradictions before locking scope.** If the user wants "real-time updates" and "works offline," those need reconciliation, not hand-waving.

10. **The spec is a living document until approved.** Revise freely during brainstorming. Once approved, changes go through a formal revision process.

---

## Exit Criteria

Brainstorming is complete when all of the following are true:

- The spec is written and covers all mandatory sections
- The user has explicitly approved the spec
- No unresolved contradictions exist
- All must-have acceptance criteria are present and testable
- The scope boundary (goals + non-goals) is clear

See [when-to-exit](references/when-to-exit.md) for detailed guidance on distinguishing "done" from "needs more rounds."

---

## Reference Files

| Reference | Contents |
|---|---|
| [question-playbook](references/question-playbook.md) | Full catalog of question types with example phrasings for each brainstorming phase |
| [spec-template](references/spec-template.md) | The output template the spec must follow, with section guidance |
| [anti-patterns](references/anti-patterns.md) | Failure modes that derail brainstorming, with detection signals and fixes |
| [when-to-exit](references/when-to-exit.md) | Criteria for when brainstorming is done vs. needs more rounds |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Spec is approved, ready for implementation planning | `writing-plans` |
| Requirements are complex, need stakeholder analysis | `product-manager` role |
| Spec reveals architectural decisions needed | `architect` role |
| Spec is approved, ready for direct TDD implementation | `test-driven-development` |
| Acceptance criteria need test plan detail | `qa-engineer` role |
| Spec involves API design decisions | `api-design` |
| Spec involves database schema decisions | `database-design` |

# Spec template

This is the output template that every brainstorming session produces. Each section is mandatory unless explicitly inapplicable, in which case state "N/A - [reason]."

Scale the depth of each section to the project's complexity. A small feature gets a sentence or two per section. A system redesign gets paragraphs.

## Contents

- [Template](#template)
- [Section-by-section guidance](#section-by-section-guidance)

---

## Template

```markdown
# Spec: [Project/Feature Name]

**Date**: [YYYY-MM-DD]
**Status**: Draft | Approved | Revised
**Author**: [who ran the brainstorming session]

---

## Problem

[State the problem as a problem, not as a solution. Describe what is broken, missing,
or needed. The reader should understand the pain without knowing anything about the
proposed solution.

Bad: "We need a caching layer."
Good: "Product pages take 4 seconds to load under normal traffic, causing a 35% bounce
rate. The database is the bottleneck - the same queries run thousands of times per hour
with identical results."]

---

## Goal

[The desired outcome in one or two sentences. Focus on the end state, not the mechanism.

Bad: "Implement Redis caching."
Good: "Product pages load in under 500ms at p95 under normal traffic."]

---

## Non-Goals

[What this spec explicitly does not cover. Every spec must have at least one non-goal.
Non-goals prevent scope creep and set expectations for stakeholders.

Examples:
- This spec does not cover the admin dashboard redesign.
- Performance optimization for the search API is out of scope.
- Mobile app support is deferred to a future phase.]

- [Non-goal 1]
- [Non-goal 2]
- [Non-goal 3 (if applicable)]

---

## Constraints

[Real limits that restrict the solution space. These are facts, not preferences.

Types of constraints:
- Technical: "Must integrate with the existing PostgreSQL database"
- Time: "Must ship before Q3 launch"
- Team: "Two backend engineers available, no frontend capacity"
- Budget: "No new infrastructure spend approved"
- Regulatory: "Must comply with GDPR data residency requirements"
- Organizational: "Must use the company's existing design system"]

- [Constraint 1]
- [Constraint 2]

---

## Users & Stakeholders

[Who benefits from this, who is affected by it, and who makes decisions about it.

| Role | Relationship | Key Need |
|---|---|---|
| [Primary user] | Uses the feature daily | [What they need] |
| [Secondary user] | Affected indirectly | [What they need] |
| [Decision maker] | Approves scope and trade-offs | [What they care about] |
| [Operations] | Maintains the system after launch | [What they need] |]

---

## Acceptance Criteria

[Testable conditions that define "done." Each criterion must be verifiable by a human
or an automated test. Use Given/When/Then format or equivalent structured format.

Rules:
- Every criterion must be testable
- "It should feel fast" is not a criterion
- "Page loads in under 500ms at p95" is a criterion
- Include both happy-path and key error-path criteria
- Number each criterion for traceability]

1. **[Short name]**: Given [precondition], when [action], then [expected result].
2. **[Short name]**: Given [precondition], when [action], then [expected result].
3. **[Short name]**: [Alternative format if Given/When/Then does not fit.]

---

## Risks

[What could go wrong, how likely it is, and what the mitigation strategy is.

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| [Risk description] | Low/Medium/High | Low/Medium/High | [How to reduce or handle] |]

Every spec must include at least one non-obvious risk. If the only risks listed are
"it might take longer than expected" and "requirements might change," dig deeper.

---

## Open Questions

[Anything still unresolved that does not block the spec from being approved. These are
genuine unknowns that will be resolved during implementation or by further investigation.

Rules:
- Do not list things here that you could resolve by asking the user right now
- Each question should note who is responsible for answering it and by when
- If an open question does block the spec, it must be resolved before approval]

- [ ] [Question] - Owner: [who], Due: [when]
- [ ] [Question] - Owner: [who], Due: [when]

---

## First-Cut Approach

[A high-level description of the likely direction. This is not architecture, not a
design doc, and not an implementation plan. It describes the shape of the solution
in enough detail that a reader can tell whether you are talking about a small script
or a distributed system.

Good: "A background job processes the queue, applies business rules, and writes results
to the existing database. The frontend polls for status updates."

Bad: "We will use Kafka with three consumer groups, a Redis-backed state machine,
and a React dashboard with WebSocket subscriptions."

The first-cut approach may be wrong. That is fine. Its purpose is to sanity-check
that the spec's scope is achievable and coherent, not to lock in a design.]
```

---

## Section-by-section guidance

### Problem

The problem section is the foundation. If the problem is wrong, everything downstream is wrong.

**Test**: Can someone who knows nothing about the project read this section and understand why work is needed? If not, rewrite it.

**Common mistakes**:
- Stating a solution as the problem ("We need to add caching")
- Being too abstract ("The user experience needs improvement")
- Mixing problem and goal ("We need to make pages faster by adding a CDN")

### Goal

The goal is the desired end state, not the path to get there.

**Test**: Does the goal describe an outcome, or does it describe work? "Implement feature X" is work. "Users can do Y" is an outcome.

### Non-Goals

Non-goals are not things you forgot or deprioritized. They are things someone might reasonably expect to be in scope, but are explicitly excluded.

**Test**: Would a reasonable person assume this is part of the project if you did not say otherwise? If yes, it is a good non-goal.

### Constraints

Constraints must be facts, not preferences. "We prefer to use TypeScript" is a preference. "The existing codebase is TypeScript and rewriting is not in scope" is a constraint.

**Test**: If this constraint disappeared, would the solution space meaningfully expand? If not, it is not a real constraint.

### Users & Stakeholders

Go beyond "the user." Identify specific roles with specific needs. Include people who maintain, support, and operate the system, not just those who use the UI.

### Acceptance Criteria

This is the most important section for downstream work. Implementation plans, test suites, and QA sign-off all derive from acceptance criteria.

**Format options**:
- **Given/When/Then**: Best for behavior-driven scenarios
- **Numbered assertions**: Best for technical criteria ("Response time < 200ms")
- **Checklist format**: Best for configuration or setup criteria

Include error paths, not just happy paths. What happens when the network is down? When the user provides invalid input? When the database is unreachable?

### Risks

Go beyond the obvious risks.

**Non-obvious risk categories**:
- Data migration risks
- Backward compatibility risks
- Operational risks (monitoring, alerting, on-call burden)
- User adoption risks
- Performance risks under load
- Security and privacy risks
- Dependency risks (third-party APIs, team availability)

### Open Questions

Open questions show honesty, not incompleteness. A spec with no open questions is likely hiding its unknowns.

### First-Cut Approach

This section exists to sanity-check coherence between the problem, goal, and scope. If the first-cut approach sounds wildly different from what the acceptance criteria describe, something is misaligned.

Keep it at the level of "we will probably build a batch processor" not "we will use Apache Spark with a custom DAG scheduler."

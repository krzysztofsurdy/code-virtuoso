# Product Requirements Document Template

A template for defining what to build and why. Copy it and adapt it for each feature or initiative.

## Contents

- [Template](#template)
- [Writing tips](#writing-tips)

---

## Template

### 1. Overview

| Field | Value |
|---|---|
| **Title** | [Feature or initiative name] |
| **Author** | [Name] |
| **Date** | [YYYY-MM-DD] |
| **Status** | Draft / In Review / Approved |
| **Version** | 1.0 |

**One-line summary**: [One sentence describing what this feature does and for whom.]

### 2. Problem Statement

Describe the problem being solved. Say who experiences it and what the impact is.

**Template**:

> **Who** is affected: [User persona or segment]
>
> **What** they experience: [The problem in observable terms]
>
> **Why** it matters: [Business impact, user pain, or missed opportunity]
>
> **How** we know: [Evidence - support tickets, analytics, user research, stakeholder input]

### 3. Success Metrics

Define how you will measure whether the feature meets its goal.

| Metric | Current Baseline | Target | Measurement Method |
|---|---|---|---|
| [e.g., Task completion rate] | [e.g., 62%] | [e.g., 85%] | [e.g., Analytics event tracking] |
| [e.g., Support tickets for X] | [e.g., 45/month] | [e.g., <15/month] | [e.g., Support ticket tag count] |
| [e.g., Time to complete action] | [e.g., 4.2 min] | [e.g., <2 min] | [e.g., Session duration analytics] |

### 4. User Stories

Format: As a **[persona]**, I want **[action]** so that **[benefit]**.

| ID | User Story | Priority | Acceptance Criteria Reference |
|---|---|---|---|
| US-001 | As a [persona], I want [action] so that [benefit] | P0 | AC-001, AC-002 |
| US-002 | As a [persona], I want [action] so that [benefit] | P1 | AC-003 |

### 5. Acceptance Criteria

Use the Given/When/Then format for testable criteria.

**AC-001: [Title]**

```
Given [precondition]
When [action performed by the user]
Then [expected observable outcome]
```

**AC-002: [Title]**

```
Given [precondition]
And [additional precondition]
When [action]
Then [outcome]
And [additional outcome]
```

**Checklist format** (alternative for simpler criteria):

- [ ] [Observable, testable statement]
- [ ] [Observable, testable statement]

### 6. Functional Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-001 | [Specific functional requirement] | P0 | |
| FR-002 | [Specific functional requirement] | P1 | |
| FR-003 | [Specific functional requirement] | P2 | |

### 7. Non-Functional Requirements

| Category | Requirement | Target |
|---|---|---|
| Performance | Page load time | < 2 seconds on 3G |
| Performance | API response time | < 200ms p95 |
| Security | Authentication | All endpoints require valid session |
| Security | Data handling | PII encrypted at rest and in transit |
| Accessibility | WCAG compliance | Level AA |
| Availability | Uptime | 99.9% |

### 8. Out of Scope

List what this feature does NOT include. This prevents scope creep and sets expectations.

- [Feature or behavior explicitly excluded]
- [Feature or behavior explicitly excluded]
- [Feature deferred to a future iteration with rationale]

### 9. Dependencies

| Dependency | Owner | Status | Risk if Delayed |
|---|---|---|---|
| [e.g., Payment API v2 rollout] | [Team/person] | [In progress / Not started] | [Impact description] |
| [e.g., Design system update] | [Team/person] | [Complete / In progress] | [Impact description] |

### 10. Open Questions

| # | Question | Owner | Due Date | Resolution |
|---|---|---|---|---|
| 1 | [Unanswered question] | [Who should answer] | [Date] | [Pending / Resolved: answer] |
| 2 | [Unanswered question] | [Who should answer] | [Date] | [Pending] |

### 11. Changelog

| Version | Date | Author | Changes |
|---|---|---|---|
| 1.0 | [Date] | [Author] | Initial draft |

---

## Writing tips

### Language precision

Replace ambiguous words with specific, testable statements.

| Avoid | Replace with |
|---|---|
| "The system should handle errors gracefully" | "The system displays error code and message to the user and logs the full stack trace" |
| "Fast response time" | "API responds within 200ms at the 95th percentile under 1000 concurrent users" |
| "User-friendly interface" | "User can complete the primary task in fewer than 3 clicks from the dashboard" |
| "Secure" | "All API endpoints require JWT authentication; PII is encrypted with AES-256 at rest" |

### Priority definitions

| Priority | Meaning | Release impact |
|---|---|---|
| P0 (Must-have) | Feature does not ship without this | Blocks release |
| P1 (Should-have) | Important but not critical for launch | Include if timeline allows |
| P2 (Nice-to-have) | Enhances the feature but not essential | Defer to next iteration |

### Common mistakes

- Writing acceptance criteria that cannot be tested objectively
- Omitting the "Out of Scope" section, which lets scope creep in unnoticed
- Listing open questions in the body text instead of tracking them explicitly
- Defining success metrics without a measurement method
- Mixing implementation details into requirements (describe the "what", not the "how")

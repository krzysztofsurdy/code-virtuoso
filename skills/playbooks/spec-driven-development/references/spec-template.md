# Spec template

Copy this into `specs/<slug>/spec.md`. Scale each section to the change: a small feature gets a line or two per section. Delete sections that do not apply, and write "N/A - reason" only where a reader would wonder.

## Contents

- [Template](#template)
- [Writing good criteria](#writing-good-criteria)
- [Clarification markers](#clarification-markers)
- [EARS phrasing](#ears-phrasing)

## Template

```markdown
# Spec: <feature name>

Status: Draft | Approved | Implemented | Superseded
Source: <ticket id, brainstorming spec path, or "request from <who>, <date>">
Updated: <YYYY-MM-DD>

## Problem

What is broken or missing, stated without the solution. One short paragraph.

## Goals

- Outcome 1, measurable where possible

## Non-goals

- What this change does not do (at least one)

## Users and scenarios

Who uses this and the main flows, in a few lines. Add one block per flow if there are several.

## Functional requirements

### FR-1: <short name>

The system <behavior in plain words>.

Acceptance criteria:
- WHEN <trigger or input> THEN <observable result>
- WHEN <unhappy path> THEN <observable result>

### FR-2: <short name>

...

## Non-functional requirements

- NFR-1: <limit, for example "p95 response under 300 ms for 100 requests per second">
- NFR-2: <security, accessibility, data retention, compatibility>

## Constraints and assumptions

- Things fixed by the environment: existing contracts, deadlines, compliance rules
- Assumptions that, if false, change the spec

## Open questions

- [NEEDS CLARIFICATION: question] (affects FR-2)

## Out of scope for now

- Ideas parked for later, so they do not leak into tasks
```

## Writing good criteria

| Do | Avoid |
|---|---|
| Name the trigger and the observable result | "Works correctly", "is fast", "handles errors" |
| One behavior per criterion | Criteria joined with "and" that can fail in two ways |
| Use concrete values: status codes, messages, limits | Vague quantities such as "quickly" or "a few" |
| Cover the unhappy path that is likely in production | Only the happy path |
| Describe behavior from outside the system | Naming classes, tables, or libraries (that is the plan) |

A good test of a criterion: could someone write an automated test from this line alone? If not, rewrite it.

## Clarification markers

Write `[NEEDS CLARIFICATION: <question>]` where a guess would otherwise sit. Make the question answerable in a sentence, and say which requirement it blocks.

```
FR-3: Users can export their data.
[NEEDS CLARIFICATION: which formats are required, CSV only or also JSON?]
```

Rules:

- The plan is not written while any marker is open.
- Ask the user one marker at a time, record the answer in the requirement, and delete the marker.
- If the user says "you decide", record the decision and its reason in the requirement. That is a decision, not a guess.

## EARS phrasing

Kiro-style projects write requirements in EARS form. Both forms carry the same information, so follow the project's convention:

| Pattern | Form |
|---|---|
| Event-driven | WHEN <event> THE SYSTEM SHALL <response> |
| State-driven | WHILE <state> THE SYSTEM SHALL <response> |
| Unwanted behavior | IF <condition> THEN THE SYSTEM SHALL <response> |
| Optional feature | WHERE <feature is present> THE SYSTEM SHALL <response> |
| Ubiquitous | THE SYSTEM SHALL <response> |

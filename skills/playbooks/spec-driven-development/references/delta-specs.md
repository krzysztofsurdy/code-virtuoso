# Delta specs for brownfield changes

When a change modifies behavior that is already specified, write only the difference against the current spec. Reviewers read the delta instead of re-reading the whole spec, and the merge into the source of truth after release is mechanical. This is the approach OpenSpec uses; the method works in any layout.

## Contents

- [When to use deltas](#when-to-use-deltas)
- [Layout](#layout)
- [Delta format](#delta-format)
- [Lifecycle](#lifecycle)
- [No existing specs](#no-existing-specs)

## When to use deltas

| Situation | Use |
|---|---|
| New feature, nothing similar specified | A full spec (`spec-template`) |
| Change alters existing specified behavior | Delta spec |
| Change touches several modules or a shared contract | Delta spec, one file per affected area |
| Old code has no spec at all | A full spec for the new part only; see [No existing specs](#no-existing-specs) |

## Layout

OpenSpec layout:

```
openspec/
  specs/<area>/spec.md              current behavior, source of truth
  changes/<change-name>/
    proposal.md                     why and what changes
    specs/<area>/spec.md            delta against the current spec
    design.md                       technical approach (optional)
    tasks.md                        checklist
  changes/archive/<date>-<name>/    finished changes
```

Default layout, same idea:

```
specs/
  current/<area>.md                 current behavior
  <slug>/
    delta-<area>.md                 changes to current behavior
    plan.md
    tasks.md
```

If the project already uses OpenSpec, use its layout and CLI exactly.

## Delta format

Group changes by type, under one heading each. Requirements keep the `### Requirement: <name>` form and scenarios use WHEN/THEN, so the merge can match by name.

```markdown
## ADDED Requirements

### Requirement: Session timeout warning
The system SHALL warn the user 2 minutes before a session expires.

#### Scenario: Warning shown
- **WHEN** a session has 2 minutes left
- **THEN** a dismissible banner shows the remaining time

## MODIFIED Requirements

### Requirement: Session lifetime
The system SHALL expire sessions after 30 minutes of inactivity.
(was: 60 minutes)

#### Scenario: Idle expiry
- **WHEN** a user is inactive for 30 minutes
- **THEN** the next request returns 401

## REMOVED Requirements

### Requirement: Remember me for 90 days
Reason: replaced by passkey login. Migration: existing tokens expire at their normal date.
```

Rules:

- A MODIFIED block repeats the full new text of the requirement, not just the changed words, so the merge replaces it whole. Note the old value in a line below.
- A REMOVED block states the reason and what happens to existing data or users.
- Add the requirement IDs or names the tasks will refer to. Tasks cite them the same way as in a full spec.
- Behavior that does not change is not mentioned.

## Lifecycle

1. Write the delta and get it approved.
2. Plan and tasks reference the delta's requirements.
3. Run the `plan-auditor` gate on delta, plan, and tasks.
4. Implement task by task.
5. On completion, merge each delta into the current spec: apply ADDED, replace MODIFIED by name, delete REMOVED. Archive the change folder with the date.
6. Check that the current spec matches the shipped behavior. If a reviewer cannot tell what the system does from the current specs alone, the merge is not finished.

## No existing specs

Most legacy code has no spec. Do not write one for the whole system first. Spec only the area you are about to change:

1. Write the current behavior of that area as a short spec, from the code and the existing tests. Mark anything you cannot confirm with `[NEEDS CLARIFICATION]`.
2. Pin that behavior with characterization tests (see `tdd`).
3. Write the delta against it.

Over time the specs cover the parts of the system that change, which are the parts that need them.

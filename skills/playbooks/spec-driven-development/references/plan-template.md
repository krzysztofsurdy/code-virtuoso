# Plan template

Copy this into `specs/<slug>/plan.md`. The plan answers "how" for an approved spec. Read the code first: the plan must fit the patterns already there.

## Contents

- [Template](#template)
- [Guidance](#guidance)

## Template

```markdown
# Plan: <feature name>

Spec: specs/<slug>/spec.md (approved <date>)
Updated: <YYYY-MM-DD>

## Approach

Two to five sentences: the shape of the solution and why it fits the codebase.

## Codebase findings

- Existing pattern to follow: <path and what it does>
- Code that will be touched: <paths>
- Existing tests and fixtures to reuse: <paths>

## Requirement mapping

| Requirement | Component or file | Interface or contract | Verified by |
|---|---|---|---|
| FR-1 | src/Auth/TokenValidator.php | validate(string): Claims | unit test, integration test |
| FR-2 | src/Http/AuthMiddleware.php | 401 body schema | integration test |
| NFR-1 | src/Cache/ClaimsCache.php | TTL 60 s | load test, manual |

## Data and interface changes

- Schema or migration changes, with rollback
- New or changed API contracts, with compatibility notes

## Decisions

| Decision | Alternatives considered | Why this one |
|---|---|---|
| <choice> | <option A, option B> | <reason tied to a requirement or constraint> |

## Risks and order of work

| Risk | Likelihood and impact | Retired by |
|---|---|---|
| <what could go wrong> | <low, medium, high> | <task or spike that tests it early> |

Order: riskiest or most uncertain slice first, then the rest by dependency.

## Verification strategy

- Unit: <what logic>
- Integration: <which boundaries>
- End to end or manual: <critical flows only>
- Commands: <the project's test, lint, and static analysis commands>

## Rollout

Feature flag, migration order, monitoring to watch, rollback path. Write "N/A" for changes with no rollout risk.
```

## Guidance

- Every requirement ID from the spec appears in the mapping table. A missing row is a gap the audit will flag.
- Keep file paths real: check they exist or say they are new.
- A decision that needs more than a few lines belongs in an ADR, linked from here.
- Do not copy the spec into the plan. Link to requirement IDs.
- If the plan reveals that a requirement is unclear or impossible, go back and fix the spec before continuing. Do not paper over it in the plan.

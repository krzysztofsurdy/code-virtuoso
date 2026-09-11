# Bug

A bug reports a deviation from intended behaviour. A good bug ticket is a stand-alone observation: a reader in six months, with no context, should be able to reproduce the problem and see how serious it is.

## Contents

- [Required fields](#required-fields)
- [Optional fields](#optional-fields)
- [Severity vs priority](#severity-vs-priority)
- [Writing reproduction steps](#writing-reproduction-steps)
- [Environment capture](#environment-capture)
- [Questionnaire](#questionnaire)
- [Output template](#output-template)
- [Quality checks](#quality-checks)
- [Common anti-patterns](#common-anti-patterns)

## Required fields

| Field | Purpose |
|---|---|
| Title | Descriptive, specific, and observable. Starts from the visible symptom. |
| Summary | Two or three sentences describing what is broken. |
| Steps to reproduce | Numbered, deterministic, minimal. Anyone with the listed environment can follow them. |
| Expected behaviour | What the system was supposed to do. Link to the spec or story if one exists. |
| Actual behaviour | What the system actually does. Include the exact error message, status code, or visual symptom. |
| Environment | OS, browser, app version, build, data condition, feature flags, whatever is relevant. |
| Severity | How badly the defect damages the product experience. |
| Priority | How urgently the team should fix it. |

## Optional fields

| Field | When to include |
|---|---|
| Screenshot or recording | For any visual or UI bug |
| Logs, stack trace, or request IDs | For errors that leave a trace |
| First observed | Date or version where the issue appeared |
| Regression | Yes/no, and the last known good version if yes |
| Workaround | If one exists while the fix is pending |
| Affected users or traffic | Metrics on blast radius |
| Related tickets | Prior fixes, duplicates, parent epic |

## Severity vs priority

These are two independent axes. Keep them separate: a minor typo on the brand page can be low severity and high priority.

| Severity | Meaning |
|---|---|
| S1 - Critical | Data loss, security breach, or the product is unusable for most users. |
| S2 - High | A core flow is broken with no reasonable workaround. |
| S3 - Medium | A feature is degraded, or a workaround exists. |
| S4 - Low | Cosmetic, typo, minor inconsistency. |

| Priority | Meaning |
|---|---|
| P0 - Now | Stop other work. Fix and ship today. |
| P1 - This sprint | Planned into the current cycle. |
| P2 - Next sprint | Prioritised but not immediate. |
| P3 - Backlog | Acknowledged, scheduled opportunistically. |

Severity is primarily a QA judgement; priority is a product judgement. The ticket should record both.

## Writing reproduction steps

Reproduction steps are the most valuable part of a bug ticket. A bug without them is a wish list.

- Number the steps. Each step is one atomic user action.
- Start from a known state ("signed out", "empty cart", "on the home page").
- Include the exact inputs used - product IDs, test accounts, payload bodies.
- Stop at the point where the observable defect occurs.
- If the bug is intermittent, say so and include the observed rate (e.g., "fails roughly 1 in 5 attempts").

Keep the steps minimal. If a step can be removed and the bug still reproduces, remove it.

## Environment capture

Include every field that could change the outcome. Leave out the rest.

Relevant fields by bug class:

| Bug class | Environment fields that usually matter |
|---|---|
| Web UI | Browser + version, OS, viewport size, ad blockers, cookies / session state |
| Mobile app | Device model, OS version, app version, network type |
| Backend API | Service version, deployment region, dependent service versions |
| Data / migration | Database version, dataset size, affected record IDs |
| Integration | Third-party API version, credentials type (sandbox vs prod) |

## Questionnaire

Ask in this order. Batch 1-3 together; 4-6 together; 7-9 together.

1. **Title**: descriptive symptom, free text
2. **Summary**: two or three sentences, free text
3. **Expected behaviour**: free text
4. **Actual behaviour**: free text, include any error messages verbatim
5. **Steps to reproduce**: numbered free text
6. **Environment**: free text, prompt for the fields relevant to the bug class
7. **Severity**: S1 / S2 / S3 / S4
8. **Priority**: P0 / P1 / P2 / P3
9. **Evidence**: screenshot, recording, logs, request IDs (optional)
10. **Regression**: is this a regression from a recent change? If yes, last known good version
11. **Workaround**: any known mitigation (optional)
12. **Blast radius**: estimated affected users or % of traffic (optional)

If the user cannot answer steps to reproduce or environment, do not fabricate values. Put the gap in `## Open Questions` and leave the ticket in draft.

## Output template

```markdown
# <Descriptive symptom-first title>

## Summary
<Two or three sentences.>

## Steps to Reproduce
1. <step>
2. <step>
3. <step>

## Expected Behaviour
<What should happen.>

## Actual Behaviour
<What happens instead, including exact errors.>

## Environment
- Platform: <browser/OS/device/service>
- Version / build: <>
- Account or data condition: <>
- Feature flags: <>

## Severity / Priority
- Severity: <S1-S4 with one-line reason>
- Priority: <P0-P3 with one-line reason>

## Evidence
<Screenshots, recordings, log excerpts, request IDs - omit if none>

## Regression
<Yes/No. If yes, last known good version.>

## Workaround
<If one exists, otherwise omit.>

## Impact
<Estimated affected users or traffic, if known.>

## Links
- Related tickets: <list>
- Logs / traces: <list>

## Open Questions
<Anything the reporter could not answer. Omit if none.>
```

## Quality checks

- The title names a concrete symptom, not a hypothesis ("payment button disabled after refresh" vs "payment flow is broken").
- Steps to reproduce are numbered, deterministic, and minimal.
- Expected and actual behaviour are concrete and separate, with no "it doesn't work".
- Error messages are quoted verbatim, not paraphrased.
- Severity and priority are both set and justified.
- Severity and priority are not confused.

## Common anti-patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| "Login is broken" | No symptom, no steps, no environment | Rewrite with concrete symptom and reproduction |
| Severity = priority for every bug | Collapses the axes and makes triage useless | Treat them independently |
| "See Slack thread" with no content | Loses context when the thread ages out | Paste the key facts into the ticket |
| Multiple unrelated bugs in one ticket | Makes fixing and verification messy | Split into separate tickets |
| Paraphrased error message | A reader cannot grep the logs for it | Quote the message character-for-character |
| Missing actual behaviour | Reviewer cannot tell what the defect is | Describe the observed outcome explicitly |

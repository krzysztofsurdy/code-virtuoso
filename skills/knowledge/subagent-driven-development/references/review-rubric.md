# Two-Stage Review Rubric

Every task output passes through two sequential review stages before the orchestrator accepts it. The stages serve different purposes and must not be combined, reordered, or skipped.

## Why Two Stages

A single review pass conflates two distinct questions:

1. **Did the subagent do what was asked?** (specification conformance)
2. **Did the subagent do it well?** (implementation quality)

These require different review postures. Spec compliance is mechanical - checkable against the brief's acceptance criteria. Quality review is judgmental - it requires expertise, context awareness, and trade-off evaluation.

Combining them leads to a common failure mode: the reviewer gets distracted by code style issues while an acceptance criterion is quietly unmet. Separating the stages forces discipline.

## Stage 1: Spec Compliance

**Purpose:** Verify that the task output satisfies every acceptance criterion from the brief.

**Posture:** Mechanical. Binary pass/fail per criterion. No subjective judgment.

### Checklist

| # | Check | Pass condition |
|---|---|---|
| 1 | **Acceptance criteria coverage** | Every criterion from the brief has a corresponding change in the output |
| 2 | **Behavioral correctness** | The implementation produces the behavior described in each criterion (verified by tests or manual inspection) |
| 3 | **Test existence** | Tests exist for each acceptance criterion that specifies testable behavior |
| 4 | **Test passage** | All new tests pass. All previously passing tests still pass. |
| 5 | **Scope boundaries** | No files or behaviors outside the brief's scope were modified |
| 6 | **Out-of-scope compliance** | Nothing listed in the "out of scope" section was touched |
| 7 | **Artifact completeness** | All expected artifacts (code, tests, configs, migrations) are present |

### Severity Levels

| Severity | Definition | Action |
|---|---|---|
| **Fail** | An acceptance criterion is not met, or an out-of-scope boundary was violated | Return to subagent with specific failing criteria. Must be fixed before Stage 2. |
| **Concern** | An acceptance criterion is met but in an unexpected way that may cause issues | Note for Stage 2 review. Does not block Stage 2 entry. |
| **Pass** | All criteria met, scope respected, artifacts complete | Proceed to Stage 2. |

### Stage 1 Output Format

```
## Spec Compliance Review: [TASK-ID]

**Verdict:** Pass / Fail / Pass with Concerns

### Criteria Results
| # | Criterion (from brief) | Status | Evidence |
|---|---|---|---|
| AC-1 | [criterion text] | Pass/Fail | [file:line or test name] |
| AC-2 | [criterion text] | Pass/Fail | [file:line or test name] |

### Scope Check
- Files modified: [list]
- Expected scope: [from brief]
- Out-of-scope violations: None / [list]

### Concerns (if any)
- [description of unexpected approach that merits Stage 2 attention]

### Blocking Issues (if verdict is Fail)
1. [specific criterion that failed, with evidence]
2. [another, if applicable]
```

## Stage 2: Code Quality

**Purpose:** Evaluate the quality of the implementation across correctness, maintainability, security, and testing.

**Posture:** Judgmental. Requires expertise and trade-off awareness. Findings have severity levels.

**Prerequisite:** Stage 1 must pass before Stage 2 begins. Reviewing quality on code that does not meet its spec is wasted effort.

### Checklist

#### Correctness

| # | Check | What to look for |
|---|---|---|
| 1 | **Edge cases** | Null inputs, empty collections, boundary values, overflow, concurrent access |
| 2 | **Error handling** | Errors caught at appropriate levels, meaningful messages, no silent swallowing |
| 3 | **Resource management** | Connections closed, streams flushed, locks released, temp files cleaned |
| 4 | **Type safety** | Correct types used, no unsafe casts, generics applied where appropriate |
| 5 | **Concurrency** | Thread safety where relevant, no race conditions, proper synchronization |

#### Design and Maintainability

| # | Check | What to look for |
|---|---|---|
| 6 | **Single responsibility** | Each class/function does one thing. Changes have one reason. |
| 7 | **Naming clarity** | Names reveal intent. No abbreviations that require context to decode. |
| 8 | **Duplication** | No copy-paste code. Shared logic extracted to appropriate abstraction. |
| 9 | **Coupling** | Dependencies are on abstractions, not concretions. No hidden global state. |
| 10 | **Complexity** | No deeply nested conditionals. No methods with 5+ parameters. |

#### Security

| # | Check | What to look for |
|---|---|---|
| 11 | **Input validation** | All external input validated at system boundaries |
| 12 | **Injection prevention** | Parameterized queries, escaped output, no string concatenation for commands |
| 13 | **Authentication/authorization** | Protected endpoints checked, no privilege escalation paths |
| 14 | **Data exposure** | No sensitive data in logs, error messages, or API responses |

#### Performance

| # | Check | What to look for |
|---|---|---|
| 15 | **Query patterns** | No N+1 queries, appropriate eager/lazy loading, indexed lookups |
| 16 | **Memory** | No unbounded collections, streaming for large data sets, no leaks |
| 17 | **Unnecessary work** | No redundant computations, appropriate caching, efficient algorithms |

#### Test Quality

| # | Check | What to look for |
|---|---|---|
| 18 | **Behavior focus** | Tests assert on outcomes, not implementation details |
| 19 | **Meaningful assertions** | Every test has at least one meaningful assertion. No empty test bodies. |
| 20 | **Edge case coverage** | Error paths, boundary values, and failure modes are tested |
| 21 | **Test independence** | No shared mutable state, no execution order dependencies |
| 22 | **Readability** | Test names describe the scenario and expected outcome |

### Severity Levels

| Severity | Definition | Action |
|---|---|---|
| **Critical** | Bug, security vulnerability, data corruption risk, or missing error handling that will cause production failures | Must fix before acceptance. Return to subagent. |
| **Warning** | Code smell, performance concern, missing edge case, or maintainability issue that will cause problems over time | Should fix before acceptance. Orchestrator decides if it blocks. |
| **Suggestion** | Style improvement, naming tweak, or minor refactoring that would improve clarity | Record for future improvement. Does not block acceptance. |

### Stage 2 Output Format

```
## Code Quality Review: [TASK-ID]

**Verdict:** Accept / Request Changes / Needs Discussion

### Findings

**[CRITICAL] [Title]**
- Location: [file:line]
- Issue: [what is wrong]
- Impact: [what happens if not fixed]
- Suggestion: [how to fix]

**[WARNING] [Title]**
- Location: [file:line]
- Issue: [what is wrong]
- Impact: [what happens if not fixed]
- Suggestion: [how to fix]

**[SUGGESTION] [Title]**
- Location: [file:line]
- Suggestion: [improvement]

### Strengths
- [what was done well - acknowledge good work]

### Summary
- Critical: [count]
- Warning: [count]
- Suggestion: [count]
- Verdict rationale: [why accept/reject]
```

## Decision Matrix

After both stages complete, the orchestrator decides:

| Stage 1 | Stage 2 | Decision |
|---|---|---|
| Pass | Accept (0 critical, 0 warning) | **Accept** - advance to next task |
| Pass | Accept (0 critical, warnings exist) | **Accept with notes** - record warnings in hand-off, optionally fix |
| Pass | Request Changes (criticals exist) | **Return** - subagent fixes critical issues, then re-review Stage 2 only |
| Pass with Concerns | Request Changes | **Return** - subagent addresses concerns and criticals together |
| Fail | Not started | **Return** - subagent fixes spec issues, then full re-review (both stages) |
| Fail (after 2 attempts) | Not started | **Abort** - re-scope the task or escalate |

## Review Efficiency

To keep reviews fast without sacrificing thoroughness:

- Stage 1 should take under 2 minutes for a well-scoped task - it is a checklist comparison
- Stage 2 depth scales with risk - mechanical changes get a lighter review than security-critical ones
- Use existing project tooling (linters, static analysis, test coverage reports) as Stage 2 inputs rather than manually checking what tools can catch
- When dispatching a reviewer subagent, include the brief's acceptance criteria so the reviewer does not need to search for them

## Re-Review After Fixes

When a subagent fixes issues and resubmits:

| Original failure | Re-review scope |
|---|---|
| Stage 1 failure | Full re-review: Stage 1 then Stage 2 (the fix may have introduced quality issues) |
| Stage 2 critical | Stage 2 only (spec compliance already confirmed) |
| Stage 2 warning (if fixed) | Stage 2 only, focused on the fixed areas |

Cap re-review cycles at two per stage. If the subagent cannot resolve issues after two fix-and-review rounds, the task needs re-scoping or a different approach.

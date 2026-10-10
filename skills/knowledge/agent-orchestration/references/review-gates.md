# Review gates and hand-offs

How to run a plan task by task with one fresh agent per task, check each result twice, and pass state to the next task. Use this when a plan has three or more tasks and the tasks build on each other.

## Contents

- [Why two gates](#why-two-gates)
- [The loop in detail](#the-loop-in-detail)
- [Gate 1: spec compliance](#gate-1-spec-compliance)
- [Gate 2: code quality](#gate-2-code-quality)
- [Decision matrix](#decision-matrix)
- [Re-review after fixes](#re-review-after-fixes)
- [Hand-offs between tasks](#hand-offs-between-tasks)
- [Keeping the orchestrator lean](#keeping-the-orchestrator-lean)

## Why two gates

A single review pass mixes two questions: did the agent do what was asked, and did it do it well? They need different postures. The first is mechanical and checkable against the brief. The second is judgment. When they are mixed, the reviewer gets absorbed in naming and style while an acceptance criterion quietly goes unmet.

Run gate 1 first. Reviewing the quality of code that misses its spec wastes effort, because the fix may rewrite it.

Both gates apply even to small tasks. Small, obviously correct changes are where assumptions go unchecked, and an error that slips through task 2 costs ten times more to fix at task 7.

## The loop in detail

For each task in order:

1. **Brief.** Write the task brief ([briefing-template.md](briefing-template.md)) with the hand-off from the previous task. Give the agent only the current task, never the whole plan.
2. **Dispatch** a fresh agent. Use filesystem isolation if the platform offers it. Preload only the skills this task needs.
3. **Receive** the report. Handle the status:

   | Status | Action |
   |---|---|
   | Done | Go to gate 1 |
   | Done with concerns | Read the concerns. If they touch correctness or scope, resolve them first. Then gate 1 |
   | Needs context | Supply the missing fact and re-dispatch. Do not guess for the agent |
   | Blocked | Provide context, re-scope the task, or escalate to a human. Do it now, not later |

4. **Gate 1**, then **gate 2**, using a reviewer agent or yourself. Give a reviewer agent the brief's acceptance criteria so it does not have to find them.
5. **Decide:** accept, return with feedback, or abort (table below). Never accept with a known open issue, and never defer a critical finding to "cleanup later".
6. **Hand off** to the next task.
7. **Log** the accept or reject decision of both gates. This is your implementation record.

Cap fix cycles at two per gate. If the agent cannot resolve the finding after two rounds of specific feedback, the task is mis-scoped, the feedback is vague, or the agent lacks context. Diagnose which one, then re-scope or escalate. Looping a third time rarely converges.

## Gate 1: spec compliance

Binary, per criterion. No taste.

| # | Check | Passes when |
|---|---|---|
| 1 | Criteria coverage | Every acceptance criterion has a matching change |
| 2 | Behavior | Each criterion's behavior is shown by a test or by inspection |
| 3 | Tests exist | Every testable criterion has a test |
| 4 | Tests pass | New tests pass, and the earlier suite still passes |
| 5 | Scope | No file or behavior outside the brief was changed |
| 6 | Out of scope | Nothing the brief excluded was touched |
| 7 | Completeness | All expected artifacts exist (code, tests, config, migrations) |

Verdicts: **Fail** (a criterion is unmet or a boundary was crossed: return it), **Pass with concerns** (met, but in an unexpected way: note it for gate 2), **Pass**.

Report format:

```
## Gate 1: [TASK-ID]
Verdict: Pass / Pass with concerns / Fail

| # | Criterion | Status | Evidence (file:line or test name) |
|---|---|---|---|

Files changed: [list]    Expected scope: [from brief]
Out-of-scope changes: none / [list]
Blocking issues: [only if Fail]
```

## Gate 2: code quality

Judgment, with severity. Use project tooling (linters, static analysis, coverage) as input instead of checking by eye what a tool can check.

| Area | Look for |
|---|---|
| Correctness | Edge cases (null, empty, boundary, overflow, concurrency), error handling that is not swallowed, resources released |
| Design | One responsibility per unit, names that show intent, no duplication, dependencies on abstractions, shallow nesting |
| Security | Input validated at boundaries, parameterized queries, output escaping, access checks on protected paths, no secrets or personal data in logs |
| Performance | No N+1 access patterns, no unbounded collections, no redundant work |
| Tests | Assert behavior, not implementation. Every test asserts something. Error paths and boundaries covered. No shared mutable state or order dependence. Names describe scenario and outcome |

| Severity | Meaning | Action |
|---|---|---|
| **Critical** | Bug, security hole, data-loss risk, or missing error handling that fails in production | Must fix before accepting |
| **Warning** | Smell, performance concern, missing edge case, maintainability problem | Should fix. You decide if it blocks |
| **Suggestion** | Style, naming, small refactor | Record. Does not block |

Scale depth with risk: a mechanical rename gets a light pass, an authentication change gets a deep one.

Report format:

```
## Gate 2: [TASK-ID]
Verdict: Accept / Request changes / Needs discussion

[CRITICAL|WARNING|SUGGESTION] Title
  Location: file:line
  Issue / Impact / Fix: ...

Strengths: [what was done well]
Counts: critical N, warning N, suggestion N
```

## Decision matrix

| Gate 1 | Gate 2 | Decision |
|---|---|---|
| Pass | Accept | Accept, hand off |
| Pass | Accept with warnings | Accept, record the warnings in the hand-off, fix them if cheap |
| Pass | Criticals found | Return. Re-review gate 2 only |
| Pass with concerns | Changes requested | Return. The agent handles concerns and criticals together |
| Fail | Not started | Return. After the fix, re-run both gates |
| Fail after two attempts | Not started | Abort: re-scope the task or escalate |

## Re-review after fixes

| Original failure | Re-review scope |
|---|---|
| Gate 1 failure | Both gates, because the fix may add quality problems |
| Gate 2 critical | Gate 2 only |
| Gate 2 warning that was fixed | Gate 2, focused on the changed areas |

## Hand-offs between tasks

Compress, do not replay. The next agent needs decisions, artifacts, and changed interfaces, not a transcript. Choose the format by how deeply the next task depends on this one.

| Format | Use when | Contents |
|---|---|---|
| **Diff summary** | Light dependency: the next task uses a new file or interface | Changed files, new signatures, test names, test status |
| **Decision log** | Choices made here constrain the next task | Diff summary plus each decision, the alternative rejected, why, and the impact on the next task |
| **Full hand-off** | The next task modifies what this one created | Decision log plus architecture notes and open items |

When unsure, use the decision log. It covers the common case without much bulk.

Template:

```
## Hand-off: Task NN -> Task MM

Changes
- Created: [path] ([signatures])
- Modified: [path] ([what changed])

Decisions
1. [Choice]. Rejected: [alternative]. Why: [reason]. Impact on Task MM: [constraint]

Tests: [counts, status]
Deviations from the plan: [none / what and why]
Open items: [none / list]
```

Keep a hand-off under about 40 lines. List file paths and signatures, not file contents. Leave out fix-cycle stories, reviewer chatter that does not affect the next task, and token or timing numbers. Later hand-offs may point back to earlier ones by task ID instead of repeating them.

Edge cases: the first task has no hand-off (write "none, first task"). A task that produced documentation or analysis still gets one. If you re-scoped a task mid-run, record the deviation so the next agent does not assume the original scope was finished.

## Keeping the orchestrator lean

The orchestrator reads the plan, briefs, dispatches, reviews, and decides. It does not implement or debug. Once it starts writing code, its context fills with detail and its coordination degrades. If a fix is small, still send it back to an agent with the specific feedback.

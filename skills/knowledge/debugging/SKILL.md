---
name: debugging
description: Systematic debugging by root cause analysis. Use when facing a bug, test failure, flaky behavior, production error, or integration failure. Covers reproduce, hypothesize, fix, prevent, and post-mortems.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Debugging

## Iron law

**No fix without root cause.** Never apply a fix until you can explain WHY the bug exists, not only WHERE it shows up. Symptom-level fixes create new bugs.

## Workflow

### Phase 1: Reproduce

Establish a reliable reproduction before investigating.

1. Collect all evidence: error messages, stack traces, logs, screenshots, user steps
2. Identify the exact conditions: environment, data state, user actions, timing
3. Create a minimal reproduction by stripping away everything not needed to trigger the bug
4. Confirm the reproduction is consistent (if intermittent, note frequency and conditions)
5. Write the reproduction steps down precisely so someone else can follow them

**Output**: Documented reproduction steps, minimal test case

**If you cannot reproduce**: Document what you tried, check environment differences, add instrumentation, and wait for the next occurrence. Do not move to Phase 2 on guesswork. Unreproducible bugs get logged, not "fixed."

### Phase 2: Investigate

Gather evidence systematically. Do NOT form hypotheses yet. This phase is about observation, not explanation.

1. Read the full error message and stack trace, every line, not only the first one
2. Check git history for recent changes (`git log --since="2 weeks ago"`, `git bisect`)
3. Trace the data flow from the entry point to the failure point
4. Check boundaries: where does data cross component, service, or layer boundaries?
5. Collect environmental context: versions, configuration, dependencies, resource state
6. Map the blast radius: what else is affected? Is this an isolated failure or systemic?

**Production vs development debugging:**
- **Production**: Assess impact and mitigate first. Can you reduce the blast radius before investigating? Use read-only access only, and never debug by modifying production state.
- **Development**: You have full control. Use breakpoints, modify state, add temporary logging freely.

**Output**: Evidence log (what you found, where, timestamps), affected component map

### Phase 3: Hypothesize

Form competing hypotheses ranked by evidence strength.

1. List ALL plausible causes. Do not anchor on the first idea
2. Classify each hypothesis by bug category (see [bug categories reference](references/bug-categories.md))
3. Rate each on evidence strength (strong/medium/weak), testability (easy/hard), and likelihood
4. Pick the most likely AND most testable hypothesis first
5. Define what would CONFIRM and what would FALSIFY each hypothesis
6. Log evidence, not hunches: "I think it might be X" is not a hypothesis; "log line Y shows value Z when it should show W" is

**Output**: Ranked hypothesis list with evidence and test plan

### Phase 4: Test

Validate one hypothesis at a time. Change a single variable per test.

1. Change ONE thing and observe the result
2. If confirmed, proceed to Phase 5
3. If falsified, update the evidence log and move to the next hypothesis
4. If inconclusive, add more instrumentation and gather more evidence
5. After 3 failed hypotheses, STOP and re-examine your assumptions. The bug model may be wrong.

**Red flags** (return to Phase 2 immediately):
- "Quick fix for now, investigate later"
- Changing multiple things at once
- Fixing without understanding
- Copy-pasting a fix from the internet without understanding why it works

**Output**: Confirmed root cause with evidence chain

### Phase 5: Fix

Implement the fix at the source, not at the symptom.

1. Write a failing test that reproduces the bug FIRST
2. Implement the fix as a single, focused change addressing the root cause
3. Verify the failing test now passes
4. Run the full test suite to catch regressions
5. Review your own fix: is this the simplest correct solution?

**Output**: Fix with regression test, clean test suite

### Phase 6: Prevent

Make sure this class of bug cannot recur.

1. Add defensive validation at the boundary where bad data entered
2. Improve error messages. Would you understand this error immediately in six months?
3. Update monitoring/alerting if this was a production issue
4. Write a post-mortem if the bug was significant (see [post-mortem template](references/post-mortem-template.md))
5. Share findings with the team, which is how institutional knowledge grows

**Output**: Prevention measures, post-mortem (if significant)

---

## Bug category strategies

Different bug types need different investigation approaches. See [bug categories reference](references/bug-categories.md) for the full guide.

| Category | First move | Key technique |
|---|---|---|
| Logic error | Read the code, trace conditions | Rubber duck walkthrough, truth tables |
| Data issue | Inspect actual vs expected data at each boundary | Boundary logging, data flow trace |
| State/race condition | Add timestamps to all state mutations | Sequence diagram, concurrency analysis |
| Integration failure | Check API contract compliance | Request/response logging, contract tests |
| Performance | Profile before guessing | Profiler, flame graphs, query analysis |
| Environment | Compare working vs broken env | Differential analysis, config audit |
| Intermittent/flaky | Increase observability first | Statistical logging, stress testing |

---

## Escalation criteria

Stop debugging and escalate when:

- You have spent more than 2x your initial time estimate without meaningful progress
- The fix requires architectural changes beyond your component
- The root cause is in a dependency you do not control
- You have found 3+ bugs in the same area, which means the code needs redesign, not more patches
- The bug exposes a fundamental design flaw
- Production impact is growing and a workaround or rollback is faster than a fix

**Escalate to:**

| Situation | Escalate to |
|---|---|
| Design or architecture issues | Architect |
| Cannot reproduce, need more info | QA team |
| Scope, priority, or trade-off questions | PM / Product Owner |
| Dependency or infrastructure issues | Platform / DevOps team |
| Security implications discovered | Security team immediately |

---

## Decision framework

### Fix depth
- Fix at the SOURCE where bad data/state originates, not where the error appears
- Add defense-in-depth: validate at boundaries even after fixing the source
- Prefer making invalid states unrepresentable over runtime validation

### Scope of fix
- Fix the specific bug, not the surrounding code
- If you see other issues nearby, file them separately. Do not let a bug fix grow in scope
- One bug = one fix = one commit = one test

### When to rewrite vs patch
- **Patch**: isolated bug, clear root cause, code is otherwise sound
- **Rewrite**: 3+ bugs in the same module, the root cause is structural, and the fix would be more complex than a rewrite
- **Rollback**: production is burning and the previous version worked. Roll back first, debug second

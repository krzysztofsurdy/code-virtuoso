---
name: debugging
description: Systematic debugging workflow — reproduce, investigate, hypothesize, fix, and prevent. Covers root cause analysis, bug category strategies, evidence-based diagnosis, and post-mortem documentation.
user-invocable: false
---

# Debugging

Systematic methodology for finding and fixing bugs. Prioritizes root cause analysis over symptom treatment, evidence over intuition, and prevention over recurrence.

## Iron Law

**No fix without root cause.** Never apply a fix until you can explain WHY the bug exists, not just WHERE it manifests. Symptom-level fixes create new bugs.

## When to Use

- Bug report from QA or production alert
- Test failure with unclear cause
- Intermittent/flaky behavior
- Performance degradation
- Unexpected behavior that "used to work"
- Integration failures between components

## Workflow

### Phase 1: Reproduce

Establish a reliable reproduction before investigating.

1. Collect all evidence — error messages, stack traces, logs, screenshots, user steps
2. Identify the exact conditions: environment, data state, user actions, timing
3. Create a minimal reproduction — strip away everything that isn't needed to trigger the bug
4. Confirm reproduction is consistent (if intermittent, note frequency and conditions)
5. Write down the reproduction steps precisely — someone else should be able to follow them

**Output**: Documented reproduction steps, minimal test case

**If you cannot reproduce**: Document what you tried, check environment differences, add instrumentation and wait for next occurrence. Do not proceed to Phase 2 on guesswork — unreproducible bugs get logged, not "fixed."

### Phase 2: Investigate

Gather evidence systematically. Do NOT form hypotheses yet — this phase is about observation, not explanation.

1. Read the full error message and stack trace — every line, not just the first one
2. Check git history — what changed recently? (`git log --since="2 weeks ago"`, `git bisect`)
3. Trace the data flow — follow the input from entry point to failure point
4. Check boundaries — where does data cross component/service/layer boundaries?
5. Collect environmental context — versions, configuration, dependencies, resource state
6. Map the blast radius — what else is affected? Is this an isolated failure or systemic?

**Production vs development debugging:**
- **Production**: Prioritize impact assessment and mitigation first. Can you reduce blast radius before investigating? Read-only access only — never debug by modifying production state.
- **Development**: You have full control. Use breakpoints, modify state, add temporary logging freely.

**Output**: Evidence log (what you found, where, timestamps), affected component map

### Phase 3: Hypothesize

Form competing hypotheses ranked by evidence strength.

1. List ALL plausible causes — do not anchor on the first idea
2. Classify each hypothesis by bug category (see [bug categories reference](references/bug-categories.md))
3. Rate each: evidence strength (strong/medium/weak), testability (easy/hard), likelihood
4. Pick the most likely AND most testable hypothesis first
5. Define what would CONFIRM and what would FALSIFY each hypothesis

**Example hypothesis table:**

| # | Hypothesis | Category | Evidence | Testability | Test Plan |
|---|---|---|---|---|---|
| 1 | Cache returns stale data after update | State | Log shows old value 2s after write | Easy | Bypass cache and compare |
| 2 | Race condition between two workers | Race condition | Intermittent, high load correlation | Medium | Add locking, stress test |
| 3 | Upstream API returns unexpected format | Integration | No evidence yet | Easy | Log raw response |

**Output**: Ranked hypothesis list with evidence and test plan

### Phase 4: Test

Validate one hypothesis at a time. Single-variable changes only.

1. Change ONE thing and observe the result
2. If confirmed — proceed to Phase 5
3. If falsified — update evidence log, return to next hypothesis
4. If inconclusive — add more instrumentation, gather more evidence
5. After 3 failed hypotheses — STOP. Re-examine your assumptions. The bug model may be wrong.

**Red flags** (return to Phase 2 immediately):
- "Quick fix for now, investigate later"
- Changing multiple things at once
- Fixing without understanding
- Copy-pasting a fix from the internet without understanding why it works

**Output**: Confirmed root cause with evidence chain

### Phase 5: Fix

Implement the fix at the source, not at the symptom.

1. Write a failing test that reproduces the bug FIRST
2. Implement the fix — single, focused change addressing the root cause
3. Verify the failing test now passes
4. Run the full test suite — ensure no regressions
5. Review your own fix: is this the simplest correct solution?

**Fix principles:**
- Fix at the SOURCE where bad data/state originates, not where the error appears
- Add defense-in-depth: validate at boundaries even after fixing the source
- Prefer making invalid states unrepresentable over runtime validation
- One bug = one fix = one commit = one test

**Output**: Fix with regression test, clean test suite

### Phase 6: Prevent

Ensure this class of bug cannot recur.

1. Add defensive validation at the boundary where bad data entered
2. Improve error messages — would future-you understand this error immediately?
3. Update monitoring/alerting if this was a production issue
4. Write a post-mortem if the bug was significant (see [post-mortem template](references/post-mortem-template.md))
5. Share findings with the team — this is how institutional knowledge grows

**Output**: Prevention measures, post-mortem (if significant)

---

## Bug Category Strategies

Different bug types need different investigation approaches. See [bug categories reference](references/bug-categories.md) for the full guide.

| Category | First Move | Key Technique |
|---|---|---|
| Logic error | Read the code, trace conditions | Rubber duck walkthrough, truth tables |
| Data issue | Inspect actual vs expected data at each boundary | Boundary logging, data flow trace |
| State/race condition | Add timestamps to all state mutations | Sequence diagram, concurrency analysis |
| Integration failure | Check API contract compliance | Request/response logging, contract tests |
| Performance | Profile before guessing | Profiler, flame graphs, query analysis |
| Environment | Compare working vs broken env | Differential analysis, config audit |
| Intermittent/flaky | Increase observability first | Statistical logging, stress testing |

---

## Escalation Criteria

Stop debugging and escalate when:

- You have spent more than 2x your initial time estimate without meaningful progress
- The fix requires architectural changes beyond your component
- The root cause is in a dependency you do not control
- You have found 3+ bugs in the same area — the code needs redesign, not more patches
- The bug exposes a fundamental design flaw
- Production impact is growing and a workaround/rollback is faster than a fix

**Escalate to:**

| Situation | Escalate To |
|---|---|
| Design or architecture issues | Architect |
| Cannot reproduce, need more info | QA team |
| Scope, priority, or trade-off questions | PM / Product Owner |
| Dependency or infrastructure issues | Platform / DevOps team |
| Security implications discovered | Security team immediately |

---

## Decision Framework

### Fix depth
- Fix at the SOURCE where bad data/state originates, not where the error appears
- Add defense-in-depth: validate at boundaries even after fixing the source
- Prefer making invalid states unrepresentable over runtime validation

### Scope of fix
- Fix the specific bug, not the surrounding code
- If you see other issues nearby, file them separately — do not scope-creep a bug fix
- One bug = one fix = one commit = one test

### When to rewrite vs patch
- **Patch**: isolated bug, clear root cause, code is otherwise sound
- **Rewrite**: 3+ bugs in same module, root cause is structural, fix would be more complex than rewrite
- **Rollback**: production is burning and the previous version worked — roll back first, debug second

---

## Integration with Team Roles

This debugging workflow connects to broader team processes:

| Phase | Team Integration |
|---|---|
| Reproduce | QA provides bug reports with reproduction steps; request more detail if insufficient |
| Investigate | Architect can help map component dependencies and blast radius |
| Fix | Code review by a peer before merge — a second pair of eyes catches fix-induced regressions |
| Prevent | Post-mortem shared with the team; action items tracked in the backlog |

When using other code-virtuoso skills:

| Situation | Recommended Skill |
|---|---|
| Bug fix reveals design problems | Install `design-patterns-virtuoso` from `krzysztofsurdy/code-virtuoso` |
| Fix involves refactoring | Install `refactoring-virtuoso` from `krzysztofsurdy/code-virtuoso` |
| SOLID violation is root cause | Install `solid-virtuoso` from `krzysztofsurdy/code-virtuoso` |
| PR for the fix | Use `pr-message-writer` from `krzysztofsurdy/code-virtuoso` |

---

## Quality Checklist

Before marking a bug fix done:

- [ ] Root cause is identified and documented
- [ ] Failing test existed before the fix
- [ ] Fix addresses root cause, not symptom
- [ ] Full test suite passes
- [ ] Fix is the simplest correct solution
- [ ] Error messages improved where relevant
- [ ] Post-mortem written for significant bugs
- [ ] Team notified if the bug affects shared components

---

## Critical Rules

1. **No fix without root cause.** This is the iron law. If you cannot explain why the bug exists, you are not done investigating.

2. **Reproduce first.** Do not investigate what you cannot reproduce. If reproduction fails, add observability and wait.

3. **Single-variable testing.** Change one thing at a time during hypothesis testing. Changing multiple variables makes results uninterpretable.

4. **Evidence over intuition.** Log your evidence. "I think it might be X" is not a hypothesis — "Log line Y shows value Z when it should show W" is.

5. **Test before and after.** A fix without a regression test is a fix that will break again.

6. **Escalate without ego.** Knowing when to stop and ask for help is a skill, not a weakness. See the escalation criteria above.

7. **Document for the next person.** The next person debugging this area might be you in six months. Leave the codebase more observable than you found it.

8. **Never debug production by modifying production.** Read-only investigation. Fixes go through the normal deployment pipeline.

9. **Scope discipline.** Fix the bug. Only the bug. Other improvements are separate tickets.

10. **Share what you learn.** Every significant bug is a learning opportunity for the team. Post-mortems are not blame — they are institutional memory.

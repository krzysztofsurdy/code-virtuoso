---
name: tdd
description: "Red-green-refactor procedure: write the failing test first, show it fail, write the minimum code, refactor on green. Use for any bug fix or new behavior in code that has or could have tests, including 'fix this bug', 'add a function', 'use TDD' and 'write the test first'."
user-invocable: true
argument-hint: "[behavior to implement or bug to fix]"
---

# Test-driven development loop

Write one failing test, make it pass with the least code, clean up while the tests stay green, repeat. The loop is useful for agents for a specific reason: a test that has never failed proves nothing. If you only ever see tests pass, you cannot tell a test that checks the behavior from one that checks nothing. Watching the failure is what makes the later pass meaningful.

Each step produces evidence: command output you can quote. Without it the loop has not been run, only described.

For test strategy, the pyramid, and test-double theory (mocks, stubs, fakes, London versus Chicago school), see the `testing` skill. This playbook covers the procedure, not those concepts.

## Core principles

| Principle | Meaning |
|---|---|
| **No production code without a failing test first** | The test defines the behavior; the code only satisfies it |
| **One test at a time** | Small steps keep the cause of any failure obvious |
| **Show the red** | Run the test and read the failure. It must fail for the reason you expect |
| **Minimum code to green** | Write only what the current test needs. More code is untested code |
| **Refactor only on green** | Cleanup while red hides whether you broke something |
| **Test behavior, not implementation** | A test should survive a refactor that keeps behavior the same |

## Step 0: Prepare

1. Find the project's test command and how to run a single test (check `AGENTS.md`, `CLAUDE.md`, the `Makefile`, `package.json`, `composer.json`, CI config). Do not guess.
2. Run the existing suite once. Record the result. A suite that is already red must be understood before you add to it.
3. Pick the smallest behavior to start with. If a spec exists with requirement IDs and WHEN/THEN criteria (see `spec-driven-development`), each criterion is one or more tests.
4. Find the right seam (see below) and an existing test file in the same area to copy conventions from.

## The loop

### 1. Red: write one failing test

Write a single test for one behavior. Name it after the behavior (`rejects_expired_token`), not the method. Use arrange, act, assert, with one reason to fail.

Run only that test. Show the output. Check two things:

- It fails. If it passes, the behavior already exists or the test checks nothing; stop and find out which.
- It fails for the right reason: an assertion about the missing behavior, not a syntax error, missing import, wrong fixture, or setup crash. Fix the test until the failure message describes the missing behavior.

State in one line what the failure shows, for example "Expected 401, got 200: expired tokens are accepted."

### 2. Green: write the minimum code

Write the simplest code that makes this test pass, even if it looks naive. Returning a constant is allowed if only one test exists; the next test will force the general form. Do not add parameters, branches, or abstractions no test demands.

Run the single test. Show the output. Then run the surrounding suite and show that too. A passing test next to a newly broken one is not green.

### 3. Refactor: clean up on green

With all tests passing, remove duplication, improve names, simplify structure, in code and in tests. Run the tests after each small change and show the result. Never skip this step: green code written to pass one test usually needs shaping. Do not change behavior here; behavior changes start a new red.

### 4. Repeat

Pick the next behavior: another criterion, an edge case, an error path. Common ones: empty input, boundary values, invalid input, permission denied, upstream failure, duplicate request. When the list from the spec is done, commit (one logical change per commit, using the project's convention).

## Excuses to skip red

These are the reasons agents give for skipping the first step. Each has a response.

| Excuse | Response |
|---|---|
| "The change is trivial, a test is overkill" | Trivial code breaks too. If it is trivial, the test takes a minute. Write it |
| "I will add tests after" | Tests written after pass by construction and encode what the code does, not what it should do. Write the test first |
| "I know it will fail, no need to run it" | You do not know it fails for the right reason. Run it and read the output |
| "The test passed immediately, great" | A test that cannot fail is broken or redundant. Break the code on purpose and confirm it goes red, or find the existing behavior it duplicates |
| "It is hard to test" | That is design feedback. Find a seam, extract the logic, or write a characterization test. Do not skip |
| "I will write all the tests first, then all the code" | That is batch mode, and a bad first test will wreck all of them. One test, one pass, repeat |
| "Let me write the full implementation, I already see it" | You are writing untested code. Write the test for the first behavior and only that code |
| "The test suite is slow" | Run the single test during the loop and the suite at the end of each cycle. If one test is slow, the seam is too high |
| "This is just config, a script, or glue" | Test the behavior it produces, or state why no automated check exists and what you verified by hand, with output |
| "Mocking everything is faster" | Over-mocked tests pass while the system is broken. Use real collaborators unless they are slow, nondeterministic, or external (see `testing`) |
| "The existing test is wrong, I will just fix it" | Maybe. But follow the rule on editing tests below, and say so |
| "I am running out of time, I will skip refactor" | Refactor is where the design gets paid for. Skip it only by saying you skipped it, and add a task to do it |

If you notice yourself writing production code before a red test, delete it and start from the test. The deleted code will be rewritten faster and tighter.

## Test at the right seam

A seam is a place where you can observe behavior or substitute a dependency without editing the code under test. Pick the lowest seam that still exercises the behavior from the outside.

| Test at | Good for | Watch out for |
|---|---|---|
| Pure function or small class (unit) | Business rules, calculations, state machines, parsing | Testing private helpers; test through the public API |
| Module boundary or service with real collaborators | Behavior that spans two or three classes | Setup growing large: the unit is probably doing too much |
| Public interface of the system (HTTP, CLI, queue handler) | Wiring, serialization, auth, error mapping | Slow tests; keep these few and meaningful |
| External systems (database, clock, network, filesystem) | Cover the real adapter with a few integration tests | Faking at the wrong layer; fake the port, not internals |

Rules of thumb:

- Assert on outputs and observable state, not on which private methods ran.
- Inject the clock, randomness, and I/O so tests control them.
- If a test needs more than a few lines of setup, the code under test has too many dependencies. Treat that as a design signal.
- A test that breaks when you rename a private method but behavior is unchanged is coupled to implementation. Move it up a seam.

For doubles and school choices, see `testing`.

## Never edit a test just to make it pass

When a test fails after your change, decide which of these is true before touching anything:

1. **The code is wrong.** Fix the code. This is the usual case.
2. **The test encodes behavior that has intentionally changed** (by the spec, ticket, or user). Update the test, and say in your message which requirement changed and why.
3. **The test is wrong or flaky** (bad fixture, hidden order dependence, time dependence). Fix it, and say what was wrong and how you know.

Never loosen an assertion, delete a test, skip a test, or widen an expected value without writing one of those explanations. If you cannot say which case applies, stop and ask. A silently edited test is the most common way an agent turns a red suite green without fixing anything.

## Bug fixes

1. Reproduce the bug with a test that fails for the reported reason. Show the red. If you cannot reproduce it in a test, you do not yet understand the bug (see `debugging`).
2. Fix the cause, not the symptom. Show the green.
3. Keep the test as a regression test. Name it after the behavior, and reference the ticket or issue if the project does that.

## Legacy code with no tests

Do not refactor or change untested code blind. First pin what it does now:

1. Choose the seam closest to the change (see `references/legacy-and-characterization.md`).
2. Write a characterization test: call the code with a realistic input, assert whatever it returns today, run it, and keep that assertion even if the behavior looks wrong. The test records current behavior; it is not a judgment of it.
3. Cover the paths your change will touch: normal case, edge cases, error cases.
4. Now make your change in the normal loop: new failing test for the new behavior, minimum code, refactor.
5. Mark behavior that looks like a bug in a note or ticket. Do not fix it in the same change unless asked.

## When the loop gets stuck

| Symptom | Action |
|---|---|
| Cannot get the test to fail for the right reason | The setup is wrong; simplify the test until the failure message is about the behavior |
| Green needs a huge code change | The step was too big. Revert, write a smaller test |
| A test is hard to write | Look for a missing seam; extract the logic into a function you can call directly |
| Tests pass but the feature does not work | A test is missing at a higher seam: add an integration test for the real path |
| Two attempts to get green have failed | Stop guessing. Report what you tried and observed, and re-read the test and the code under it |
| Unrelated failure appears | Note it, do not fix it in this change, and tell the user |

## Quick checklist

- [ ] Test command found, baseline suite run and recorded
- [ ] Each behavior: one test, red output shown, failure reason matches
- [ ] Minimum code written; single test and surrounding suite green, output shown
- [ ] Refactor done on green, tests re-run
- [ ] No test edited without a stated reason
- [ ] Bug fixes keep a regression test
- [ ] Legacy changes started with characterization tests
- [ ] Final full suite, lint, and static analysis output captured (`verification-before-completion`)

## Reference files

| Reference | Contents |
|---|---|
| [legacy-and-characterization](references/legacy-and-characterization.md) | Finding seams in untested code, writing characterization tests, safe first moves |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Choosing a test strategy, doubles, London versus Chicago | `testing` |
| Implementing tasks from a spec and task list | `spec-driven-development` |
| A test fails and the cause is unclear | `debugging` |
| Cleaning up after green, naming refactorings | `refactoring` |
| Claiming the work is done | `verification-before-completion` |
| Running the loop inside a full ticket workflow | `ticket-delivery` |

---
name: verification-before-completion
description: Evidence-based completion discipline. Use before claiming any work is 'done', complete, finished, or ready — whether it is code, config, documentation, a migration, or a bugfix. Requires running verification commands (tests, lints, type checks, builds, smoke tests), capturing output, and citing concrete evidence rather than assertions. Covers tiered definitions of done, evidence patterns, verification checklists by task type, and common fake-completion failure modes. Triggers: 'done', 'finished', 'complete', 'ready', 'should work', 'it's working now', before closing a task, before writing a PR.
user-invocable: false
allowed-tools: Read Grep Glob Bash
---

# Verification Before Completion

Discipline for proving work is done rather than asserting it. Every completion claim must be backed by captured output from verification commands executed in the current session. This skill exists because the most expensive bugs are not the ones that fail loudly — they are the ones that ship behind a confident "it works."

## Iron Law

**No "done" without evidence. Assertions are not evidence.**

If you have not run a verification command and read its output in this session, you cannot claim the work passes. "Should work" is not a status. "I believe it's correct" is not a test result. The only acceptable proof is captured output from an executed command.

## Why This Matters

False completion is more costly than incomplete work. Incomplete work is visible — someone will finish it. False completion is invisible — it passes review, merges, deploys, and fails in production. Every minute spent on proper verification saves hours of debugging, rollback, incident response, and trust repair. The cost of catching a defect multiplies by orders of magnitude at each stage: local development, code review, staging, production. Verify early, verify often, verify with evidence.

## Core Principles

| Principle | Meaning |
|---|---|
| **Evidence over assertion** | A claim is only as strong as the output backing it. No output, no claim. |
| **Fresh over stale** | Only verification run in the current session counts. Previous runs prove nothing about current state. |
| **Complete over partial** | Running one test file does not verify the suite. Running the linter does not verify the build. Each check covers its own surface. |
| **Captured over remembered** | Paste the output. Do not summarize from memory. Memory lies. |
| **Exit code over log lines** | A command that prints "OK" but exits non-zero has failed. Always check the exit code. |
| **Automated over manual** | A reproducible command beats "I checked it manually" every time. |

## Tiered Definition of Done

Work passes through multiple tiers before it is truly done. Each tier has its own evidence requirements. See [done-definitions](references/done-definitions.md) for the full breakdown.

| Tier | What It Means | Minimum Evidence |
|---|---|---|
| **Local done** | Works on the development machine | Tests pass, linter clean, type checker clean, build succeeds — all with captured output |
| **Review-ready done** | Safe for a peer to evaluate | Local done + changes committed, PR description matches actual changes, no untracked files |
| **Merged done** | Accepted into the main branch | Review-ready done + CI pipeline green, reviewer approved, no merge conflicts |
| **Deployed done** | Running in a target environment | Merged done + deployment command succeeded, health check returns expected status |
| **Verified-in-production done** | Confirmed working for real users | Deployed done + smoke tests pass against live environment, key metrics stable, no new errors in logs |

## The Verification Cycle

Run this cycle before every completion claim.

### Phase 1: Identify Verification Surface

Determine what needs to be verified based on what changed.

- List every file modified, added, or deleted
- Map each change to its verification category (code, config, schema, docs, infra)
- Identify the minimum set of commands that covers all changed surfaces
- If unsure what to verify, verify everything — over-verification costs minutes, under-verification costs hours

### Phase 2: Run Verification Commands

Execute every required command. Do not skip any.

- Run commands in the project root unless they require a specific directory
- Use the project's own scripts and configuration — do not invent custom verification
- Run the full suite, not a subset, unless the full suite takes more than 5 minutes (then run targeted + note that full suite is deferred)
- Capture both stdout and stderr

### Phase 3: Capture Output

Record the raw output from every command.

- Include the exact command that was run
- Include the full output (or the summary section for large outputs)
- Include the exit code
- Timestamp is implicit in the current session — do not fabricate timestamps

### Phase 4: Compare to Expected

Verify that the output matches success criteria.

- All tests pass (zero failures, zero errors, zero skipped unless pre-existing)
- Zero lint errors (zero warnings for strict projects)
- Type checker reports zero errors
- Build exits with code 0 and produces expected artifacts
- If any check fails, the work is NOT done — fix the issue and restart from Phase 2

### Phase 5: Cite Evidence in Claim

Reference the captured output when claiming completion.

- State which commands were run
- State the result of each (pass count, exit code, key output lines)
- If any caveats exist (pre-existing failures, skipped checks, known issues), state them explicitly
- Never use language that hides uncertainty — see [Language to Avoid](#language-to-avoid)

## What Counts as Evidence

See [evidence-patterns](references/evidence-patterns.md) for the complete reference.

| Evidence (valid) | Non-evidence (invalid) |
|---|---|
| Test runner output: `42 passed, 0 failed` | "Tests should pass" |
| Linter output: `0 errors, 0 warnings` | "I ran the linter" (no output shown) |
| Build log ending with exit code 0 | "The build looks fine" |
| HTTP response: `200 OK` with expected body | "The endpoint works" |
| Type checker: `Found 0 errors` | "Types are correct" |
| Deployment log: `Successfully deployed v2.3.1` | "I deployed it" |
| Diff showing expected file changes | "I made the changes" |
| Screenshot of UI in expected state | "The UI looks right" |

## Verification by Task Type

Different changes require different verification. See [verification-checklist](references/verification-checklist.md) for complete checklists per task type.

| Task Type | Required Checks |
|---|---|
| **Code change** | Tests, linter, type checker, build |
| **Configuration change** | Validation command, application startup, affected feature smoke test |
| **Database/schema change** | Migration runs forward, migration rolls back, application starts, affected queries work |
| **Infrastructure change** | Deployment succeeds, health checks pass, smoke tests pass, rollback tested |
| **Documentation change** | Links resolve, code examples execute, formatting renders correctly |
| **Dependency update** | Lock file updated, install succeeds, full test suite passes, build succeeds |
| **Bug fix** | Failing test reproduced the bug BEFORE fix, test passes AFTER fix, regression suite clean |

## Common Fake-Completion Patterns

See [failure-modes](references/failure-modes.md) for the full catalog.

| Pattern | Why It Fools People | What Actually Happened |
|---|---|---|
| **Compile-checked, not run** | "It compiles" feels like progress | Syntax is valid but logic is wrong — runtime behavior untested |
| **Partial test run** | "Tests pass" is technically true — for the 3 you ran | The other 200 tests might be broken by your change |
| **Stale cache** | Output looks right | You are seeing cached results from before your change |
| **Mocked-out integration** | Unit tests pass | The real service returns a different format than your mock |
| **Wrong environment** | "Works on my machine" | Config, data, or dependencies differ in staging/production |
| **Exit code ignored** | Log output looks normal | The command actually returned non-zero — it failed |
| **Self-reported success** | "I verified it" | No output captured, no command shown, no evidence provided |
| **Premature celebration** | "It works!" after the first positive signal | One passing test does not mean the feature is complete |

## Language to Avoid

| Banned Phrase | Why It Fails | Preferred Alternative |
|---|---|---|
| "Should work" | Prediction, not evidence | "Ran `npm test`, exit code 0, 47/47 passed" |
| "I believe it's correct" | Belief is not verification | "Type checker reports 0 errors" |
| "Looks good" | Visual impression, not a test | "Linter output: 0 errors, 0 warnings" |
| "I ran it" | Claim without output | "Ran `pytest -v`, output: 23 passed in 1.4s" |
| "It's working now" | Status without proof | "Health check returns 200, response body contains expected fields" |
| "I tested it" | Vague, unverifiable | "Ran `go test ./...`, 156 tests passed, 0 failed" |
| "Everything passes" | Unsubstantiated universal claim | "CI pipeline green: lint, type-check, test, build — all exit 0" |
| "Fixed" | Conclusion without evidence | "Failing test now passes. Regression suite: 312/312 green." |
| "Done" (alone) | Completion without criteria | "All verification checks pass. See output above." |

## Quality Checklist

Before claiming any work is complete:

- [ ] All modified files are identified
- [ ] Verification commands are identified for each change type
- [ ] Every verification command has been run (not recalled from memory — run fresh)
- [ ] Output from every command is captured and visible
- [ ] All tests pass with zero failures
- [ ] Linter reports zero errors
- [ ] Type checker reports zero errors (if applicable)
- [ ] Build succeeds with exit code 0 (if applicable)
- [ ] No untracked or uncommitted files that should be included
- [ ] No language from the "Language to Avoid" table appears in the completion claim
- [ ] Any caveats, known issues, or deferred checks are explicitly stated
- [ ] Evidence is cited, not asserted

## Critical Rules

1. **Run before you claim.** Every verification command must be executed in the current session. Output from a previous session, a previous branch, or a previous version of the code is not evidence.

2. **Capture everything.** Paste output, do not paraphrase it. "Tests pass" is a claim. "Ran `cargo test`, 89 passed, 0 failed" is evidence.

3. **Check exit codes.** A command that prints friendly output but exits non-zero has failed. Always verify the exit code, not just the log output.

4. **Full suite, not cherry-picked.** Run the complete test suite, not just the tests for the file you changed. Your change may break something elsewhere.

5. **No self-certification.** "I verified it" without captured output is worth zero. The evidence must be visible to anyone reading the completion claim.

6. **Caveats are mandatory.** If any check was skipped, any test was ignored, or any known issue remains, state it explicitly. Hidden caveats are lies by omission.

7. **Failures mean not done.** If any verification command fails, the work is not complete. Fix the failure and re-run. There is no "done except for that one failing test."

8. **Fresh over stale.** If you made any change after the last verification run — even a one-character fix — re-run all verification. The last change is the one that breaks things.

9. **Verification is not optional overhead.** It is the work. Code without verification is a draft, not a delivery.

10. **When in doubt, verify more.** Over-verification wastes minutes. Under-verification wastes days.

## Reference Files

| Reference | Contents |
|---|---|
| [verification-checklist](references/verification-checklist.md) | Step-by-step checklists by task type: code, config, schema, infra, docs, dependency updates |
| [evidence-patterns](references/evidence-patterns.md) | What counts as evidence vs. what does not. Concrete examples across stacks. |
| [failure-modes](references/failure-modes.md) | Catalog of fake-completion patterns: how agents and humans skip verification and get away with it (temporarily) |
| [done-definitions](references/done-definitions.md) | Multi-tiered definition of done from local to production-verified, with evidence requirements per tier |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Writing tests before implementation | `testing` |
| Systematic bug investigation before claiming fix | `debugging` |
| Reviewing code quality after verification passes | `refactoring` |
| Writing PR description after all checks pass | `pr-message-writer` |
| Ensuring CI pipeline covers all verification tiers | `cicd` |
| Checking security implications before marking done | `security` |
| Verifying performance impact of changes | `performance` |

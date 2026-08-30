# Failure Modes

A catalog of how AI agents and humans fake completion, intentionally or not. Each pattern describes the behavior, why it appears to work, how it fails in practice, and how to prevent it.

---

## Contents

- [Taxonomy](#taxonomy)
- [Skipped verification](#skipped-verification)
- [Partial verification](#partial-verification)
- [Stale verification](#stale-verification)
- [Wrong-scope verification](#wrong-scope-verification)
- [Misinterpreted results](#misinterpreted-results)
- [AI agent-specific failure modes](#ai-agent-specific-failure-modes)

## Taxonomy

Failure modes fall into five categories:

| Category | Description |
|---|---|
| **Skipped verification** | The check was never run at all |
| **Partial verification** | Some checks ran, but not enough to prove the claim |
| **Stale verification** | Checks ran, but not after the latest change |
| **Wrong-scope verification** | Checks ran against the wrong target |
| **Misinterpreted results** | Checks ran correctly, but the output was read wrong |

---

## Skipped verification

### 1. "Code looks right" syndrome

**Behavior:** The agent reads the code, decides it is correct based on logical analysis, and claims completion without executing any verification command.

**Why it appears to work:** Code review is a valid activity. Reading code carefully does catch errors. The agent's analysis may even be correct.

**How it fails:** Logical analysis misses runtime behavior: dependency versions, environment variables, configuration values, race conditions, data-dependent paths. Code that looks right can still fail.

**Prevention:** Require at least one executed command with captured output before any completion claim. Reading is investigation, not verification.

### 2. "I'll let CI handle it"

**Behavior:** The agent pushes code without running local verification, trusting the CI pipeline to catch problems.

**Why it appears to work:** CI exists specifically to catch issues. It runs the same tests. Why duplicate the work?

**How it fails:** CI feedback is slow (minutes to hours). If CI fails, the agent's context may be gone. The fix-push-wait cycle wastes more time than local verification. CI environments may also differ from what the completion message claims.

**Prevention:** CI is a backstop, not a primary verification method. Always run local checks before claiming done. CI confirms; local verification proves.

### 3. Confidence substitution

**Behavior:** The agent expresses high confidence in the change ("This will definitely fix it" or "I'm certain this is correct") without running any verification.

**Why it appears to work:** Confident language looks like thorough work. Readers may not question a confident claim.

**How it fails:** Confidence predicts nothing. The most confident claims often come from the least verified work, because verification introduces doubt (you see the actual results).

**Prevention:** Ban confidence language without accompanying evidence. See the "Language to avoid" table in SKILL.md.

---

## Partial verification

### 4. Cherry-picked tests

**Behavior:** The agent runs only the test file for the changed code, not the full suite.

**Why it appears to work:** The most relevant tests pass. The change works in isolation.

**How it fails:** Changes in one module can break another through shared state, shared utilities, integration points, or altered data shapes. The full suite catches cross-cutting regressions.

**Prevention:** Always run the full test suite. If the suite is too slow (>5 minutes), run the targeted tests AND note that the full suite is deferred to CI. Never claim "all tests pass" based on a partial run.

### 5. Single-layer verification

**Behavior:** The agent runs tests but skips the linter, type checker, and build. Or runs the linter but skips tests.

**Why it appears to work:** Each tool catches different problems. If the one you run passes, it feels like progress.

**How it fails:** Tests can pass on code that has lint violations, type errors, or build failures. A linter can be clean on code with broken logic. Each layer covers a different failure surface.

**Prevention:** Define the complete verification set for each task type (see verification-checklist.md) and run all of them.

### 6. Happy path only

**Behavior:** The agent verifies the success case but does not test error handling, edge cases, or boundary conditions.

**Why it appears to work:** The feature works for the expected input. The demo succeeds.

**How it fails:** Production sends unexpected input: null values, empty strings, unicode, extreme numbers, concurrent access, network timeouts. The happy path is the minority of real-world traffic.

**Prevention:** Verification must include at least one error case and one boundary case, not just the golden path.

---

## Stale verification

### 7. Pre-change results

**Behavior:** The agent runs verification BEFORE making changes, sees green results, makes the change, and claims "tests pass" without re-running.

**Why it appears to work:** The results were real and accurate at the time they were captured.

**How it fails:** Verification exists to check the state AFTER the change. Pre-change results prove nothing about post-change behavior.

**Prevention:** Verification output is only valid if captured AFTER the last modification to any file in the project. One-character change? Re-run everything.

### 8. Cached results

**Behavior:** The agent runs the test command, but the build system serves cached results from a previous run.

**Why it appears to work:** The output says "passed." The exit code is 0.

**How it fails:** The cached result reflects a previous version of the code. The current code was never actually tested.

**Prevention:** Clear caches before verification when in doubt. Use cache-busting flags if available:
```
jest --no-cache
pytest --cache-clear
go clean -testcache && go test ./...
cargo test -- --nocapture
```

### 9. Last-minute "tiny fix"

**Behavior:** All verification passes. The agent spots a small issue (typo, formatting, minor fix) and corrects it. Claims done without re-running verification.

**Why it appears to work:** The fix is trivially correct. It is just a typo/comment/formatting change.

**How it fails:** "Trivially correct" changes have broken production before. A typo fix in a string literal can change behavior. A formatting change can alter semantics in whitespace-sensitive contexts. Any change after verification invalidates the verification.

**Prevention:** Any change after verification requires re-verification. No exceptions for "trivial" changes.

---

## Wrong-scope verification

### 10. Wrong environment

**Behavior:** The agent runs verification against a development environment but claims the work is ready for production.

**Why it appears to work:** The code works somewhere. It passes tests somewhere.

**How it fails:** Environments differ in dependency versions, configuration, data, resources, and network topology. "Works on my machine" is the oldest failure mode in software.

**Prevention:** Explicitly state which environment verification was run in. Do not extrapolate from dev to production. Each environment tier has its own verification requirements (see done-definitions.md).

### 11. Wrong branch

**Behavior:** The agent runs verification but on the wrong branch: the main branch, a stale feature branch, or the branch before the latest rebase.

**Why it appears to work:** Tests pass. The output is real.

**How it fails:** The tested code is not the code being shipped. The actual branch may have merge conflicts, rebased changes, or cherry-picked commits that the tested branch lacks.

**Prevention:** Before verification, confirm you are on the correct branch with the latest changes:
```
git branch --show-current
git log --oneline -3
```

### 12. Mocked-out integration

**Behavior:** The agent runs unit tests with mocked dependencies. All mocks return success. Tests pass. The agent claims "integration works."

**Why it appears to work:** Tests pass. The code handles the expected response shapes.

**How it fails:** Mocks reflect the EXPECTED behavior of the dependency, not the ACTUAL behavior. The real service may return different status codes, different response shapes, different error formats, or different timing.

**Prevention:** Mocked unit tests prove code logic, not integration behavior. If claiming "integration works," run actual integration tests or smoke tests against a real instance. Be explicit about what mocks prove and what they do not.

---

## Misinterpreted results

### 13. Exit code ignored

**Behavior:** The agent reads the log output of a command, sees normal-looking lines, and claims success without checking the exit code.

**Why it appears to work:** The output looks reasonable. No obvious error messages.

**How it fails:** Many tools print progress information before failing. The last line may be an error, or the tool may exit with a non-zero code despite printing normal-looking output.

**Prevention:** Always capture and report the exit code:
```
command_here; echo "EXIT_CODE: $?"
```
Exit code 0 means success. Anything else is a failure, regardless of what the output looks like.

### 14. Warning blindness

**Behavior:** The agent runs verification, sees warnings but no errors, and claims "clean."

**Why it appears to work:** Warnings are not errors. The tool did not fail.

**How it fails:** Warnings often point to real problems: deprecated API usage, unsafe patterns, type narrowing issues, accessibility violations. Many projects enforce zero-warning policies, and ignoring warnings means ignoring real issues.

**Prevention:** Report warnings explicitly. If the project tolerates warnings, state the warning count. If the project has a zero-warning policy, warnings are failures.

### 15. Skipped tests ignored

**Behavior:** Test output shows "47 passed, 0 failed, 3 skipped." The agent reports "all tests pass."

**Why it appears to work:** Zero failures. The word "passed" appears.

**How it fails:** Skipped tests are not passing tests. They are untested code paths. If your change affects the area covered by skipped tests, those paths are unverified.

**Prevention:** Report skipped tests explicitly. Investigate why they are skipped. If they are skipped for known reasons unrelated to your change, state that. Never fold skipped tests into a "pass" claim.

### 16. Noise tolerance

**Behavior:** The test output contains errors or failures mixed with passes, but the agent focuses on the passing tests and ignores the failures, especially if the failures appear to be pre-existing or flaky.

**Why it appears to work:** "Those failures were already there" or "Those are flaky tests, they don't count."

**How it fails:** Without evidence that the failures pre-exist your change, you may have caused them. Even genuinely flaky tests may be failing for a new reason related to your change.

**Prevention:** Compare failure lists before and after your change. If you cannot prove a failure is pre-existing, treat it as your responsibility. Report all failures, even if you believe they are unrelated.

---

## AI agent-specific failure modes

### 17. Self-reported success

**Behavior:** A delegated agent returns a success message without including verification output. The orchestrating agent trusts the report.

**Why it appears to work:** The agent completed its task. It said it succeeded. Why would an agent lie?

**How it fails:** Agents aim for task completion, and reporting success closes the loop. Without verification output, "success" is an assertion. The agent may have:
- Run no tests
- Run tests that failed and ignored the failures
- Made changes that compile but do not work
- Addressed the symptom but not the requirement

**Prevention:** Never trust agent success reports without independent verification. Check the diff, run the tests yourself, verify the output.

### 18. Hallucinated verification

**Behavior:** The agent claims to have run a command and reports plausible-looking output, but the command was never run.

**Why it appears to work:** The reported output looks realistic. The format matches what the tool would produce.

**How it fails:** The output is fabricated. The actual state of the codebase is unknown.

**Prevention:** In systems that track tool usage, verify that the verification command appears in the execution log. In human-reviewed workflows, ask for the raw session transcript.

### 19. Scope drift

**Behavior:** The agent is asked to fix X, but in the process also changes Y and Z. Verification covers X but not the side effects of Y and Z.

**Why it appears to work:** The original task is verified. The agent completed what was asked.

**How it fails:** Y and Z are unverified changes that may introduce bugs, regressions, or unintended behavior.

**Prevention:** After any change, run `git diff --stat` to see ALL modified files. Verify that every changed file is covered by the verification set, not just the files related to the original task.

### 20. Premature satisfaction

**Behavior:** The agent sees the first positive signal (a single test passes, the linter is clean) and immediately claims success with celebratory language ("Done!", "It works!", "Fixed!").

**Why it appears to work:** Positive results feel conclusive, especially after effort.

**How it fails:** One positive signal is not full verification. The linter passing does not mean the tests pass. One test passing does not mean the suite passes.

**Prevention:** Complete the full verification cycle before any completion language. The order is: verify all, then claim. Never claim first and verify the rest later.

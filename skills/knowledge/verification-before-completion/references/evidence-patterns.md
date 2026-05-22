# Evidence Patterns

What counts as evidence that work is done — and what does not. Evidence is captured output from an executed command. Everything else is assertion.

---

## The Evidence Rule

Evidence must be:

1. **Produced** — a command was actually executed
2. **Captured** — the output is visible, not just remembered
3. **Current** — from the current session, after the latest change
4. **Complete** — covers the full verification surface, not a subset
5. **Interpretable** — someone else can read it and reach the same conclusion

If any of these properties is missing, it is not evidence.

---

## Valid Evidence by Category

### Test Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Test runner summary with counts | `42 passed, 0 failed, 0 skipped` | All tests in scope pass |
| Individual test output (verbose) | `PASS src/auth.test.js (2.1s)` | Specific test file passes |
| Exit code | `echo $?` returns `0` | Command completed successfully |
| Coverage report | `Statements: 87.3%, Branches: 72.1%` | Coverage level (not correctness, but completeness of test surface) |

**Multi-stack examples:**

```
# JavaScript/TypeScript
$ npm test
> jest --coverage
Tests:  42 passed, 0 failed
Exit code: 0

# Python
$ pytest -v
23 passed in 1.4s
Exit code: 0

# Go
$ go test ./...
ok  mymodule/pkg/auth  0.034s
ok  mymodule/pkg/api   0.089s
Exit code: 0

# Rust
$ cargo test
running 67 tests
test result: ok. 67 passed; 0 failed; 0 ignored
Exit code: 0

# Ruby
$ bundle exec rspec
45 examples, 0 failures
Exit code: 0

# Java/Kotlin
$ ./gradlew test
BUILD SUCCESSFUL in 12s
Exit code: 0
```

### Lint Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Linter summary | `0 errors, 0 warnings` | Code meets style and quality rules |
| Clean output (no lines) | `$ eslint . && echo "clean"` -> `clean` | No violations detected |
| Exit code 0 | Command completed without error | Linter passed |

**Multi-stack examples:**

```
# JavaScript
$ eslint .
# (no output = clean)
Exit code: 0

# Python
$ ruff check .
All checks passed!
Exit code: 0

# Go
$ golangci-lint run
# (no output = clean)
Exit code: 0

# Rust
$ cargo clippy - -D warnings
# (no output = clean)
Exit code: 0
```

### Type Check Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Type checker summary | `Found 0 errors in 47 files` | No type errors in the codebase |
| Exit code 0 | Command completed successfully | Type system is satisfied |

**Multi-stack examples:**

```
# TypeScript
$ tsc --noEmit
# (no output = clean)
Exit code: 0

# Python (mypy)
$ mypy .
Success: no issues found in 23 source files
Exit code: 0

# Python (pyright)
$ pyright
0 errors, 0 warnings, 0 informations
Exit code: 0
```

### Build Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Build success message | `Build succeeded` | Compilation and bundling completed |
| Artifact exists | `ls dist/bundle.js` shows file | Build produced expected output |
| Exit code 0 | Build command completed | Build pipeline passed |

### HTTP / API Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Status code | `HTTP/1.1 200 OK` | Endpoint responds with expected status |
| Response body | `{"status":"healthy","version":"2.3.1"}` | Response contains expected data |
| Response headers | `Content-Type: application/json` | Response format is correct |
| Timing | `time_total: 0.043s` | Response time is acceptable |

**Example verification command:**

```
$ curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost:8080/api/users/1
{"id":1,"name":"test","email":"test@example.com"}
HTTP_CODE:200
```

### Deployment Results

| Evidence Format | Example | What It Proves |
|---|---|---|
| Deployment log | `Deployed v2.3.1 to production` | Deployment command succeeded |
| Health check response | `{"status":"UP"}` | Service is running and responding |
| Pod/container status | `Running  1/1  Age: 30s` | Container started and is stable |
| Version endpoint | `{"version":"2.3.1"}` | Correct version is deployed |

### Git State

| Evidence Format | Example | What It Proves |
|---|---|---|
| `git status` output | `nothing to commit, working tree clean` | All changes are committed |
| `git diff --stat` output | `3 files changed, 47 insertions(+), 12 deletions(-)` | Scope of changes is known |
| `git log --oneline -3` | Shows recent commits | Commit history is clean |

---

## Invalid Evidence (Non-Evidence)

These are common assertions that sound like evidence but prove nothing.

### Self-Assertions

| Statement | Why It Fails |
|---|---|
| "I tested it" | No command shown, no output captured. Unverifiable. |
| "I ran the tests" | Which tests? What was the result? Where is the output? |
| "I checked and it works" | Checked how? Works according to what criteria? |
| "I verified the fix" | Verification without output is an assertion, not evidence. |

### Predictions

| Statement | Why It Fails |
|---|---|
| "Should work" | Prediction about the future. Not a measurement of the present. |
| "Should be fine" | Optimism is not a verification strategy. |
| "This will fix it" | Confidence in a change is not proof of its correctness. |
| "No issues expected" | Expectation is not observation. |

### Vague Summaries

| Statement | Why It Fails |
|---|---|
| "Tests pass" | Which tests? How many? Show the output. |
| "Build is clean" | What was the build command? What was the exit code? |
| "Looks correct" | Visual inspection is not systematic verification. |
| "Everything works" | Universal claims require universal evidence. |

### Past Tense Without Current Proof

| Statement | Why It Fails |
|---|---|
| "It was working earlier" | Earlier is not now. Changes since then invalidate earlier results. |
| "Tests passed before my change" | Your change is exactly what needs to be tested. |
| "The CI was green on the last commit" | This commit is different from the last commit. |

### Delegated Trust

| Statement | Why It Fails |
|---|---|
| "The CI will catch it" | CI is a safety net, not a substitute for local verification. |
| "The reviewer will check" | Code review catches logic issues, not missing tests. |
| "The QA team will test it" | QA verifies acceptance criteria, not that your code compiles. |
| "The other agent said it passed" | Agent reports are claims that need independent verification. |

---

## Evidence Strength Tiers

Not all evidence is equally strong. Prefer higher tiers.

| Tier | Type | Example | Strength |
|---|---|---|---|
| 1 | Automated test suite (full) | `pytest: 156 passed, 0 failed` | Strongest — reproducible, comprehensive |
| 2 | Automated single check | `eslint: 0 errors` | Strong — reproducible, focused |
| 3 | Command output (manual) | `curl: HTTP 200, body matches` | Moderate — reproducible but not automated |
| 4 | Log inspection | "Deploy log shows version 2.3.1" | Weak — depends on log fidelity |
| 5 | Visual inspection | "UI renders correctly" | Weakest — subjective, not reproducible |

Tier 1-2 evidence is required for completion claims. Tier 3 supplements but does not replace automated checks. Tier 4-5 is additional context, never sufficient on its own.

---

## Combining Evidence

A complete verification claim combines multiple evidence types:

```
Verification complete:
- Tests: `npm test` — 47 passed, 0 failed, exit code 0
- Lint: `eslint .` — 0 errors, 0 warnings, exit code 0  
- Types: `tsc --noEmit` — 0 errors, exit code 0
- Build: `npm run build` — succeeded, exit code 0
- Smoke: `curl localhost:3000/health` — 200 OK, {"status":"healthy"}
```

This is evidence. The reader can verify every claim. Compare to:

```
Everything works. Tests pass, lint is clean, and the build succeeds.
```

This is assertion. The reader must trust the author. Trust is not a verification strategy.

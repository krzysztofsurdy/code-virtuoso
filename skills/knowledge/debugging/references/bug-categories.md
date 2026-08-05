# Bug Categories

Investigation strategies by bug type. Each category has distinct symptoms, root causes, and investigation techniques. Identify the category early, because it determines your debugging approach.

---

## Contents

- [Logic errors](#logic-errors)
- [Data issues](#data-issues)
- [State and race conditions](#state-and-race-conditions)
- [Integration failures](#integration-failures)
- [Performance issues](#performance-issues)
- [Environment issues](#environment-issues)
- [Intermittent and flaky bugs](#intermittent-and-flaky-bugs)

## Logic errors

**Typical symptoms**: Wrong output for specific inputs, incorrect behavior on edge cases, "works for most users but not this one."

**Common root causes**:
- Incorrect conditional logic (wrong operator, inverted condition)
- Off-by-one errors in loops, ranges, or indexing
- Missing edge cases (empty input, null, zero, negative, boundary values)
- Wrong operator precedence or short-circuit evaluation assumptions
- Incorrect algorithm implementation

**Investigation steps**:
1. Read the code line by line. Do not skim. Trace the exact failing input through every branch.
2. Build a truth table for complex conditionals and enumerate all combinations.
3. Rubber duck the algorithm: explain each step out loud. Where does your explanation diverge from the code?
4. Test boundary values: zero, one, empty, max, min, null.
5. Compare against the specification: is the code wrong, or is the spec ambiguous?

**Common mistakes**: Assuming the logic is correct because it "looks right." Trusting that similar code elsewhere works the same way.

**Prevention**: Property-based testing, boundary value test cases, code review focused on logic paths.

---

## Data issues

**Typical symptoms**: Null pointer exceptions, type errors, garbled output, truncated data, "works in dev but not with real data."

**Common root causes**:
- Null or undefined where a value is expected
- Type mismatch (string where number expected, wrong date format)
- Encoding problems (UTF-8 vs Latin-1, URL encoding, HTML entities)
- Data truncation (field too short, integer overflow)
- Serialization/deserialization mismatches (JSON, XML, binary formats)
- Stale or corrupt data in storage

**Investigation steps**:
1. Log the actual data at every boundary crossing: entry point, service call, database query, external API.
2. Compare actual shape vs expected shape at each step. Where does it diverge?
3. Check serialization round-trips: serialize then deserialize and compare.
4. Inspect raw data in storage directly. Do not trust the application's reading layer.
5. Test with production-like data, not just test fixtures.

**Common mistakes**: Only checking the "happy path" data shape. Assuming upstream data is always valid. Not logging the actual value that caused the failure.

**Prevention**: Input validation at every boundary, schema validation, strict typing, data contract tests.

---

## State and race conditions

**Typical symptoms**: Intermittent failures, "works when I step through the debugger," different results under load, data corruption that appears randomly.

**Common root causes**:
- Shared mutable state accessed without synchronization
- Timing dependencies between operations assumed to be sequential
- Stale cache not invalidated after writes
- Incorrect initialization order
- Concurrent modifications to the same resource
- Assumptions about event ordering that do not hold under load

**Investigation steps**:
1. Add timestamps to every state mutation and build a timeline of what happened and when.
2. Draw a sequence diagram of the expected vs actual order of operations.
3. Look for shared mutable state: any variable, cache, or resource accessed by multiple threads/processes/requests.
4. Reproduce under load. Stress testing raises the probability of timing-dependent bugs.
5. Check for atomicity: are multi-step operations atomic, or can they be interrupted?
6. Review locking and synchronization: are locks acquired in a consistent order? Are there deadlock risks?

**Common mistakes**: Dismissing intermittent failures as "flaky." Adding sleep/delay as a "fix." Testing only with single-user scenarios.

**Prevention**: Minimize shared mutable state, use immutable data structures, design for concurrency from the start, add concurrency tests.

---

## Integration failures

**Typical symptoms**: "Works in isolation but fails when connected," HTTP errors, timeout errors, unexpected response formats, authentication failures.

**Common root causes**:
- API contract violations (changed endpoint, different response format, new required field)
- Version mismatches between services
- Network timeouts or connectivity issues
- Authentication/authorization configuration errors
- Incorrect error handling of external responses (only handling the happy path)
- Missing retry logic for transient failures

**Investigation steps**:
1. Log the full request AND response at the integration boundary: headers, body, status code, timing.
2. Verify the contract. Is the API documentation accurate? Has the external service changed?
3. Test the integration point in isolation. Use curl, Postman, or a test script to call the external service directly.
4. Check error handling paths. What happens when the external service returns 400? 500? Times out? Returns malformed data?
5. Review recent deployments of BOTH sides of the integration.

**Common mistakes**: Only testing the happy path of external calls. Assuming external services are always available and always return valid data. Not logging enough context on failure.

**Prevention**: Contract tests, integration test suites, circuit breakers, error handling for every failure mode, response validation.

---

## Performance issues

**Typical symptoms**: Slow responses, high CPU/memory usage, timeouts under load, gradual degradation over time.

**Common root causes**:
- Slow database queries (missing indexes, N+1 queries, full table scans)
- Memory leaks (objects never released, growing caches without eviction)
- Blocking I/O on the critical path
- Excessive computation (unnecessary loops, redundant calculations)
- Missing caching where repeated computation is expensive
- Inefficient algorithms that do not scale with data size

**Investigation steps**:
1. Profile FIRST. Never guess where the bottleneck is. Use a profiler, flame graphs, or query analyzer.
2. Identify the hot path: where is most time/memory being spent?
3. Measure with production-scale data. Performance with 10 rows tells you nothing about performance with 10 million.
4. Check database query plans. Are indexes being used? Are there sequential scans?
5. Measure before AND after any change. Quantify the improvement, do not rely on "feels faster."

**Common mistakes**: Optimizing without profiling. Optimizing the wrong thing. Caching as a first resort instead of fixing the underlying query/algorithm. Premature optimization of code that is not on the hot path.

**Prevention**: Performance budgets, load testing in CI, query analysis tools, monitoring dashboards with alerting thresholds.

---

## Environment issues

**Typical symptoms**: "Works on my machine," fails only in specific environments, deployment failures, permission errors, "nothing changed but it broke."

**Common root causes**:
- Missing or wrong dependency versions
- Configuration differences between environments
- File system permissions or path differences
- Platform-specific behavior (OS, runtime version, architecture)
- Missing environment variables or secrets
- Infrastructure changes (DNS, networking, certificates)

**Investigation steps**:
1. Compare working vs broken environments SYSTEMATICALLY. Do not assume you know the difference.
2. Check every variable: runtime version, dependency versions, OS version, configuration values, environment variables.
3. Review recent infrastructure or deployment changes. Even if "nothing changed," something did.
4. Try to reproduce the exact environment locally (containers help).
5. Check permissions, disk space, network connectivity, certificate expiration.

**Common mistakes**: Assuming environments are identical. Not versioning configuration. Relying on implicit environment setup that is not documented.

**Prevention**: Infrastructure as code, containerization, environment parity, automated environment validation, dependency lockfiles.

---

## Intermittent and flaky bugs

**Typical symptoms**: Fails sometimes, passes other times. No obvious pattern. "Could not reproduce."

**Common root causes**:
- Timing or race conditions (see State and race conditions above)
- External service instability
- Resource contention (disk, network, connections)
- Data-dependent edge cases that appear only with specific data combinations
- Test isolation failures (test depends on state from another test)
- Floating point comparison without tolerance

**Investigation steps**:
1. Increase observability FIRST: add structured logging with timestamps, request IDs, and context. You need data before you can find patterns.
2. Look for correlations: time of day, load level, specific data patterns, concurrent operations, day of week.
3. Run the failing scenario repeatedly under varied conditions. Stress test to increase the reproduction rate.
4. Check for test order dependencies: run the failing test in isolation and in different orders.
5. If the bug is in production, analyze logs statistically. What do failing requests have in common that succeeding ones do not?

**Common mistakes**: Marking intermittent failures as "not reproducible" and closing the ticket. Adding retries without understanding why it fails. Blaming "the network" without evidence.

**Prevention**: Deterministic tests, test isolation, structured logging, chaos engineering, statistical monitoring for anomaly detection.

---
name: testing
description: Testing principles, strategies, and patterns. Covers the testing pyramid, test design, TDD, test doubles, and common testing antipatterns. Stack-agnostic.
user-invocable: false
---

# Testing

A disciplined approach to verifying that software behaves correctly, remains stable under change, and communicates intent to future developers. Good tests act as living documentation, a safety net for refactoring, and a design feedback mechanism.

This skill covers universal testing concepts that apply regardless of language, framework, or tooling.

## When to Use

- Designing a test strategy for a new project or feature
- Deciding what level of testing (unit, integration, e2e) a piece of code needs
- Evaluating whether existing tests are providing value or creating drag
- Applying TDD to drive design decisions
- Debugging a flaky or brittle test suite
- Reviewing test code for quality and maintainability

## Testing Pyramid

The testing pyramid describes the ideal distribution of tests across three levels. More tests at the base, fewer at the top.

```
        /  E2E  \           Few, slow, expensive
       /----------\
      / Integration \       Moderate number, moderate speed
     /----------------\
    /    Unit Tests     \   Many, fast, cheap
   /____________________\
```

### Unit Tests (Base)

- Test a single unit of behavior in isolation (a function, a method, a small class)
- No I/O, no database, no network, no file system
- Execute in milliseconds
- Should form the majority of your test suite (roughly 70%)
- Fast feedback loop enables rapid iteration

### Integration Tests (Middle)

- Test how multiple units collaborate, or how code interacts with external systems
- May involve a real database, message queue, or HTTP endpoint
- Execute in seconds
- Verify that wiring, configuration, and contracts between components work
- Roughly 20% of your test suite

### End-to-End Tests (Top)

- Test complete user journeys through the full system
- Interact with the application as a user would
- Slowest, most brittle, most expensive to maintain
- Reserve for critical business paths only
- Roughly 10% of your test suite

### The Ice Cream Cone Antipattern

The inverted pyramid: many e2e tests, few unit tests. Symptoms:

- Test suite takes hours to run
- Tests break constantly due to UI changes or timing issues
- Developers stop running tests locally
- Feedback loop is too slow to support continuous delivery

**Fix:** Identify what each e2e test is actually verifying. Push that verification down to the lowest possible level. Most business logic can be tested at the unit level.

## Test Design Principles

### Arrange-Act-Assert (AAA)

Every test should follow three distinct phases:

1. **Arrange** — set up the preconditions and inputs
2. **Act** — execute the behavior under test
3. **Assert** — verify the expected outcome

Keep each phase clearly separated. If Arrange dominates the test, extract a builder or factory. If Act requires multiple steps, you may be testing too much at once.

### One Assertion per Concept

A test should verify one logical concept. This does not mean literally one `assert` call — asserting multiple properties of a single result is fine. What matters is that the test fails for exactly one reason.

```
// Good: one concept — "completed order has correct totals"
assert order.subtotal == 100
assert order.tax == 21
assert order.total == 121

// Bad: two unrelated concepts in one test
assert order.total == 121
assert emailService.wasCalled()
```

### Test Naming

Test names should describe the behavior, not the implementation. A good test name answers: "What scenario is being tested, and what is the expected outcome?"

Patterns that work across languages:
- `should_return_zero_when_cart_is_empty`
- `rejects_negative_quantities`
- `applies_discount_for_premium_customers`

Avoid names like `testCalculate`, `test1`, or `testGetterSetter`.

### Test Independence and Isolation

Each test must be completely independent of every other test:

- No shared mutable state between tests
- No required execution order
- Each test sets up its own preconditions and cleans up after itself
- A single failing test should not cascade into other failures

### Deterministic Tests

A test must produce the same result every time it runs, regardless of:

- The current time or date
- The order of test execution
- The machine it runs on
- Network availability
- Other tests running in parallel

Non-deterministic tests (flaky tests) destroy trust in the test suite and are worse than no tests at all.

### FIRST Principles

| Principle | Meaning |
|---|---|
| **Fast** | Tests should run in seconds, not minutes. Slow tests don't get run. |
| **Independent** | No test relies on the output of another test. |
| **Repeatable** | Same result in any environment — local, CI, staging. |
| **Self-validating** | Pass or fail with no human interpretation required. |
| **Timely** | Written at the right time — ideally before or alongside the production code. |

## Test-Driven Development (TDD)

TDD is a design discipline where tests are written before production code, following a tight feedback loop.

### Red-Green-Refactor Cycle

1. **Red** — Write a failing test that describes the desired behavior
2. **Green** — Write the simplest production code that makes the test pass
3. **Refactor** — Improve the code structure while keeping all tests green

Rules:
- Never write production code without a failing test
- Write only enough test to fail (compilation failure counts)
- Write only enough production code to pass the current failing test

### Two Schools of TDD

| Aspect | Chicago (Classical) | London (Mockist) |
|---|---|---|
| Verification | State-based | Interaction-based |
| Direction | Inside-out | Outside-in |
| Collaborators | Real objects | Mocks/stubs |
| Strength | Refactoring-resilient tests | Drives interface design |
| Risk | Complex setup for deep graphs | Tests coupled to implementation |

See [TDD Schools reference](references/tdd-schools.md) for detailed comparison and guidance.

### When TDD Helps Most

- Business logic with clear rules and edge cases
- Algorithm design
- API contract definition
- Bug reproduction and fixing (write the failing test first)

### When TDD May Not Apply

- Exploratory prototyping (write tests after you understand the shape)
- UI layout and styling
- One-off scripts

## Test Doubles

Test doubles replace real dependencies during testing. Each type serves a different purpose.

| Double | Purpose | Verifies? |
|---|---|---|
| **Dummy** | Fill parameter lists. Never actually used. | No |
| **Stub** | Provide canned responses to method calls. | No |
| **Spy** | Record interactions for later assertion. | Yes (after the fact) |
| **Mock** | Pre-programmed with expectations. Fails if not called correctly. | Yes (inline) |
| **Fake** | Simplified working implementation (e.g., in-memory repository). | No |

See [Test Doubles reference](references/test-doubles.md) for detailed guidance on when to use each type.

### Key Principle: Mock at Boundaries

Use test doubles at architectural boundaries (ports, external services), not between internal collaborators. Mocking internal classes couples your tests to implementation details and makes refactoring painful.

## What to Test / What Not to Test

### High Value — Always Test

- Business rules and domain logic
- Edge cases, boundary conditions, error paths
- State transitions and workflows
- Input validation and sanitization
- Security-critical paths (authentication, authorization)
- Data transformations and calculations

### Low Value — Usually Skip

- Trivial getters/setters with no logic
- Framework-generated code (ORM mappings, routing config)
- Third-party library internals (test your integration, not their code)
- Private methods (test through the public API)
- Logging and telemetry (unless business-critical)

### Testing Implementation vs Behavior

**Test behavior, not implementation.** A good test describes *what* the system does, not *how* it does it internally.

Signs you are testing implementation:
- Test breaks when you refactor without changing behavior
- Test asserts the order of internal method calls
- Test verifies private state rather than public output
- Renaming an internal class breaks tests for unrelated features

Signs you are testing behavior:
- Test describes a user-meaningful scenario
- Test remains green after internal refactoring
- Test asserts on outputs, side effects, or state changes visible through the public API

## Testing Strategies by Layer

Different architectural layers call for different testing approaches. See [Testing Strategies reference](references/testing-strategies.md) for detailed guidance.

| Layer | Primary Test Type | Key Technique |
|---|---|---|
| Domain/Business Logic | Unit tests | State-based verification, no I/O |
| Application Services | Unit + Integration | Test doubles for infrastructure ports |
| Data Access | Integration | Real database (test containers, in-memory) |
| API Endpoints | Integration + Contract | Request/response validation |
| UI Components | Component tests | Interaction simulation |
| Full System | E2E (selective) | Critical paths only |

## Common Antipatterns

| Antipattern | Symptoms | Fix |
|---|---|---|
| **Brittle tests** | Tests break on every refactor even when behavior is unchanged | Test behavior through public API, not internal structure |
| **Testing implementation** | Asserting on method call order, private state, internal wiring | Assert on outputs and observable side effects |
| **Slow test suite** | Test suite takes 10+ minutes; developers skip running tests | Push tests down the pyramid; use test doubles for I/O |
| **Flaky tests** | Tests pass/fail randomly without code changes | Remove time dependencies, shared state, and ordering assumptions |
| **Excessive mocking** | More mock setup than actual test logic; tests are unreadable | Use real collaborators where possible; mock only at boundaries |
| **Test data coupling** | Tests share fixtures and break when shared data changes | Each test creates its own data; use builders/factories |
| **Missing error paths** | Only happy path tested; failures discovered in production | Explicitly test error cases, edge cases, and boundary conditions |
| **Commented-out tests** | Failing tests are disabled rather than fixed or deleted | Fix the test, or delete it if the behavior changed intentionally |
| **Giant test methods** | Tests are 50+ lines with multiple acts and asserts | Split into focused tests; extract setup into helpers |
| **No assertion** | Test executes code but never asserts anything | Every test must have at least one meaningful assertion |

## Quality Checklist

Use this checklist when writing or reviewing tests:

- [ ] **Behavior-focused**: tests describe *what* the system does, not *how*
- [ ] **Independent**: no test depends on another test's execution or state
- [ ] **Deterministic**: same result every time, on every machine
- [ ] **Fast**: unit tests in milliseconds, full suite in under 5 minutes
- [ ] **Readable**: a new team member can understand the test without reading the implementation
- [ ] **Arranged clearly**: AAA structure with obvious separation of phases
- [ ] **Named descriptively**: test name explains the scenario and expected outcome
- [ ] **Error paths covered**: not just happy path — edge cases and failures are tested
- [ ] **Minimal setup**: no unnecessary dependencies or fixtures; builders/factories where needed
- [ ] **No flakiness**: no time-dependent, order-dependent, or environment-dependent tests
- [ ] **Appropriate level**: tested at the lowest pyramid level that provides confidence
- [ ] **Doubles at boundaries**: mocks/stubs used at architectural ports, not internal classes

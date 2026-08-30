# Test Doubles

## Contents

- [Overview](#overview)
- [Types of test doubles](#types-of-test-doubles)
- [When not to use test doubles](#when-not-to-use-test-doubles)
- [The "don't mock what you don't own" principle](#the-dont-mock-what-you-dont-own-principle)
- [Mock at architectural boundaries](#mock-at-architectural-boundaries)
- [Mockist vs classicist debate](#mockist-vs-classicist-debate)
- [Common mistakes](#common-mistakes)

## Overview

A test double is any object that stands in for a real dependency during testing. The term comes from the film industry's "stunt double": a substitute that looks like the real thing but serves a specific purpose. Knowing the double types helps you pick the right one and avoid over-mocking.

## Types of test doubles

### Dummy

An object passed to satisfy a parameter list but never used by the code under test.

**When to use:** A constructor or method requires a parameter that is irrelevant to the behavior you are testing.

**Example scenario:** Testing an order's total calculation. The method signature requires a logger, but logging is not involved in the calculation. Pass a dummy logger.

### Stub

An object that returns pre-configured answers to method calls. It does not verify how it was called.

**When to use:** You need to control indirect inputs to the system under test. The dependency provides data that influences the behavior you are testing.

**Example scenario:** Testing a pricing service that reads exchange rates from an external API. Stub the API client to return a fixed exchange rate so the test is deterministic and fast.

### Spy

A stub that also records how it was called: which methods, with what arguments, how many times.

**When to use:** You need to verify that the system under test interacted with a dependency in a specific way, but you want to assert *after* the act phase (not inline).

**Example scenario:** Testing that a registration service sends a welcome email. Use a spy on the email sender, then assert after the act that `send` was called once with the correct recipient.

### Mock

An object pre-programmed with expectations about how it will be called. Verification happens on the mock itself, typically before or during the act phase.

**When to use:** You want strict verification of interactions and want the test to fail immediately if the expected interaction does not occur.

**Example scenario:** Testing that a payment processor is called exactly once with the correct amount. The mock is configured with this expectation up front.

**Mock vs spy:** Mocks verify expectations eagerly (the mock itself fails). Spies record passively and let you verify later with assertions. Many testing frameworks blur this distinction.

### Fake

A lightweight, working implementation of a dependency that takes shortcuts unsuitable for production.

**When to use:** A real dependency is too slow or complex for tests, but you need realistic behavior, not just canned answers.

**Example scenario:**
- In-memory repository instead of a real database
- Fake file system that operates on a dictionary in memory
- Fake email sender that collects messages into a list

Fakes need maintenance: keep them in sync with the real implementation's contract.

## When not to use test doubles

- **Pure functions and value objects**: call them directly; no doubles needed
- **Simple collaborators that are fast and deterministic**: the real thing gives higher confidence
- **To avoid writing integration tests**: doubles verify contracts, not wiring

## The "don't mock what you don't own" principle

Do not create test doubles for third-party APIs, libraries, or framework internals. Instead:

1. Create your own abstraction (port/interface) that wraps the third-party dependency
2. Mock your own abstraction in tests
3. Write a thin adapter that implements your abstraction using the real third-party code
4. Test the adapter with integration tests

**Why:** Third-party APIs change without notice. If you mock them directly, your tests keep passing even when the real behavior has changed, which gives false confidence.

## Mock at architectural boundaries

The best place for test doubles is at architectural boundaries, the "ports" in a ports-and-adapters architecture:

- **Database access**: stub or fake the repository interface
- **External HTTP services**: stub the HTTP client abstraction
- **Message queues**: fake the message bus
- **File system**: fake the file storage interface
- **Clock/time**: stub a clock interface for deterministic time

Avoid mocking between internal collaborators (service A mocking service B within the same bounded context). This couples tests to the internal structure and makes refactoring expensive.

## Mockist vs classicist debate

| Approach | Uses doubles for | Trade-off |
|---|---|---|
| **Classicist** | Only external dependencies and slow resources | Higher confidence, more complex setup |
| **Mockist** | All collaborators except the unit under test | Focused tests, but coupled to implementation |

Neither approach is better in every case. Many teams use a hybrid:

- Real objects for fast, deterministic collaborators (value objects, domain services)
- Doubles for slow, non-deterministic, or external dependencies (databases, APIs, clocks)

## Common mistakes

| Mistake | Problem | Fix |
|---|---|---|
| Mocking everything | Tests verify wiring, not behavior; break on any refactor | Use real collaborators where practical |
| Mocking return values of mocks | Deep mock chains signal a design problem (Law of Demeter) | Simplify the interface; inject what you need directly |
| Not verifying fake correctness | Fake drifts from real implementation; tests pass but production fails | Write contract tests that run against both fake and real implementations |
| Verifying too many interactions | Tests become a mirror of the implementation | Verify only the interactions that matter to the behavior |

# TDD Schools: London vs Chicago

## Contents

- [Overview](#overview)
- [Chicago School (Classical / Detroit)](#chicago-school-classical--detroit)
- [London School (Mockist / Interaction-Based)](#london-school-mockist--interaction-based)
- [Side-by-side comparison](#side-by-side-comparison)
- [When to use which](#when-to-use-which)
- [Hybrid approach](#hybrid-approach)
- [Key takeaway](#key-takeaway)

## Overview

Test-Driven Development has two major schools that differ in test isolation, verification style, and design direction. Neither is "correct". Each works better in different contexts, and knowing both lets you pick the right one for the problem.

## Chicago School (Classical / Detroit)

The original TDD approach, associated with Kent Beck's "Test-Driven Development: By Example."

### Core principles

- **State-based verification**: assert on the output or resulting state, not on which methods were called
- **Inside-out direction**: start with the innermost domain logic, then build outward toward application and infrastructure layers
- **Real collaborators**: use actual objects wherever possible; avoid mocks unless dealing with external or slow dependencies
- **Refactoring-friendly**: tests verify outcomes rather than interactions, so internal restructuring rarely breaks them

### Workflow

1. Identify a small piece of domain behavior
2. Write a test that asserts the expected state after invoking that behavior
3. Implement the simplest code to pass the test
4. Refactor: rearrange internals freely, since tests verify outputs, not call sequences
5. Move outward to the next layer, using the already-tested domain objects as real collaborators

### Strengths

- Tests survive refactoring. Changing how code works does not break them as long as what it does stays the same.
- Tests document behavior. Reading the test tells you what the system does.
- Higher confidence, because real objects exercise actual code paths.
- Simpler test code, with less mock setup and fewer expectations to maintain.

### Weaknesses

- Setup gets complex when the object graph is deep. Creating the unit under test may require building many real collaborators.
- When a deep dependency breaks, many tests fail, which makes the root cause harder to pinpoint.
- Less guidance on interface design. Interfaces emerge after the fact instead of being driven by the test.

## London School (Mockist / Interaction-Based)

Associated with Steve Freeman and Nat Pryce's "Growing Object-Oriented Software, Guided by Tests" (GOOS).

### Core principles

- **Interaction-based verification**: assert that the unit under test called its collaborators with the correct arguments
- **Outside-in direction**: start with an acceptance test at the outermost layer, then drive inward, discovering interfaces as you go
- **Mocked collaborators**: every direct dependency of the unit under test is replaced with a mock or stub
- **Interface-driven design**: you must define collaborator interfaces before implementing them, so TDD drives the API design

### Workflow

1. Write a failing acceptance test for a user-facing feature
2. Starting from the outermost layer (controller, handler), write a unit test that mocks the next layer's interface
3. Define the interface that the mock represents. This is the "discovered" design.
4. Implement the outer layer to pass the test
5. Move inward: the mocked interface becomes the next unit to test, with its own mocked collaborators
6. Repeat until you reach the innermost layer, then implement the real infrastructure

### Strengths

- Each unit test is focused: it tests one class with all collaborators mocked, so failures are precise
- Drives interface design by forcing you to think about collaborator contracts before implementing them
- Fits outside-in development, where you build the system from the user's perspective
- Encourages small classes with clear roles

### Weaknesses

- Tests are coupled to implementation. Renaming a method, extracting a class, or changing call order breaks tests even if behavior is unchanged.
- Refactoring is expensive, because internal restructuring often means rewriting tests.
- Risk of "mock hell": so much mock setup that tests are harder to read than the production code.
- False positives: tests pass because mocks behave as programmed, even if the real integration would fail.

## Side-by-side comparison

| Aspect | Chicago | London |
|---|---|---|
| Verification style | State/output | Interactions/calls |
| Design direction | Inside-out | Outside-in |
| Collaborators in test | Real objects | Mocks and stubs |
| Refactoring cost | Low | High |
| Failure localization | Broad (many tests may fail) | Precise (one test fails) |
| Interface discovery | After implementation | During test writing |
| Setup complexity | Can be high (deep object graphs) | Moderate (mock configuration) |
| Best for | Domain logic, calculations, transformations | Coordination logic, workflow orchestration |

## When to use which

### Prefer Chicago when

- The code is logic-heavy: calculations, validations, transformations, state machines
- You want maximum freedom to refactor internals
- Collaborators are fast, deterministic, and easy to construct
- You are working on domain or core layers with few external dependencies

### Prefer London when

- The code mainly coordinates between collaborators (orchestration, delegation)
- You want to discover and refine interfaces during design
- You are building from the outside in, starting with user-facing behavior
- The collaborator graph is complex and constructing real objects would be impractical

## Hybrid approach

Most experienced practitioners mix both schools:

- **Domain layer**: Chicago style, with real objects, state-based assertions, and maximum refactoring safety
- **Application/service layer**: London style, mocking infrastructure ports and verifying coordination logic
- **Infrastructure adapters**: integration tests with real external systems. Neither school applies; the goal is to verify the wiring.

The result:
- Domain tests that survive refactoring
- Focused service tests that drive interface design
- Integration tests that verify real behavior at the boundaries

## Key takeaway

The choice depends on context, not ideology. Match the approach to the code under test. Logic-heavy code suits classical state-based testing. Coordination-heavy code suits interaction-based testing. A healthy test suite usually contains both.

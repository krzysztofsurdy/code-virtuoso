# Task Brief Template

A task brief is the complete contract between the orchestrator and a subagent. It must be self-contained: the subagent should be able to execute the task using only this brief and access to the codebase, with no further conversation.

## Contents

- [Template](#template)
- [Field-by-field guidance](#field-by-field-guidance)
- [Brief quality checklist](#brief-quality-checklist)
- [Sizing guidance](#sizing-guidance)
- [Adaptation for different agent types](#adaptation-for-different-agent-types)

## Template

```
## Task: [TASK-ID] [Short descriptive title]

### Goal
[One sentence describing what this task accomplishes. Be specific and observable.]

### Inputs
- File paths: [list of files the subagent needs to read or modify]
- Interfaces: [signatures, contracts, or types the subagent must conform to]
- Test fixtures: [existing test data or factories the subagent should use]
- Dependencies: [libraries, services, or modules already available]

### Context from Prior Tasks
[Hand-off summary from the previous task, or "None - this is the first task."
Include only: what changed, what was decided, and what affects this task.
Do NOT paste conversation history or full diffs.]

### Acceptance Criteria
1. [Observable condition that can be verified mechanically]
2. [Another observable condition]
3. [Continue until all requirements are captured]

### Out of Scope
- [Explicit boundary: what the subagent must NOT modify]
- [Another boundary]

### Failure Handling
- If blocked by a missing interface or ambiguous requirement: STOP and report back with the specific question. Do not guess.
- If tests fail for reasons unrelated to this task: report the failure. Do not fix unrelated tests.
- If the task cannot be completed as specified: report what was accomplished and what remains, with a clear explanation of the blocker.
```

## Field-by-field guidance

### Task ID and title

The task ID ties back to the plan. Use whatever scheme the plan uses (numbered, ticketed, or named). The title should be descriptive enough that someone reading just the title understands the scope.

Good: `TASK-03: Add validation middleware for order creation endpoint`
Bad: `Task 3: Do the validation thing`

### Goal

One sentence. Make it observable - describe the end state, not the activity.

Good: "The order creation endpoint rejects requests with missing or invalid fields and returns structured error responses with field-level messages."

Bad: "Add validation to orders." (Too vague - what kind of validation? Where? What happens on failure?)

### Inputs

List everything the subagent needs to find in the codebase. Be explicit about file paths - the subagent should not need to search for files. If a file does not exist yet and the subagent should create it, say so.

```
- File paths:
  - src/Order/CreateOrderHandler.php (modify - add validation call)
  - src/Order/CreateOrderRequest.php (create - new validation DTO)
  - tests/Order/CreateOrderHandlerTest.php (modify - add validation test cases)
- Interfaces:
  - ValidatorInterface::validate(object $request): ValidationResult
  - (already exists in src/Shared/Validation/ValidatorInterface.php)
- Dependencies:
  - The project uses a constraint-based validation library (see composer.json)
```

### Context from prior tasks

This field carries the hand-off summary from the previous task in the sequence. It tells the subagent about decisions and changes that affect its work. It does not replay what happened.

When the task is first in the sequence:
```
Context from Prior Tasks: None - this is the first task in the plan.
```

When there is relevant prior context:
```
Context from Prior Tasks:
- Task 02 created the OrderRepository interface (src/Order/OrderRepositoryInterface.php)
  with methods: save(Order), findById(OrderId), findByCustomer(CustomerId)
- Task 02 chose to use UUIDs for OrderId (decision: consistency with existing entity IDs)
- The repository integration test (tests/Order/OrderRepositoryTest.php) validates
  all three methods against the test database
```

What NOT to include:
- "The subagent tried X first but it didn't work, so it tried Y"
- Raw diffs from the previous task
- The previous task's full brief
- Commentary about how well the previous task went

### Acceptance criteria

Each criterion must be independently verifiable. Write them so that a reviewer can check each one without subjective judgment.

Good criteria:
```
1. POST /orders with missing "customer_id" returns 422 with error body
   containing {"field": "customer_id", "message": "..."}
2. POST /orders with negative "quantity" returns 422 with error body
   containing {"field": "quantity", "message": "..."}
3. POST /orders with valid data passes validation and reaches the handler
4. Unit tests cover all validation rules with both valid and invalid inputs
5. No changes to existing tests - all previously passing tests still pass
```

Bad criteria:
```
1. Validation works correctly (too vague)
2. Good error messages (subjective)
3. Tests exist (no specificity about what is tested)
```

### Out of scope

Explicit boundaries prevent scope creep. List things the subagent might reasonably attempt but should not.

```
- Do NOT modify the OrderRepository or its tests (those were completed in Task 02)
- Do NOT add authorization checks - that is Task 05
- Do NOT change the HTTP response format for successful requests
- Do NOT add logging - that is a cross-cutting concern handled separately
```

### Failure handling

Default instructions that apply to most tasks:

```
- If blocked by a missing interface or ambiguous requirement: STOP and report
  back with the specific question. Do not guess or invent interfaces.
- If tests fail for reasons unrelated to this task: report the failure with
  the test name and error. Do not fix unrelated tests.
- If the task cannot be completed as specified: report what was accomplished,
  what remains, and a clear explanation of the blocker.
- If you discover a bug in code from a prior task: report it. Do not fix it
  unless it is blocking your task and the fix is trivial and obvious.
```

Customize when the task has specific risk:

```
- If the database migration fails: do NOT retry. Report the exact error.
  Migration failures require orchestrator review before re-attempting.
```

## Brief quality checklist

Before dispatching a brief, verify:

- [ ] Goal is one sentence and describes an observable end state
- [ ] All file paths are explicit (no "find the relevant file")
- [ ] Acceptance criteria are independently verifiable without subjective judgment
- [ ] Out-of-scope boundaries are listed (at least one)
- [ ] Context from prior tasks is a summary, not a history dump
- [ ] Failure handling instructions are present
- [ ] The brief is self-contained - a new agent can execute it without asking questions

## Sizing guidance

A well-scoped brief describes work a subagent can finish in one session without exceeding its context window. Signs that a task is too large:

| Signal | Action |
|---|---|
| More than 5 files to modify | Split by component or layer |
| More than 8 acceptance criteria | Split into two tasks with clear boundaries |
| Acceptance criteria reference multiple unrelated behaviors | Each behavior is its own task |
| The context section exceeds 20 lines | The task depends on too much prior work - consider a checkpoint |
| You cannot describe the goal in one sentence | The task contains multiple goals - split them |

## Adaptation for different agent types

The template works for any subagent role. Shift the emphasis to match the dispatch target:

| Agent Type | Brief emphasis |
|---|---|
| Implementer | Acceptance criteria, file paths, test expectations, TDD instructions |
| Reviewer | Scope of changes, review focus areas, severity threshold for blocking |
| Investigator | Questions to answer, files to explore, output format for findings |
| Doc writer | What changed, audience, documentation format, where to place output |

# Handoff Patterns

When tasks in a plan are sequential, the orchestrator must pass structured state from task N to task N+1. The handoff is the bridge between isolated agent sessions - it carries just enough context for the next subagent to work effectively without inheriting the previous agent's full history.

## Core Principle

**Compress, do not replay.** The next subagent needs decisions, artifacts, and relevant changes - not a transcript of what happened. Every line in a handoff should answer the question: "Does the next agent need this to do its job?"

## Three Handoff Formats

Choose the format based on how deeply the next task depends on the previous one.

### 1. Diff Summary

**When to use:** The next task has a light dependency - it needs to know what files changed and what interfaces were introduced, but does not need to understand why decisions were made.

**Typical scenario:** Task N created a new service class. Task N+1 writes the controller that uses it.

```
## Handoff: Task 02 -> Task 03

### Changes
- Created: src/Order/OrderService.php
  - OrderService::create(CreateOrderRequest): Order
  - OrderService::cancel(OrderId): void
- Created: tests/Order/OrderServiceTest.php (8 test cases)
- Modified: src/Order/OrderRepositoryInterface.php
  - Added: findByCustomer(CustomerId): array

### Test Status
- All tests passing (42 total, 8 new)
- No skipped or incomplete tests

### Notes
- OrderService expects OrderRepositoryInterface injected via constructor
- CreateOrderRequest is a simple DTO with public readonly properties
```

### 2. Decision Log

**When to use:** Design choices were made during the previous task that constrain or inform the next task. The next subagent needs to understand WHY things were done a certain way, not just what changed.

**Typical scenario:** Task N chose between two architectural approaches. Task N+1 must extend the chosen approach consistently.

```
## Handoff: Task 03 -> Task 04

### Changes
- Created: src/Pricing/PricingStrategy.php (interface)
- Created: src/Pricing/TieredPricingStrategy.php
- Created: src/Pricing/FlatPricingStrategy.php
- Created: tests/Pricing/TieredPricingStrategyTest.php (12 test cases)
- Created: tests/Pricing/FlatPricingStrategyTest.php (6 test cases)

### Decisions
1. **Strategy pattern over conditional logic**
   - Chose: Strategy interface with one class per pricing model
   - Rejected: Switch statement in a single PriceCalculator class
   - Rationale: New pricing models will be added quarterly; strategy pattern
     allows addition without modifying existing code
   - Impact on Task 04: The discount system (Task 04) should follow the same
     pattern - create a DiscountStrategy interface rather than adding
     conditionals to the pricing strategies

2. **Money represented as integer cents**
   - Chose: All monetary values stored as integer cents (no floating point)
   - Rationale: Avoids floating point precision errors in calculations
   - Impact on Task 04: Discount calculations must work in integer cents.
     Round at the final step only.

### Test Status
- All tests passing (56 total, 18 new)

### Notes
- PricingStrategy::calculate() returns a PriceResult value object (immutable)
- PriceResult contains: subtotal, taxAmount, total (all in cents)
```

### 3. Full Handoff

**When to use:** The next task will directly modify or extend what the previous task created. The subagent needs to understand the complete picture: what changed, why, and how the pieces fit together.

**Typical scenario:** Task N built the data model. Task N+1 adds validation rules and error handling to the same classes.

```
## Handoff: Task 05 -> Task 06

### Changes
- Created: src/Order/OrderStateMachine.php
- Created: src/Order/OrderState.php (enum: Draft, Confirmed, Shipped, Delivered, Cancelled)
- Created: src/Order/OrderTransition.php (enum: Confirm, Ship, Deliver, Cancel)
- Modified: src/Order/Order.php
  - Added: state property (OrderState, default: Draft)
  - Added: transition(OrderTransition): void
  - Added: canTransition(OrderTransition): bool
- Created: tests/Order/OrderStateMachineTest.php (22 test cases)
- Modified: tests/Order/OrderTest.php (added 8 transition test cases)

### Decisions
1. **State machine embedded in entity, not external service**
   - Chose: Order entity owns its state transitions via OrderStateMachine
   - Rejected: Separate StateMachineService that operates on Order
   - Rationale: State transitions are core domain logic; keeping them in the
     entity ensures invariants are always enforced
   - Impact on Task 06: Event dispatching (Task 06) should hook into the
     Order::transition() method. Do NOT create a separate transition service.

2. **Enum-based states over string constants**
   - Chose: PHP enum for states and transitions
   - Rationale: Compile-time safety, exhaustive matching in switch statements
   - Impact on Task 06: Event names should derive from the enum values for
     consistency (e.g., "order.confirmed" from OrderTransition::Confirm)

3. **Guard clauses for invalid transitions**
   - Order::transition() throws InvalidTransitionException when the
     transition is not allowed from the current state
   - The allowed transitions matrix is in OrderStateMachine::TRANSITIONS

### Architecture Notes
- The transition matrix (OrderStateMachine::TRANSITIONS) is a two-dimensional
  array: [currentState][transition] => nextState
- canTransition() checks the matrix without mutating state
- transition() calls canTransition() internally, then updates state
- Tests cover every valid transition AND every invalid transition attempt

### Test Status
- All tests passing (78 total, 30 new)
- Coverage: OrderStateMachine 100%, Order transition methods 100%

### Open Items
- None blocking. Task 06 can proceed as planned.
```

## Choosing the Right Format

| Signal | Format |
|---|---|
| Next task uses output from this task but does not modify it | Diff summary |
| Design decisions were made that constrain the next task | Decision log |
| Next task directly extends or modifies this task's output | Full handoff |
| Unsure | Default to decision log - it covers the most common case without excessive bulk |

## What Never Goes in a Handoff

| Excluded content | Why |
|---|---|
| Raw conversation history | Noise. The next agent does not need to know how the previous agent thought through the problem. |
| Full file contents | The agent can read files directly. Provide paths and signatures, not code dumps. |
| Previous task's brief | Irrelevant to the next task. If the next task needs the same context, it should be in its own brief. |
| Fix-cycle details | "The agent tried X, it failed, then tried Y" is implementation noise. Only the final state matters. |
| Reviewer feedback | Unless a review finding directly affects the next task, it stays with the completed task. |
| Token counts or timing | Operational metrics are for the orchestrator's log, not the next agent's context. |

## Handoff Quality Checklist

Before including a handoff in the next task's brief:

- [ ] Every changed file is listed with its path
- [ ] New interfaces include their method signatures
- [ ] Decisions include the rationale AND the impact on the next task
- [ ] No raw conversation history or fix-cycle details
- [ ] No full file contents (paths and signatures only)
- [ ] The handoff answers: "What does the next agent need to know?"
- [ ] The handoff is under 40 lines (if longer, it may be carrying too much)

## Progressive Context

As tasks progress through a plan, handoffs can reference earlier handoffs by task ID rather than repeating their content:

```
### Context from Prior Tasks
- Task 02 handoff: Created OrderRepositoryInterface (see Task 02 handoff for method signatures)
- Task 03 handoff: OrderService depends on OrderRepositoryInterface via constructor injection
- Task 04 changes (this handoff): Added PricingStrategy interface used by OrderService::create()
```

This keeps later handoffs from growing unboundedly while still providing traceability. If the subagent needs detail from an earlier task, it can request the specific handoff by ID.

## Edge Cases

### First Task in the Plan

No handoff exists. The brief's "Context from Prior Tasks" section should say: "None - this is the first task."

### Task That Produces No Code Changes

Some tasks produce documentation, configuration, or analysis rather than code. The handoff still applies - describe what was produced and where it lives.

### Task That Was Re-Scoped Mid-Execution

If the orchestrator re-scoped a task after the subagent started, the handoff must note the deviation from the original plan:

```
### Plan Deviation
- Original scope: Full CRUD for OrderController
- Actual scope: Create and Read only (Update and Delete deferred to Task 08)
- Reason: Validation rules for updates depend on state machine (Task 06)
```

This prevents the next subagent from assuming the full original scope was completed.

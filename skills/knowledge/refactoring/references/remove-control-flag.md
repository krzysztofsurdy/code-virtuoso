# Remove Control Flag

## Overview

Remove Control Flag replaces boolean variables that manage loop flow or early exits with direct control-flow statements such as `break`, `continue`, and `return`. Flag variables add indirection and no clarity. The language already has constructs built for controlling execution paths.

Control flags are a holdover from an era that wanted a single entry and a single exit in every routine. Current practice favors explicit flow control, which states intent more directly and keeps the code short.

## Contents

- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after](#before-and-after)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

Control flags cause several problems:

- **Obscured intent**: the purpose of the boolean variable may not be clear.
- **Added complexity**: extra variables and conditional checks clutter the code.
- **Harder maintenance**: developers must track flag state across several code paths.
- **Non-idiomatic code**: it ignores language features designed for this purpose.

Using `break`, `continue`, and `return` directly states the intent and removes boilerplate logic.

## Mechanics

1. **Identify** control flags: find boolean variables used to exit loops or functions.
2. **Replace** assignments: swap each flag assignment for the matching flow control statement.
3. **Remove**: delete the flag variable and the related conditional checks.

## Before and after

### Example 1: loop with early exit

**Before (with control flag):**

```php
<?php declare(strict_types=1);

function findUserByEmail(array $users, string $email): ?User
{
    $found = false;
    $user = null;

    foreach ($users as $currentUser) {
        if (!$found) {
            if ($currentUser->getEmail() === $email) {
                $user = $currentUser;
                $found = true;
            }
        }
    }

    return $user;
}
```

**After (with return statement):**

```php
<?php declare(strict_types=1);

function findUserByEmail(array $users, string $email): ?User
{
    foreach ($users as $user) {
        if ($user->getEmail() === $email) {
            return $user;
        }
    }

    return null;
}
```

### Example 2: skipping iterations

**Before (with control flag):**

```php
<?php declare(strict_types=1);

function processValidOrders(array $orders): array
{
    $results = [];

    foreach ($orders as $order) {
        $shouldProcess = true;

        if ($order->isCancelled()) {
            $shouldProcess = false;
        }

        if ($shouldProcess && $order->getTotal() <= 0) {
            $shouldProcess = false;
        }

        if ($shouldProcess) {
            $results[] = $this->processOrder($order);
        }
    }

    return $results;
}
```

**After (with continue statement):**

```php
<?php declare(strict_types=1);

function processValidOrders(array $orders): array
{
    $results = [];

    foreach ($orders as $order) {
        if ($order->isCancelled() || $order->getTotal() <= 0) {
            continue;
        }

        $results[] = $this->processOrder($order);
    }

    return $results;
}
```

### Example 3: complex validation

**Before (with control flag):**

```php
<?php declare(strict_types=1);

function validatePayment(Payment $payment): bool
{
    $isValid = true;

    if ($payment->getAmount() <= 0) {
        $isValid = false;
    }

    if ($isValid && !$payment->hasValidCard()) {
        $isValid = false;
    }

    if ($isValid && $payment->isExpired()) {
        $isValid = false;
    }

    return $isValid;
}
```

**After (with early return):**

```php
<?php declare(strict_types=1);

function validatePayment(Payment $payment): bool
{
    if ($payment->getAmount() <= 0) {
        return false;
    }

    if (!$payment->hasValidCard()) {
        return false;
    }

    if ($payment->isExpired()) {
        return false;
    }

    return true;
}
```

Alternatively, with a match expression (PHP 8.0+):

```php
<?php declare(strict_types=1);

function validatePayment(Payment $payment): bool
{
    return match (true) {
        $payment->getAmount() <= 0 => false,
        !$payment->hasValidCard() => false,
        $payment->isExpired() => false,
        default => true,
    };
}
```

## Benefits

- **Visible flow**: the execution path shows at each branch, with no auxiliary state to track.
- **Fewer moving parts**: removing flag variables shrinks the method's working set.
- **Better efficiency**: loops exit as soon as the answer is found instead of running to the end.
- **Idiomatic style**: code uses language features as they were designed.
- **Simpler tests**: fewer conditional paths mean fewer scenarios to test.

## When not to use

Do **not** apply this refactoring when:

- **Several exit states are needed**: if you need several flags to track different states, consider splitting the logic into separate methods instead.
- **Async operations**: flag manipulation is required across asynchronous boundaries.
- **Complex state machines**: if the logic is a state machine, use the State pattern instead.
- **Performance-critical code**: in very tight loops where every variable counts (unlikely in modern PHP).

## Related refactorings

- **Extract Method**: move complex conditions into separate, well-named methods.
- **Replace Nested Conditionals with Guard Clauses**: simplify nested if statements.
- **Replace Conditional with Polymorphism**: use object-oriented design for complex branching logic.
- **Consolidate Duplicate Conditional Fragments**: reduce code duplication in conditionals.

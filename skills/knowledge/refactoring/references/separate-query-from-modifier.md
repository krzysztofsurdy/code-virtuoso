## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After: PHP 8.3+ code](#beforeafter-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Separate Query from Modifier splits a method that both returns data and changes object state into two methods. It applies Command Query Separation (CQS) at method level: a method either performs an action or returns data, not both. Command Query Responsibility Segregation (CQRS) takes the same idea to the architecture level, with separate read and write models.

## Motivation

A method that returns a value and also has side effects behaves unpredictably:

- **Unpredictable results**: callers cannot fetch the data twice and expect identical results.
- **Hidden side effects**: the method changes visible state without saying so (public fields, database entries, files).
- **Maintenance burden**: developers must remember not to call the query carelessly, because it modifies state.

Without the split, you cannot safely call the method to read data without possibly changing the object.

## Mechanics

1. **Create a query method**: extract the value-returning logic into a new method that only queries.
2. **Modify the original method**: have the original modifier call the new query method if its logic needs it.
3. **Update callers**: replace each call with the query method first, then the modifier separately.
4. **Clean up**: remove the return value from the original modifier.

## Before/After: PHP 8.3+ code

### Before
```php
class User
{
    private array $badgesBefore = [];
    private bool $smileyState = false;

    public function smileys(): int
    {
        if (!$this->smileyState) {
            $this->smileyState = true;
            $this->badgesBefore[] = 'SMILEY';
        }
        return count($this->badgesBefore);
    }
}

// Usage - problem: method does two things
$user = new User();
$count = $user->smileys(); // Returns count AND modifies state
$count = $user->smileys(); // Might return different value!
```

### After
```php
class User
{
    private array $badgesAfter = [];
    private bool $smileyState = false;

    // Pure query method - no side effects
    public function getSmileyCount(): int
    {
        return count($this->badgesAfter);
    }

    // Pure modifier method - no return value
    public function addSmileyBadge(): void
    {
        if (!$this->smileyState) {
            $this->smileyState = true;
            $this->badgesAfter[] = 'SMILEY';
        }
    }
}

// Usage - clear intent and predictable behavior
$user = new User();
$count = $user->getSmileyCount(); // Query only - safe to call repeatedly
$user->addSmileyBadge();           // Modifier only
$count = $user->getSmileyCount(); // Same result as first call
```

## Benefits

- **Predictability**: query methods can be called any number of times without side effects.
- **Clarity**: method names and behavior show whether they query or modify.
- **Testability**: query and modifier logic can be tested independently.
- **Caching**: query methods become candidates for result caching.
- **Concurrency**: separating reads from writes makes thread-safety easier to reason about.
- **CQRS groundwork**: the same separation at method level is the starting point for CQRS at the architecture level.

## When not to use

- **Convenience methods**: some operations return data about what was modified (e.g., "how many rows were deleted?").
- **Performance constraints**: separate calls may add overhead in performance-critical code.
- **Legacy systems**: changing well-established APIs can break dependent code needlessly.
- **Simple getters/setters**: basic property accessors need no separation if they have no side effects.

## Related refactorings

- **Command pattern**: encapsulates requests as objects, similar to separating modifiers.
- **Query pattern**: a dedicated pattern for side-effect-free data retrieval.
- **Command Query Responsibility Segregation (CQRS)**: the architectural extension of Command Query Separation.
- **Remove Setting Method**: prevents unwanted modifications to immutable objects.
- **Introduce Parameter Object**: can simplify the signatures of the separated query and modifier methods.

## Overview

The Separate Query from Modifier refactoring technique separates methods that retrieve data from methods that modify object state. This implements the Command Query Responsibility Segregation (CQRS) principle, ensuring that methods either perform an action or return data, but not both.

## Motivation

When a single method both returns a value and produces side effects, it creates unpredictable behavior:

- **Unpredictable results**: Callers cannot retrieve data multiple times and expect identical results
- **Hidden side effects**: Methods silently change visible state (public fields, database entries, files)
- **Maintenance burden**: Developers must remember not to call query methods carelessly, as they modify state

Without separation, you cannot safely call a method multiple times to get data without inadvertently changing the object's condition.

## Mechanics

The refactoring follows a straightforward process:

1. **Create a query method**: Extract the value-returning logic into a new method that performs only the query operation
2. **Modify original method**: Have the original modifier call the new query method if needed for its logic
3. **Update callers**: Replace all references to call the query method first, then the modifier separately
4. **Clean up**: Remove the return value from the original modifier method

## Before/After: PHP 8.3+ Code

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

- **Predictability**: Query methods can be called as many times as desired without unexpected side effects
- **Clarity**: Method names and behavior explicitly indicate whether they query or modify
- **Testability**: Easier to test query and modifier logic independently
- **Caching**: Query methods become candidates for result caching
- **Concurrency**: Separating reads from writes improves thread-safety assumptions
- **CQRS alignment**: Aligns with modern architectural patterns for scalable systems

## When NOT to Use

- **Convenience methods**: Some operations naturally return data about what was modified (e.g., "how many rows were deleted?")
- **Performance constraints**: Creating separate calls may introduce overhead in performance-critical code
- **Legacy systems**: Changing well-established APIs can break dependent code unnecessarily
- **Simple getters/setters**: Basic property accessors don't need separation if they have no side effects

## Related Refactorings

- **Command Pattern**: Encapsulates requests as objects, similar to separating modifiers
- **Query Pattern**: Dedicated pattern for safe, side-effect-free data retrieval
- **Command Query Responsibility Segregation (CQRS)**: Architectural pattern extending this principle
- **Remove Setting Method**: Prevents unwanted modifications to immutable objects
- **Introduce Parameter Object**: Can simplify separated query/modifier method signatures

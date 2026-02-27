## Overview

Duplicate code occurs when two or more code fragments are identical or nearly identical. This is one of the most common code smells and indicates that logic should be consolidated into a single, reusable component. Duplicate code violates the DRY (Don't Repeat Yourself) principle and creates maintenance burden.

## Why It's a Problem

When identical code exists in multiple locations, every bug fix, improvement, or change must be replicated across all instances. This dramatically increases:

- **Maintenance costs**: Changes require updates in multiple places
- **Bug propagation**: Fixing a bug in one location may leave copies unfixed
- **Inconsistency**: Duplicates naturally diverge over time, creating subtle bugs
- **Testing burden**: More code paths to test and maintain
- **Cognitive load**: Developers must understand redundant implementations

## Signs and Symptoms

- Identical or nearly identical code blocks in different methods or classes
- Copy-pasted code segments with minor variable name changes
- Methods with similar control structures but different implementations
- Constructor or getter/setter duplication across multiple classes
- Repeated validation, logging, or error handling patterns
- Similar SQL queries or API call patterns scattered throughout the code

## Before/After Examples

### Example 1: Extract Method (Same Class)

**Before:**
```php
<?php

declare(strict_types=1);

final class OrderProcessor
{
    public function calculateRegularTotal(array $items): float
    {
        $total = 0.0;
        foreach ($items as $item) {
            $total += $item['price'] * $item['quantity'];
        }
        $total *= 0.9; // 10% discount
        return $total;
    }

    public function calculatePremiumTotal(array $items): float
    {
        $total = 0.0;
        foreach ($items as $item) {
            $total += $item['price'] * $item['quantity'];
        }
        $total *= 0.8; // 20% discount
        return $total;
    }
}
```

**After:**
```php
<?php

declare(strict_types=1);

final class OrderProcessor
{
    private function calculateSubtotal(array $items): float
    {
        $total = 0.0;
        foreach ($items as $item) {
            $total += $item['price'] * $item['quantity'];
        }
        return $total;
    }

    public function calculateRegularTotal(array $items): float
    {
        return $this->calculateSubtotal($items) * 0.9;
    }

    public function calculatePremiumTotal(array $items): float
    {
        return $this->calculateSubtotal($items) * 0.8;
    }
}
```

### Example 2: Extract Class (Different Classes)

**Before:**
```php
<?php

declare(strict_types=1);

final class UserValidator
{
    public function validateEmail(string $email): bool
    {
        if (empty($email) || !str_contains($email, '@')) {
            return false;
        }
        if (strlen($email) > 255) {
            return false;
        }
        return true;
    }
}

final class SubscriptionValidator
{
    public function validateEmail(string $email): bool
    {
        if (empty($email) || !str_contains($email, '@')) {
            return false;
        }
        if (strlen($email) > 255) {
            return false;
        }
        return true;
    }
}
```

**After:**
```php
<?php

declare(strict_types=1);

final readonly class EmailValidator
{
    private const MAX_LENGTH = 255;

    public function validate(string $email): bool
    {
        return !empty($email)
            && str_contains($email, '@')
            && strlen($email) <= self::MAX_LENGTH;
    }
}

final class UserValidator
{
    public function __construct(private EmailValidator $emailValidator) {}

    public function validateEmail(string $email): bool
    {
        return $this->emailValidator->validate($email);
    }
}

final class SubscriptionValidator
{
    public function __construct(private EmailValidator $emailValidator) {}

    public function validateEmail(string $email): bool
    {
        return $this->emailValidator->validate($email);
    }
}
```

## Recommended Refactorings

**Extract Method**: When duplicate code exists within the same class or related classes, extract the shared logic into a separate method and call it from multiple locations.

**Extract Class**: When duplication spans unrelated classes, create a new class to encapsulate the shared behavior and inject it as a dependency.

**Pull Up Field/Method**: In inheritance hierarchies, move duplicate code to parent classes so subclasses can reuse it.

**Form Template Method**: For similar algorithms with variations, create a template method in a parent class with override points for differences.

**Consolidate Conditional Expression**: When duplicate logic appears in multiple conditional branches, extract it to reduce complexity.

## Exceptions

Duplication is acceptable in these cases:

- **Performance-critical code**: Sometimes inline code outperforms method calls. Benchmark before extracting.
- **Different domains**: Code that looks identical but serves different business purposes may belong separate.
- **Simple value checks**: Guard clauses with identical null or type checks may be clearer inline.
- **Constants**: Repeated literal values are acceptable when they represent different semantic meaning.
- **Test fixtures**: Test code often duplicates setup logic intentionally for clarity and isolation.

## Related Smells

- **Long Method**: Often creates duplicate code by copying similar logic instead of extracting it
- **Long Parameter List**: May indicate missing abstraction that could consolidate duplicated parameters
- **Divergent Change**: When one class changes for multiple reasons, it may contain diverse duplicate patterns
- **Primitive Obsession**: Type-specific duplication that could be consolidated with proper objects

## Refactoring.guru Guidance

### Signs and Symptoms

Two code fragments look almost identical.

### Reasons for the Problem

- Multiple programmers working on different parts of the same program simultaneously without awareness of each other's work.
- Certain parts of code look different but actually perform the same job (harder to detect).
- Copy-paste programming under deadline pressure.

### Treatment

- **Same class**: Apply **Extract Method** to consolidate identical code into a single reusable method.
- **Sibling subclasses**: Use **Extract Method** combined with **Pull Up Field**, or apply **Pull Up Constructor Body** for constructor duplication. If the algorithms are similar but not identical, use **Form Template Method**.
- **Different classes**: Use **Extract Superclass** for a shared parent class, or **Extract Class** if inheritance is not appropriate.
- **Conditional expressions**: Merge duplicate conditions with **Consolidate Conditional Expression** and extract the combined logic.

### Payoff

- Merging duplicate code simplifies the structure and makes it shorter.
- Simplification plus reduced size equals code that is easier to maintain and cheaper to support.

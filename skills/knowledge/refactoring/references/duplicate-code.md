## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Duplicate code appears when two or more code fragments do the same work with identical or near-identical logic. It is one of the most common code smells, and it means the shared logic should be extracted into one reusable place. Every copy is a liability. It multiplies the effort of any change and breaks the DRY (Don't Repeat Yourself) principle.

## Why it's a problem

When the same logic lives in several places, every fix, enhancement, or behavioral change must be applied to each copy:

- **Multiplied maintenance**: One conceptual change requires edits in several places
- **Inconsistent fixes**: Patching a bug in one copy and missing the others creates hard-to-diagnose inconsistencies
- **Drift**: Duplicates diverge over time as different developers modify different copies
- **Larger test surface**: More code paths to cover, with no extra functionality
- **Wasted reading time**: Developers spend time checking whether near-identical fragments behave the same way

## Signs and symptoms

- Identical or near-identical code blocks in different methods or classes
- Copy-pasted segments where only variable names differ
- Methods that share the same control flow structure but implement it separately
- Repeated constructor or accessor patterns across multiple classes
- The same validation, logging, or error-handling logic spread across the codebase
- Similar database queries or API call sequences in unrelated files

## Before and after

### Example 1: Extract Method (same class)

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

### Example 2: Extract Class (different classes)

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

## Recommended refactorings

**Extract Method**: When duplication occurs in the same class or closely related classes, move the shared logic into its own method and call it from each original location.

**Extract Class**: When duplication spans unrelated classes, create a class to own the shared behavior and inject it where needed.

**Pull Up Field/Method**: In inheritance hierarchies, move duplicate code to the parent class so all subclasses inherit it. For constructor duplication, apply **Pull Up Constructor Body**.

**Form Template Method**: When algorithms have the same structure but differ in specific steps, define a template method in the parent with override points for the varying parts.

**Consolidate Conditional Expression**: When the same logic appears in several conditional branches, merge the conditions and extract the shared body.

The right technique depends on where the duplication lives: the same class, sibling subclasses, and unrelated classes each need a different approach. The usual root causes are several programmers working in parallel, copy-paste under deadline pressure, and code that looks different but does the same job.

## Exceptions

Duplication is acceptable in these cases:

- **Performance-critical paths**: Inline code can outperform method calls in tight loops. Benchmark before extracting.
- **Distinct business domains**: Code that looks identical but serves different purposes may need to stay separate so it can evolve independently.
- **Simple guard clauses**: Identical null or type checks may be clearer inline than hidden behind an extraction.
- **Semantic constants**: The same literal value used in different contexts with different meanings does not justify consolidation.
- **Test fixtures**: Test code often duplicates setup logic on purpose, for clarity and isolation.

## Related smells

- **Long Method**: Long methods breed duplication because developers copy similar logic instead of extracting it
- **Long Parameter List**: May point to a missing abstraction that could absorb duplicated parameter groups
- **Divergent Change**: A class that changes for several reasons may hold scattered pockets of duplicated logic
- **Primitive Obsession**: Type-specific duplication that value objects could remove

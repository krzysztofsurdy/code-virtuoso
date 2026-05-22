## Overview

Duplicate code appears when two or more code fragments perform the same work using identical or near-identical logic. It is among the most frequently encountered code smells and serves as a clear signal that shared logic should be extracted into a single, reusable location. Every copy of the same logic is a liability - it multiplies the effort required for any change and undermines the DRY (Don't Repeat Yourself) principle.

## Why It's a Problem

When the same logic lives in multiple places, every fix, enhancement, or behavioral change must be applied to each copy individually:

- **Multiplied Maintenance**: A single conceptual change requires edits in several locations
- **Inconsistent Fixes**: Patching a bug in one copy while missing others creates hard-to-diagnose inconsistencies
- **Natural Drift**: Duplicates inevitably diverge over time as different developers modify different copies
- **Heavier Test Surface**: More code paths to cover, with no additional functional benefit
- **Wasted Reader Effort**: Developers spend time determining whether near-identical fragments truly behave the same way

## Signs and Symptoms

- Identical or near-identical code blocks appearing in different methods or classes
- Copy-pasted segments where only variable names differ
- Methods that share the same control flow structure but implement it separately
- Repeated constructor or accessor patterns across multiple classes
- The same validation, logging, or error-handling logic sprinkled throughout the codebase
- Similar database queries or API call sequences in unrelated files

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

**Extract Method**: When duplication occurs within the same class or closely related classes, pull the shared logic into its own method and call it from each original location.

**Extract Class**: When duplication spans unrelated classes, create a dedicated class to own the shared behavior and inject it as a dependency where needed.

**Pull Up Field/Method**: Within inheritance hierarchies, relocate duplicate code to the parent class so all subclasses can inherit it. For constructor duplication, apply **Pull Up Constructor Body**.

**Form Template Method**: When algorithms are structurally similar but differ in specific steps, define a template method in the parent with override points for the variable parts.

**Consolidate Conditional Expression**: When the same logic appears across multiple conditional branches, merge the conditions and extract the shared body.

The right technique depends on where the duplication lives: same class, sibling subclasses, or unrelated classes each call for a different approach. Multiple programmers working in parallel, copy-paste under deadline pressure, and code that looks different but performs the same job are the most common root causes.

## Exceptions

Duplication is acceptable in these cases:

- **Performance-critical paths**: Inline code can outperform method calls in tight loops. Benchmark before extracting.
- **Distinct business domains**: Code that looks identical but serves different conceptual purposes may belong separate to evolve independently.
- **Simple guard clauses**: Identical null or type checks may be clearer repeated inline than hidden behind an extraction.
- **Semantic constants**: The same literal value used in different contexts with different meanings does not warrant consolidation.
- **Test fixtures**: Test code often intentionally duplicates setup logic for clarity and isolation.

## Related Smells

- **Long Method**: Long methods breed duplication because developers copy similar logic rather than extracting it
- **Long Parameter List**: May point to a missing abstraction that could consolidate duplicated parameter groups
- **Divergent Change**: A class changing for multiple reasons may harbor diverse pockets of duplicated logic
- **Primitive Obsession**: Type-specific duplication that proper value objects could eliminate

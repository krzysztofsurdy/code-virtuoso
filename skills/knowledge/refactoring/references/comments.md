## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

The Comments smell appears when code needs inline explanations to be understood. Comments are not bad in themselves. They become a smell when they replace clear code instead of adding to it. If a block needs a comment to explain *what* it does, the fix is usually to restructure the code so the comment is no longer needed. Self-documenting code relies on good names, small focused methods, and explicit types.

## Why it's a problem

Even well-meant comments carry risks:

- **They rot quickly**: When code changes, comments are often left behind and become misleading
- **They mask structural weaknesses**: Heavy commenting usually means the code is too convoluted. Fixing the code is a better investment than annotating it
- **They compensate for poor naming**: Instead of renaming an unclear method or variable, developers add a comment next to it
- **They restate the obvious**: Comments that echo the code add noise
- **They discourage refactoring**: Developers may feel the code is "documented enough" and skip the structural fixes it needs

## Signs and symptoms

- Methods full of inline explanations
- Comments that describe *what* the code does instead of *why* a non-obvious decision was made
- Comments placed before complex expressions or logic blocks
- Stale comments that no longer match the current code behavior
- Comments that paraphrase variable or method names that could be renamed

## Before and after

### Before: unclear logic with heavy comments

```php
<?php declare(strict_types=1);

class OrderProcessor
{
    // Get all orders from the last 30 days and filter by status
    public function getActiveOrders(int $days = 30): array
    {
        $orders = [];
        // Calculate the date threshold
        $threshold = time() - ($days * 86400);

        // Loop through all orders
        foreach ($this->fetchAll() as $order) {
            // Check if order is within timeframe and not cancelled
            if ($order['timestamp'] >= $threshold && $order['status'] !== 'cancelled') {
                $orders[] = $order;
            }
        }

        return $orders;
    }

    // Calculate the total amount including tax
    public function calculateTotal(float $subtotal, string $taxCode): float
    {
        // Get the tax rate from the code
        $rate = match($taxCode) {
            'VAT20' => 0.20,
            'VAT10' => 0.10,
            'VAT0' => 0.00,
            default => 0.05,
        };

        // Multiply subtotal by rate and add
        return $subtotal * (1 + $rate);
    }
}
```

### After: self-documenting code

```php
<?php declare(strict_types=1);

enum TaxRate: float
{
    case Standard = 0.20;
    case Reduced = 0.10;
    case Exempt = 0.00;
    case Default = 0.05;

    public static function fromCode(string $code): self
    {
        return match($code) {
            'VAT20' => self::Standard,
            'VAT10' => self::Reduced,
            'VAT0' => self::Exempt,
            default => self::Default,
        };
    }
}

readonly class OrderFilter
{
    private readonly int $thresholdTimestamp;

    public function __construct(private int $daysBack = 30)
    {
        $this->thresholdTimestamp = time() - ($daysBack * 86400);
    }

    public function isWithinTimeframe(int $timestamp): bool
    {
        return $timestamp >= $this->thresholdTimestamp;
    }
}

class OrderProcessor
{
    public function getActiveOrders(int $daysBack = 30): array
    {
        $filter = new OrderFilter($daysBack);

        return array_filter(
            $this->fetchAll(),
            fn(array $order) => $filter->isWithinTimeframe($order['timestamp'])
                && !$order['isCancelled']()
        );
    }

    public function calculateTotalWithTax(float $subtotal, string $taxCode): float
    {
        $taxRate = TaxRate::fromCode($taxCode);
        return $subtotal * (1 + $taxRate->value);
    }
}
```

## Recommended refactorings

**Extract Method**: Turn commented code sections into separate, well-named methods. The method name replaces the comment.

**Rename Method/Variable**: Give unclear identifiers descriptive names. `$d` becomes `$daysThreshold`; `calc()` becomes `calculateTotalWithTax()`.

**Extract Variable**: Break complex expressions into intermediate variables with meaningful names. The clarifying comment is then unnecessary.

**Introduce Enum/Class**: Group related constants or values into enums or typed classes to clarify the code structure.

**Extract Assertion**: Replace comments that document expected state with assertions or type hints that enforce invariants.

## Exceptions

Comments are appropriate when:

- **Explaining "why", not "what"**: Business logic, legal requirements, or architectural decisions that the code alone does not show
- **Complex algorithms**: When an algorithm is complex and cannot be simplified, a comment explaining the approach is acceptable
- **API documentation**: PHPDoc blocks for public methods, parameters, and return types are part of the API contract
- **Non-obvious workarounds**: Explaining why an implementation that looks wrong is necessary (e.g., browser compatibility, performance trade-offs)

## Related smells

- **Long Method**: Methods that accumulate many comments are usually too long and should be decomposed
- **Poor Naming**: Comments often cover up unclear variable and method names
- **Duplicate Code**: Identical logic explained separately in comments in different places
- **Magic Numbers**: Unexplained numeric constants that force developers to write clarifying comments

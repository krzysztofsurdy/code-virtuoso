## Overview

The Comments smell surfaces when code relies heavily on inline explanations to make itself understood. Comments are not inherently bad - they become a smell when they substitute for clear code rather than supplementing it. If a block of code needs a comment to explain *what* it does, the real fix is usually restructuring the code so the comment becomes unnecessary. Truly self-documenting code communicates through well-chosen names, small focused methods, and explicit types.

## Why It's a Problem

Even well-intentioned comments introduce risks:

- **They rot quickly**: When code evolves, comments are often left behind, becoming misleading rather than helpful
- **They mask structural weaknesses**: Heavy commenting usually signals that the code itself is too convoluted - fixing the code is a better investment than annotating it
- **They compensate for poor naming**: Instead of renaming a method or variable to be self-explanatory, developers add a comment alongside the unclear name
- **They restate the obvious**: Comments that merely echo what the code already says add noise without value
- **They discourage refactoring**: Developers may feel the code is "documented enough" and skip the structural improvements it actually needs

## Signs and Symptoms

- Methods peppered with inline explanations throughout
- Comments that describe *what* the code does rather than *why* a non-obvious decision was made
- Comments placed before complex expressions or logic blocks
- Stale comments that no longer match the current code behavior
- Comments that paraphrase variable or method names that could simply be renamed

## Before/After Examples

### Before: Unclear Logic with Heavy Comments

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

### After: Self-Documenting Code

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

## Recommended Refactorings

**Extract Method**: Convert commented code sections into separate, well-named methods. The method name replaces the need for the comment.

**Rename Method/Variable**: Give unclear identifiers more descriptive names. `$d` becomes `$daysThreshold`; `calc()` becomes `calculateTotalWithTax()`.

**Extract Variable**: Break complex expressions into intermediate variables with meaningful names, eliminating the need for clarifying comments.

**Introduce Enum/Class**: Group related constants or values into enums or typed classes to make code structure clearer.

**Extract Assertion**: Replace comments documenting expected state with assertions or type hints that enforce invariants.

## Exceptions

Comments are valuable and appropriate when:

- **Explaining "why" not "what"**: Documenting business logic, legal requirements, or architectural decisions that aren't obvious from code alone
- **Documenting complex algorithms**: When an algorithm is inherently complex and simplification isn't feasible, a comment explaining the approach is acceptable
- **API documentation**: PHPDoc blocks for public methods, parameters, and return types serve as part of the API contract
- **Non-obvious workarounds**: Explaining why a seemingly incorrect implementation is necessary (e.g., browser compatibility, performance trade-offs)

## Related Smells

- **Long Method**: Methods that accumulate many comments are usually too long and should be decomposed
- **Poor Naming**: Comments frequently serve as a bandage over unclear variable and method names
- **Duplicate Code**: Identical logic explained separately in different locations via comments
- **Magic Numbers**: Unexplained numeric constants that force developers to write clarifying comments

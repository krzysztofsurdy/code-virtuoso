## Overview

The Comments code smell occurs when code is filled with explanatory comments meant to clarify what the code does. While comments can be valuable, excessive comments often indicate that the code structure itself needs improvement. The best code is self-documenting through meaningful names and clear structure.

## Why It's a Problem

Comments are frequently created with good intentions, but they often mask deeper issues:

- **They become maintenance burdens**: When code changes, comments frequently become outdated and misleading
- **They indicate poor code design**: If code requires extensive comments to understand, the code structure is likely the problem, not the lack of documentation
- **They hide bad naming**: Comments compensate for unclear method/variable names instead of addressing the root cause
- **They duplicate information**: Comments often restate what the code already expresses clearly
- **They create false security**: Developers may rely on comments instead of refactoring confusing code

## Signs and Symptoms

- Methods containing numerous explanatory comments
- Comments describing what the code does rather than why
- Comments explaining complex expressions or logic sections
- Comments that become outdated as code changes
- Comments that rephrase variable/method names that could be clearer

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

- **Long Method**: Methods that require many comments are often too long and should be broken down
- **Poor Naming**: Comments often compensate for unclear variable and method names
- **Duplicate Code**: Repeated logic that's explained separately via comments
- **Magic Numbers**: Unexplained constants that force developers to add clarifying comments

## Refactoring.guru Guidance

### Signs and Symptoms

A method is filled with explanatory comments that attempt to clarify what the code does.

### Reasons for the Problem

Comments are usually created with the best of intentions, when the author realizes that their code is not intuitive or obvious. The best comment is a good name for a method or class.

### Treatment

- **Extract Variable**: If a comment explains a complex expression, break the expression into understandable sub-expressions using well-named intermediate variables.
- **Extract Method**: If a comment explains a section of code, turn that section into a separate method. The method name should replace the comment.
- **Rename Method**: If a method has been extracted but still needs a comment to explain what it does, give the method a self-explanatory name.
- **Introduce Assertion**: If you need to assert rules about the state of the system, use an assertion instead of a comment.

### Payoff

- Code becomes more intuitive and self-documenting.

### When to Ignore

- Comments explaining **why** something is done (not what) remain valuable.
- Comments documenting complex algorithms where simplification is not feasible.

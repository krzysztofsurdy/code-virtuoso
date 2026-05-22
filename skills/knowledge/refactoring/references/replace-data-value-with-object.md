## Overview

Replace Data Value with Object promotes a bare primitive - a string, integer, or similar simple type - into a dedicated class. What starts as a single field often accumulates validation rules, formatting logic, and related operations that do not belong on the host class. Wrapping the value in its own object gives that behavior a proper home and turns a passive piece of data into an active participant in the domain model.

## Motivation

### When to Apply

- **Primitive obsession**: Using strings or integers to represent domain concepts (IDs, codes, amounts)
- **Scattered validation**: Same validation logic repeated in multiple places
- **Missing behavior**: Data lacks associated operations that belong conceptually with it
- **Weak type safety**: Using generic primitives instead of domain-specific types
- **Inconsistent representation**: The same concept handled differently in different parts of code
- **Expandable requirements**: A simple value may need additional properties or methods
- **Cross-cutting concerns**: Formatting, parsing, or validation applied repeatedly

### Why It Matters

Elevating a primitive to a first-class object centralizes validation, attaches behavior to the data it belongs with, and replaces vague types with explicit domain vocabulary. The result is a codebase where business rules are enforced at the point of creation rather than scattered across consumers.

## Mechanics: Step-by-Step

1. **Identify the primitive**: Find the simple data value needing object treatment
2. **Create new class**: Design a dedicated class representing the concept
3. **Define constructor**: Implement validation and initialization logic
4. **Add factory methods**: Consider named constructors for common creation patterns
5. **Encapsulate behavior**: Move related logic into the new class
6. **Replace usages**: Update code to use the new object instead of primitive
7. **Test thoroughly**: Ensure behavior and validation work correctly
8. **Refine interface**: Optimize public API based on actual usage patterns

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Order
{
    private int $id;
    private string $email;
    private int $amount; // In cents
    private string $currencyCode;

    public function __construct(int $id, string $email, int $amount, string $currencyCode)
    {
        if (empty($email) || !str_contains($email, '@')) {
            throw new InvalidArgumentException('Invalid email');
        }

        if ($amount <= 0) {
            throw new InvalidArgumentException('Amount must be positive');
        }

        if (strlen($currencyCode) !== 3) {
            throw new InvalidArgumentException('Invalid currency code');
        }

        $this->id = $id;
        $this->email = $email;
        $this->amount = $amount;
        $this->currencyCode = $currencyCode;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function getAmount(): int
    {
        return $this->amount;
    }

    public function getCurrencyCode(): string
    {
        return $this->currencyCode;
    }

    public function getFormattedAmount(): string
    {
        return '$' . ($this->amount / 100);
    }
}

class EmailValidator
{
    public static function validate(string $email): bool
    {
        return !empty($email) && str_contains($email, '@');
    }
}

class OrderProcessor
{
    public function sendConfirmation(string $email): void
    {
        // Email validation logic scattered
        if (empty($email) || !str_contains($email, '@')) {
            throw new InvalidArgumentException('Invalid email');
        }
        // Send email...
    }

    public function createInvoice(string $email, int $amount, string $currencyCode): void
    {
        // Validation logic repeated
        if ($amount <= 0) {
            throw new InvalidArgumentException('Amount must be positive');
        }
        // Generate invoice...
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

final readonly class Email
{
    private function __construct(private string $value) {}

    public static function create(string $value): self
    {
        if (empty($value) || !str_contains($value, '@')) {
            throw new InvalidArgumentException(
                sprintf('"%s" is not a valid email address', $value)
            );
        }

        return new self($value);
    }

    public function getValue(): string
    {
        return $this->value;
    }

    public function getDomain(): string
    {
        $parts = explode('@', $this->value);
        return $parts[1] ?? '';
    }

    public function __toString(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }
}

final readonly class Money
{
    private function __construct(
        private int $amount,
        private string $currencyCode,
    ) {}

    public static function create(int $amount, string $currencyCode): self
    {
        if ($amount <= 0) {
            throw new InvalidArgumentException('Amount must be positive');
        }

        if (strlen($currencyCode) !== 3) {
            throw new InvalidArgumentException('Invalid currency code');
        }

        return new self($amount, $currencyCode);
    }

    public function getAmount(): int
    {
        return $this->amount;
    }

    public function getCurrencyCode(): string
    {
        return $this->currencyCode;
    }

    public function getFormatted(): string
    {
        return sprintf('%s %.2f', $this->currencyCode, $this->amount / 100);
    }

    public function add(self $other): self
    {
        if ($this->currencyCode !== $other->currencyCode) {
            throw new InvalidArgumentException('Cannot add different currencies');
        }

        return new self($this->amount + $other->amount, $this->currencyCode);
    }
}

class Order
{
    public function __construct(
        private int $id,
        private Email $email,
        private Money $amount,
    ) {}

    public function getEmail(): Email
    {
        return $this->email;
    }

    public function getAmount(): Money
    {
        return $this->amount;
    }
}

class OrderProcessor
{
    public function sendConfirmation(Email $email): void
    {
        // Email validation already handled by Email class
        // Send email to $email->getValue()...
    }

    public function createInvoice(Email $email, Money $amount): void
    {
        // Money validation already handled by Money class
        // Generate invoice with $amount->getFormatted()...
    }
}
```

## Benefits

- **Enforced invariants**: Validation happens once, at construction, rather than at every use site
- **Behavior co-location**: Operations on the value live next to the value itself
- **Explicit domain vocabulary**: Type names like `Email` and `Money` make code read like prose
- **Immutability by design**: Value objects are typically `readonly`, eliminating accidental mutation
- **Meaningful equality**: Objects can define what "same" means for their domain concept
- **Isolated testability**: Each value object can be tested independently of the rest of the system
- **Reduced primitive coupling**: Consumers depend on domain abstractions, not raw strings and integers

## When NOT to Use

- **Simple pass-through values**: If the primitive needs no validation or behavior, keep it simple
- **External API contracts**: Don't wrap third-party data; maintain compatibility
- **High-volume operations**: Excessive object creation may impact performance (profile first)
- **Performance-critical tight loops**: Though usually negligible with modern PHP
- **Legacy systems with strict contracts**: Refactoring may break existing interfaces
- **Not yet stabilized requirements**: Wait until the concept's role is clear

## Related Refactorings

- **Extract Class**: When a value object needs to become a full entity with identity
- **Introduce Parameter Object**: Groups multiple parameters as a value object
- **Move Method**: Transfer behavior from procedural code into the new value object
- **Replace Type Code with Classes**: Converts enumerations to value objects with behavior
- **Hide Delegate**: Encapsulates value object access behind a simpler interface

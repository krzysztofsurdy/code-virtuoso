## Overview

Replace Data Value with Object is a refactoring technique that transforms simple primitive data values (strings, integers, arrays) into dedicated objects. This elevates data from passive containers to active entities capable of encapsulating behavior, validation, and business logic. The refactoring is particularly valuable when a single data value acquires multiple responsibilities or requires consistent handling across your codebase.

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

This refactoring strengthens type safety, centralizes validation and behavior, improves code clarity, and makes the domain model explicit. It bridges the gap between anemic data structures and rich domain models, allowing code to express business intent more naturally.

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

- **Type Safety**: Compiler-level protection against misusing primitive values
- **Centralized Validation**: Business rules exist in one place, not scattered throughout code
- **Encapsulated Behavior**: Related operations belong directly with their data
- **Self-Documenting Code**: Domain concepts become explicit types in the codebase
- **Immutability**: Value objects are typically immutable, preventing accidental mutations
- **Equality by Value**: Objects can implement meaningful equality semantics
- **Easier Testing**: Focused classes are simpler to test in isolation
- **Reduced Coupling**: Calling code depends on domain abstractions, not primitives
- **Domain-Driven Design**: Aligns code structure with business domain concepts

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

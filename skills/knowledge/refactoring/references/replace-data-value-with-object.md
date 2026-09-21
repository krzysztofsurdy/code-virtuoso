## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)

## Overview

Replace Data Value with Object turns a bare primitive (a string, integer, or similar simple type) into a dedicated class. A single field often picks up validation rules, formatting logic, and related operations that do not belong on the host class. Wrapping the value in its own object gives that behavior a home and makes the data an active part of the domain model.

## Motivation

### When to apply

- **Primitive obsession**: Strings or integers represent domain concepts (IDs, codes, amounts)
- **Scattered validation**: The same validation logic is repeated in several places
- **Missing behavior**: The data lacks operations that belong with it
- **Weak type safety**: Generic primitives are used instead of domain-specific types
- **Inconsistent representation**: The same concept is handled differently in different parts of the code
- **Growing requirements**: A simple value may need more properties or methods
- **Cross-cutting concerns**: Formatting, parsing, or validation is applied repeatedly

### Why it matters

Making a primitive a first-class object centralizes validation, attaches behavior to the data it belongs with, and replaces vague types with explicit domain vocabulary. Business rules are then enforced where the value is created, not scattered across consumers.

## Mechanics

1. **Identify the primitive**: Find the simple data value that needs to become an object
2. **Create the class**: Design a dedicated class for the concept
3. **Define the constructor**: Implement validation and initialization logic
4. **Add factory methods**: Consider named constructors for common creation patterns
5. **Encapsulate behavior**: Move related logic into the new class
6. **Replace usages**: Update code to use the new object instead of the primitive
7. **Run the tests**: Check that behavior and validation work
8. **Refine the interface**: Adjust the public API based on how it is actually used

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

- **Enforced invariants**: Validation happens once, at construction, not at every use site
- **Behavior next to data**: Operations on the value live with the value
- **Domain vocabulary**: Type names like `Email` and `Money` make the code read clearly
- **Immutability**: Value objects are typically `readonly`, which prevents accidental mutation
- **Meaningful equality**: Objects can define what "same" means for their domain concept
- **Isolated testing**: Each value object can be tested independently of the rest of the system
- **Less primitive coupling**: Consumers depend on domain types, not raw strings and integers

## When NOT to use

- **Pass-through values**: If the primitive needs no validation or behavior, keep it as is
- **External API contracts**: Do not wrap third-party data; keep compatibility
- **High-volume operations**: Creating many objects may affect performance (profile first)
- **Performance-critical tight loops**: The cost is usually negligible in modern PHP
- **Legacy systems with strict contracts**: The refactoring may break existing interfaces
- **Unsettled requirements**: Wait until the concept's role is clear

## Related Refactorings

- **Extract Class**: Use it when a value object needs to become a full entity with identity
- **Introduce Parameter Object**: Groups multiple parameters as a value object
- **Move Method**: Transfer behavior from procedural code into the new value object
- **Replace Type Code with Class**: Converts enumerations to value objects with behavior
- **Hide Delegate**: Hides access to the value object behind a simpler interface

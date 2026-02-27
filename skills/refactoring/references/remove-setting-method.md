# Remove Setting Method

## Overview

The **Remove Setting Method** refactoring eliminates setter methods for object fields that should be initialized during construction and remain unchanged throughout the object's lifetime. This technique enforces immutability patterns and makes object contracts more explicit and reliable.

## Motivation

Setter methods create opportunities for unintended state mutations. When a field's value should only be established during object creation, keeping the setter method:

- Allows accidental modifications that violate object design assumptions
- Makes it unclear whether a field's value can change after initialization
- Creates maintenance challenges when code elsewhere assumes immutability
- Reduces code clarity by providing APIs that don't match actual usage patterns

Removing setter methods for immutable fields makes the programmer's intent explicit: these values are fixed at construction time.

## Mechanics

1. **Identify immutable fields** - Locate fields that should never change after object construction
2. **Update the constructor** - Ensure the constructor accepts parameters for initializing these fields
3. **Find setter invocations** - Search for all calls to the setter method throughout the codebase
4. **Replace setter calls** - Move initialization to the constructor call instead
5. **Remove the setter** - Delete the setter method definition
6. **Verify immutability** - Confirm no other code attempts to modify these fields

## Before/After Example

### Before (PHP 8.3+)

```php
class Account
{
    private string $accountNumber;
    private string $accountHolder;
    private float $balance = 0.0;

    public function __construct()
    {
    }

    public function setAccountNumber(string $number): void
    {
        $this->accountNumber = $number;
    }

    public function setAccountHolder(string $holder): void
    {
        $this->accountHolder = $holder;
    }

    public function getAccountNumber(): string
    {
        return $this->accountNumber;
    }

    public function getAccountHolder(): string
    {
        return $this->accountHolder;
    }

    public function getBalance(): float
    {
        return $this->balance;
    }
}

// Usage
$account = new Account();
$account->setAccountNumber('ACC-12345');
$account->setAccountHolder('John Doe');
```

### After (PHP 8.3+)

```php
class Account
{
    public function __construct(
        private readonly string $accountNumber,
        private readonly string $accountHolder,
        private float $balance = 0.0,
    ) {
    }

    public function getAccountNumber(): string
    {
        return $this->accountNumber;
    }

    public function getAccountHolder(): string
    {
        return $this->accountHolder;
    }

    public function getBalance(): float
    {
        return $this->balance;
    }
}

// Usage
$account = new Account('ACC-12345', 'John Doe');
```

## Benefits

- **Enforced Immutability** - `readonly` properties prevent accidental modifications after construction
- **Clearer Intent** - Required constructor parameters make dependencies explicit
- **Reduced Complexity** - Less code to maintain and understand
- **Safer APIs** - Object contracts are clearer and harder to violate
- **Better Reasoning** - Immutable state is easier to reason about and debug
- **Modern PHP** - Leverages PHP 8.3+ constructor property promotion and `readonly` modifier

## When NOT to Use

- **Legitimate mutability needed** - If the field's value legitimately needs to change, keep the setter
- **Optional initialization** - If the field is truly optional and might be set later, a setter may be appropriate
- **Framework requirements** - Some frameworks require setter methods for serialization or data mapping
- **Lazy initialization** - If values are calculated on first access, setters may still be useful
- **Object evolution** - If the object is meant to evolve through multiple state changes, setters serve a purpose

## Related Refactorings

- **Introduce Parameter Object** - Group multiple constructor parameters into dedicated objects
- **Change Reference to Value** - Often paired with this refactoring for immutable value objects
- **Replace Constructor with Factory Method** - Provides alternative initialization patterns
- **Introduce Builder** - For complex objects with many optional initialization parameters

# Remove Setting Method

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Example](#beforeafter-example)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)

## Overview

Remove Setting Method deletes setters for fields that should be set at construction time and never change afterward. Without the setter, the class says the field is fixed once the object exists. Later code cannot change it by accident.

## Motivation

A setter that should never be called after initialization misleads callers. Its presence signals that the field is mutable, so code starts changing the value at arbitrary points. The results:

- Unintended state changes that violate the object's design assumptions
- Ambiguity about whether a field is meant to be stable or changeable
- Bugs that are hard to trace when distant code alters a supposedly fixed value
- A gap between what the API promises and what the object's contract actually is

Removing the setter and initializing the field through the constructor makes immutability explicit and enforceable.

## Mechanics

1. **Identify immutable fields**: Locate fields that should never change after construction.
2. **Update the constructor**: Make sure it accepts parameters for initializing these fields.
3. **Find setter invocations**: Search the codebase for every call to the setter.
4. **Replace setter calls**: Move the initialization into the constructor call.
5. **Remove the setter**: Delete the setter method.
6. **Verify immutability**: Confirm no other code tries to modify these fields.

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

- **Guaranteed stability**: `readonly` properties make mutation after construction impossible at the language level
- **Explicit dependencies**: Required constructor parameters declare what the object needs up front
- **Smaller API**: Fewer methods to learn, test, and maintain
- **Trustworthy contracts**: Callers know the object will not change under them
- **Simpler reasoning**: Immutable state removes a whole class of temporal bugs
- **Constructor promotion**: Takes advantage of constructor promotion and the `readonly` modifier

## When NOT to use

- **The value legitimately changes**: Keep the setter.
- **Optional initialization**: If the field is optional and might be set later, a setter may be appropriate.
- **Framework requirements**: Some frameworks need setters for serialization or data mapping.
- **Lazy initialization**: If values are calculated on first access, setters may still be useful.
- **Evolving objects**: If the object is meant to go through several state changes, setters have a purpose.

## Related Refactorings

- **Introduce Parameter Object**: Group multiple constructor parameters into dedicated objects
- **Change Reference to Value**: Often paired with this refactoring for immutable value objects
- **Replace Constructor with Factory Method**: Provides alternative initialization patterns
- **Builder pattern**: For complex objects with many optional initialization parameters

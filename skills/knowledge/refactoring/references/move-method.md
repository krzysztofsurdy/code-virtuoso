# Move Method

## Overview

Move Method transfers a method to the class where it fits better. When a method depends more on the data or behavior of another class than on its own, moving it puts it next to its collaborators. Cohesion goes up and coupling between classes goes down.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after: PHP 8.3+ example](#before-and-after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

Methods drift away from the data they work on as a codebase evolves. A method probably belongs elsewhere when:

- It reads or writes fields of another class more than its own
- Most callers belong to a different class
- It couples two otherwise independent classes
- Keeping it in place violates the Single Responsibility Principle

Moving it to the class it interacts with most:

- Puts behavior next to the data it uses
- Cuts message traffic between classes
- Strengthens encapsulation in each class
- Makes the code easier to navigate

## Mechanics

1. **Analyze dependencies**: list the class members and parameters the method uses.
2. **Check visibility**: confirm the method can be moved (check access permissions).
3. **Find references**: identify every place that calls the method.
4. **Create in the target class**: define the method in the destination class with a suitable signature.
5. **Update calls**: replace calls from the source class with calls to the target class.
6. **Remove the original**: delete the method from the source class.
7. **Run the tests**: confirm that behavior is unchanged.

## Before and after: PHP 8.3+ example

### Before: method in the wrong class

```php
class Account
{
    private float $balance;
    private AccountType $type;

    public function __construct(float $balance, AccountType $type)
    {
        $this->balance = $balance;
        $this->type = $type;
    }

    // This method belongs in AccountType, not Account
    public function getInterestRate(): float
    {
        return match ($this->type->getName()) {
            'savings' => 0.05,
            'checking' => 0.01,
            'money_market' => 0.08,
            default => 0.0,
        };
    }

    public function calculateInterest(): float
    {
        return $this->balance * $this->getInterestRate();
    }
}

class AccountType
{
    private string $name;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }
}
```

### After: method moved to the target class

```php
class Account
{
    private float $balance;
    private AccountType $type;

    public function __construct(float $balance, AccountType $type)
    {
        $this->balance = $balance;
        $this->type = $type;
    }

    public function calculateInterest(): float
    {
        return $this->balance * $this->type->getInterestRate();
    }
}

class AccountType
{
    private string $name;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    // Method moved here - it belongs with the data it uses
    public function getInterestRate(): float
    {
        return match ($this->name) {
            'savings' => 0.05,
            'checking' => 0.01,
            'money_market' => 0.08,
            default => 0.0,
        };
    }
}
```

### Moving a longer method

```php
// Before: validation in PaymentProcessor that belongs in Payment
class PaymentProcessor
{
    public function validatePayment(Payment $payment): bool
    {
        if ($payment->getAmount() <= 0) {
            return false;
        }
        if (empty($payment->getReference())) {
            return false;
        }
        if ($payment->getDate() > new DateTime()) {
            return false;
        }
        return true;
    }
}

// After: validation moved to Payment class
class Payment
{
    private float $amount;
    private string $reference;
    private DateTime $date;

    public function isValid(): bool
    {
        if ($this->amount <= 0) {
            return false;
        }
        if (empty($this->reference)) {
            return false;
        }
        if ($this->date > new DateTime()) {
            return false;
        }
        return true;
    }
}

class PaymentProcessor
{
    public function process(Payment $payment): bool
    {
        return $payment->isValid();
    }
}
```

## Benefits

- **Stronger encapsulation**: methods sit next to the data they depend on.
- **Looser coupling**: classes are more self-contained.
- **Easier navigation**: related logic is found next to its data.
- **Localized changes**: a change to related functionality stays inside one class.
- **Clear responsibilities**: each class owns a coherent set of operations.
- **Cleaner public interfaces**: APIs reflect real dependencies, not historical accidents.

## When not to use

- The method needs private members of the source class that cannot be exposed.
- Moving it would create circular dependencies between classes.
- The method is part of a public API that external code relies on.
- The target class is in a different layer of the application, so the move would break layering.
- The method logic is generic and belongs in a utility or base class.

## Related refactorings

- **Extract Method**: break down a complex method before moving it.
- **Extract Class**: if a class has too many responsibilities, extract a new class and move methods to it.
- **Introduce Parameter Object**: use it when moving a method requires passing many parameters.
- **Hide Delegate**: the reverse operation, for when you want to keep the original interface.
- **Replace Temp with Query**: often used alongside Move Method to simplify data flow.

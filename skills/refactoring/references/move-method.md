## Overview

Move Method is a fundamental refactoring technique that relocates a method from one class to another. This refactoring is used when a method is more closely related to another class than the class it currently belongs to, improving encapsulation and reducing coupling between classes.

## Motivation

Methods often become misplaced when code evolves. A method might:
- Use more features from another class than its own
- Be called primarily by instances of a different class
- Create tight coupling between unrelated classes
- Violate the Single Responsibility Principle

Moving the method to a more appropriate class:
- Improves code organization and clarity
- Reduces inter-class coupling
- Enhances encapsulation
- Makes the codebase easier to understand and maintain
- Aligns with the principle that methods should be close to the data they manipulate

## Mechanics

1. **Analyze dependencies**: Examine which class members and parameters the method uses
2. **Check visibility**: Ensure the method can be safely moved (check access permissions)
3. **Handle references**: Identify all places where the method is called
4. **Create in target class**: Define the method in the destination class with appropriate signature
5. **Update calls**: Replace calls from the source class with calls to the target class
6. **Remove original**: Delete the method from the source class
7. **Test thoroughly**: Ensure all functionality remains intact

## Before/After: PHP 8.3+ Example

### Before: Method in Wrong Class

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

### After: Method Moved to Target Class

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

### Advanced Example: Moving Complex Methods

```php
// Before: Complex validation in PaymentProcessor that belongs in Payment
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

// After: Validation moved to Payment class
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

- **Better Encapsulation**: Methods are placed with the data they operate on
- **Reduced Coupling**: Classes become more independent and focused
- **Improved Readability**: Code becomes easier to understand and navigate
- **Enhanced Maintainability**: Changes to related functionality are localized
- **Clearer Responsibilities**: Each class has a single, well-defined purpose
- **Better API Design**: Public interfaces reflect actual dependencies

## When NOT to Use

- When the method needs access to private members of the source class that can't be exposed
- When moving would create circular dependencies between classes
- When the method is part of a public API heavily used by external code
- When the target class is in a different layer of the application (violates layering)
- When the method logic is generic and truly belongs in a utility or base class

## Related Refactorings

- **Extract Method**: Break down complex methods before moving them
- **Extract Class**: If a class has too many responsibilities, extract a new class and move methods to it
- **Introduce Parameter Object**: When moving a method requires passing multiple parameters
- **Hide Delegate**: Reverse operation when you want to preserve the original interface
- **Replace Temp with Query**: Often used alongside moving methods to simplify data flow

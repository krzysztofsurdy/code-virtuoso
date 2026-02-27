# Switch Statements Code Smell

## Overview

Switch statements (and lengthy if-else chains) are a code smell that signals violations of object-oriented design principles. They indicate places where polymorphism should be used instead of conditional logic. While not inherently evil, complex or scattered switch statements make code harder to maintain and extend.

## Why It's a Problem

Switch statements create tight coupling between the code and the types being checked. When requirements change, you must find and modify every switch statement handling that logic. This violates the Open/Closed Principle—code should be open for extension but closed for modification.

Additionally, switch statements indicate missing abstractions. Different cases often represent different behaviors that should be encapsulated in separate classes. This makes code less flexible and harder to test.

## Signs and Symptoms

- Complex switch operators with many cases
- Multiple similar switch statements scattered throughout the codebase
- Switch statements that handle type checking based on object properties
- Adding new cases requires modifying multiple switch locations
- Switch statements with deeply nested logic or side effects
- Difficulty testing individual cases in isolation

## Before/After Examples

### Before: Type-Based Switching

```php
<?php

declare(strict_types=1);

enum PaymentMethod: string {
    case CREDIT_CARD = 'credit_card';
    case BANK_TRANSFER = 'bank_transfer';
    case PAYPAL = 'paypal';
}

readonly class Payment {
    public function __construct(
        public float $amount,
        public PaymentMethod $method,
    ) {}
}

function processPayment(Payment $payment): string {
    return match ($payment->method) {
        PaymentMethod::CREDIT_CARD => 'Processing credit card: ' . $payment->amount,
        PaymentMethod::BANK_TRANSFER => 'Processing bank transfer: ' . $payment->amount,
        PaymentMethod::PAYPAL => 'Processing PayPal: ' . $payment->amount,
    };
}

function getPaymentFee(Payment $payment): float {
    return match ($payment->method) {
        PaymentMethod::CREDIT_CARD => $payment->amount * 0.03,
        PaymentMethod::BANK_TRANSFER => 5.0,
        PaymentMethod::PAYPAL => $payment->amount * 0.02,
    };
}
```

### After: Polymorphism-Based Approach

```php
<?php

declare(strict_types=1);

interface PaymentProcessor {
    public function process(float $amount): string;
    public function calculateFee(float $amount): float;
}

readonly class CreditCardProcessor implements PaymentProcessor {
    public function process(float $amount): string {
        return 'Processing credit card: ' . $amount;
    }

    public function calculateFee(float $amount): float {
        return $amount * 0.03;
    }
}

readonly class BankTransferProcessor implements PaymentProcessor {
    public function process(float $amount): string {
        return 'Processing bank transfer: ' . $amount;
    }

    public function calculateFee(float $amount): float {
        return 5.0;
    }
}

readonly class PayPalProcessor implements PaymentProcessor {
    public function process(float $amount): string {
        return 'Processing PayPal: ' . $amount;
    }

    public function calculateFee(float $amount): float {
        return $amount * 0.02;
    }
}

readonly class Payment {
    public function __construct(
        public float $amount,
        private PaymentProcessor $processor,
    ) {}

    public function process(): string {
        return $this->processor->process($this->amount);
    }

    public function getFee(): float {
        return $this->processor->calculateFee($this->amount);
    }
}
```

## Recommended Refactorings

**Replace Type Code with Subclasses**
Create separate classes for each case instead of using type codes. Each class implements the same interface but with different behaviors.

**Replace Conditional with Polymorphism**
Use inheritance or interface implementation to let each object handle its own behavior. This is the most common refactoring for switch statements.

**Introduce Strategy Pattern**
When behavior varies at runtime, inject different strategy implementations. This allows flexible composition without inheritance.

**Replace Parameter with Explicit Methods**
Break a method accepting various type parameters into separate methods. Each method name makes the intent clearer.

**Extract Method and Move Method**
Isolate switch logic into dedicated methods, then move them to appropriate classes that handle specific cases.

**Introduce Null Object**
When handling null cases, create a null object implementing your interface instead of checking for null conditions.

## Exceptions

Simple switches are acceptable in these cases:

- **Factory patterns**: Creating appropriate objects based on input is a legitimate use of switches
- **Mapping operations**: Simple data transformations without behavior differences (e.g., enum to string)
- **Router/dispatcher logic**: Directing to appropriate handlers is expected in frameworks
- **Guard clauses**: Validating preconditions with early returns
- **Single switch locations**: A well-placed switch serving one clear purpose is less problematic than scattered switches

## Related Smells

- **Primitive Obsession**: Switch statements often indicate missing value objects or enums
- **Duplicate Code**: Scattered switches suggest duplicated conditional logic
- **Long Method**: Complex switches signal methods doing too much
- **Speculative Generality**: Over-engineered polymorphism for non-existent requirements
- **Lazy Class**: Unnecessary classes created solely to replace switches

## Refactoring.guru Guidance

### Signs and Symptoms
You have a complex `switch` operator or sequence of `if` statements. Code for a single switch can be scattered in different places in the program.

### Reasons for the Problem
Switch operators are relatively rare in well-designed object-oriented code. When you see `switch` you should think of polymorphism. When requirements change, developers must locate and update every instance of the switch.

### Treatment
- **Extract Method** and **Move Method** to isolate switch logic appropriately
- **Replace Type Code with Subclasses** or **Replace Type Code with State/Strategy** for type code-based switches
- **Replace Conditional with Polymorphism** after establishing inheritance structure
- **Replace Parameter with Explicit Methods** when conditions call identical methods with different parameters
- **Introduce Null Object** if null is a conditional option

### Payoff
- Improved code organization

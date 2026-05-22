# Switch Statements Code Smell

## Overview

Switch statements (and lengthy if-else chains) are a code smell that points to missed opportunities for polymorphism. When you see conditional logic branching on an object's type or category, it usually means the behavior should be distributed across specialized classes rather than centralized in one block. A single, isolated switch is rarely a problem - the smell intensifies when similar switches appear in multiple places throughout the codebase.

## Why It's a Problem

Branching on type creates a rigid bond between the conditional logic and the set of types it handles. Every time a new type is introduced, you must track down and update every switch that deals with that classification. This directly violates the Open/Closed Principle - the system should accommodate new variants without modifying existing code.

Beyond maintainability, scattered switch statements signal missing abstractions. Each case branch typically represents a distinct behavior that belongs in its own class, where it can be tested independently and extended without ripple effects.

## Signs and Symptoms

- Switch or match blocks with many cases
- The same branching pattern duplicated in several places across the codebase
- Conditional logic that inspects an object's type or property to decide behavior
- Adding a new variant forces changes in multiple switch locations
- Deeply nested logic or side effects inside case branches
- Individual cases that are hard to test in isolation

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
Instead of switching on type codes, create a class for each variant. All classes share the same interface but provide their own implementation of the behavior.

**Replace Conditional with Polymorphism**
The most common remedy. Let each object define its own behavior through inheritance or interface implementation, eliminating the need for external branching entirely.

**Introduce Strategy Pattern**
When behavior must vary at runtime, inject different strategy implementations. This achieves flexible composition without requiring an inheritance hierarchy.

**Replace Parameter with Explicit Methods**
Split a method that accepts a type parameter into separate, clearly named methods. The method name itself communicates the intent.

**Extract Method and Move Method**
Pull the switch logic into its own method first, then relocate it to the class where it belongs - typically the class representing the type being switched on.

**Introduce Null Object**
When one of the cases handles null, replace the null check with a dedicated null object that implements the expected interface with default behavior.

## Exceptions

Simple switches are appropriate in these situations:

- **Factory patterns**: Instantiating the right class based on input is a natural use of switches
- **Mapping operations**: Straightforward data transformations without behavioral differences (e.g., converting an enum to a display string)
- **Router/dispatcher logic**: Directing requests to the appropriate handler is standard in frameworks
- **Guard clauses**: Validating preconditions with early returns
- **Single, isolated switches**: A switch that appears in exactly one place and serves one clear purpose is far less problematic than duplicated switches

## Related Smells

- **Primitive Obsession**: Switches often compensate for missing value objects or enums
- **Duplicate Code**: Repeated switches across the codebase indicate duplicated conditional logic
- **Long Method**: Complex switches are a sign that a method is handling too many responsibilities
- **Speculative Generality**: Replacing simple switches with elaborate polymorphism for hypothetical future needs
- **Lazy Class**: Classes created solely to replace a switch that didn't warrant the abstraction

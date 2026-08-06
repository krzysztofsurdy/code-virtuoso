# Switch Statements Code Smell

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before/After Examples](#beforeafter-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Switch statements (and long if-else chains) are a smell that points to a missed chance for polymorphism. Conditional logic that branches on an object's type or category usually belongs in specialized classes, not in one central block. A single, isolated switch is rarely a problem. The smell gets worse when similar switches appear in several places.

## Why it's a problem

Branching on type ties the conditional logic to the set of types it handles. Each time you add a type, you must find and update every switch on that classification. This violates the Open/Closed Principle: the system should accept new variants without changes to existing code.

Scattered switches also point to missing abstractions. Each case usually represents a distinct behavior that belongs in its own class, where it can be tested alone and extended without ripple effects.

## Signs and symptoms

- Switch or match blocks with many cases.
- The same branching pattern repeated in several places.
- Conditional logic that inspects an object's type or property to decide behavior.
- Adding a new variant forces changes in several switch locations.
- Deeply nested logic or side effects inside case branches.
- Individual cases that are hard to test alone.

## Before/After Examples

### Before: type-based switching

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

### After: polymorphism-based approach

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

## Recommended refactorings

**Replace Type Code with Subclasses**
Instead of switching on type codes, create a class for each variant. All classes share one interface and supply their own behavior.

**Replace Conditional with Polymorphism**
The most common remedy. Each object defines its own behavior through inheritance or an interface, so no external branching is needed.

**Introduce Strategy pattern**
When behavior must vary at runtime, inject different strategy implementations. This gives flexible composition without an inheritance hierarchy.

**Replace Parameter with Explicit Methods**
Split a method that takes a type parameter into separate, well-named methods. The method name states the intent.

**Extract Method and Move Method**
Pull the switch logic into its own method first, then move it to the class where it belongs, usually the class for the type being switched on.

**Introduce Null Object**
When one of the cases handles null, replace the null check with a null object that implements the expected interface with default behavior.

## Exceptions

Simple switches are fine in these situations:

- **Factory patterns**: creating the right class from input is a natural use of a switch.
- **Mapping operations**: straightforward data transformations with no behavioral differences (e.g., converting an enum to a display string).
- **Router/dispatcher logic**: directing requests to the right handler is standard in frameworks.
- **Guard clauses**: validating preconditions with early returns.
- **Single, isolated switches**: a switch in exactly one place with one clear purpose is far less of a problem than duplicated switches.

## Related smells

- **Primitive Obsession**: switches often make up for missing value objects or enums.
- **Duplicate Code**: repeated switches across the codebase are duplicated conditional logic.
- **Long Method**: a complex switch suggests a method with too many responsibilities.
- **Speculative Generality**: elaborate polymorphism replacing a simple switch for hypothetical future needs.
- **Lazy Class**: a class created only to replace a switch that did not need the abstraction.

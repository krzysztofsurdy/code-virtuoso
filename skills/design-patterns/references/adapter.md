## Overview

The Adapter design pattern is a structural pattern that enables objects with incompatible interfaces to collaborate. It wraps an object with an incompatible interface and exposes a new interface that the client expects, acting as a translator between two incompatible systems.

## Intent

The Adapter pattern solves the problem of using a class that doesn't match the interface you need. It allows you to:

- Make incompatible interfaces compatible
- Integrate third-party libraries seamlessly
- Decouple client code from specific implementations
- Reuse existing classes with different interfaces

## Problem and Solution

**Problem:** You have a useful library or class that provides functionality you need, but its interface doesn't match what your application expects. Modifying the library is not possible or practical.

**Solution:** Create an adapter class that implements the interface your application expects while wrapping the incompatible class. The adapter translates calls from the expected interface to the actual interface of the wrapped class.

## Structure

The Adapter pattern involves these participants:

- **Client:** Code that expects a specific interface
- **Target Interface:** The interface the client expects
- **Adapter:** Implements the target interface and wraps the adaptee
- **Adaptee:** The existing class with an incompatible interface

Two main approaches:
1. **Class Adapter:** Uses inheritance (multiple inheritance)
2. **Object Adapter:** Uses composition (preferred in PHP)

## When to Use

Use the Adapter pattern when:

- Working with legacy code or third-party libraries with incompatible interfaces
- You need to reuse existing classes with different expected interfaces
- You want to create a common interface for a group of classes
- Integrating multiple systems with different APIs
- You need to avoid modifying existing code (Open/Closed Principle)

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Structural\Adapter;

// Target interface expected by the client
interface PaymentProcessor {
    public function process(float $amount): bool;
    public function getTransactionId(): string;
}

// Adaptee: Third-party payment gateway with different interface
class LegacyPaymentGateway {
    private string $transactionId = '';

    public function executePayment(float $sum): array {
        $this->transactionId = 'TXN_' . time();
        return [
            'success' => true,
            'transaction' => $this->transactionId,
            'amount' => $sum
        ];
    }

    public function getLastTransaction(): string {
        return $this->transactionId;
    }
}

// Adapter: Wraps the legacy gateway and implements the target interface
class PaymentGatewayAdapter implements PaymentProcessor {
    public function __construct(
        private readonly LegacyPaymentGateway $gateway
    ) {}

    public function process(float $amount): bool {
        $result = $this->gateway->executePayment($amount);
        return $result['success'] ?? false;
    }

    public function getTransactionId(): string {
        return $this->gateway->getLastTransaction();
    }
}

// Client code
$gateway = new LegacyPaymentGateway();
$adapter = new PaymentGatewayAdapter($gateway);

if ($adapter->process(99.99)) {
    echo "Payment processed: {$adapter->getTransactionId()}";
}
```

## Real-World Analogies

- **Power Adapter:** An electrical outlet adapter allows you to plug European plugs into American sockets by translating the physical interface.
- **Language Interpreter:** A translator adapts communication between people speaking different languages.
- **Database Drivers:** Database abstraction layers adapt different database APIs to a common interface.
- **Media Player Codec:** Video players use codecs to adapt different media formats to a playable interface.

## Pros and Cons

**Pros:**
- Single Responsibility Principle: Separates interface conversion from business logic
- Open/Closed Principle: Add new adapters without changing existing code
- Flexibility: Use multiple implementations interchangeably
- Reusability: Leverage existing classes without modification
- Loose Coupling: Client depends on abstraction, not concrete implementations

**Cons:**
- Increased Complexity: Additional classes can make codebase more complex
- Performance Overhead: Extra layer of indirection in method calls
- Over-Engineering: Simple cases don't need adaptation patterns
- Harder Debugging: Stack traces become longer with wrapper layers

## Relations with Other Patterns

- **Decorator:** Similar structure (wrapping), but Decorator adds responsibility while Adapter converts interface
- **Facade:** Simplifies complex subsystems while Adapter makes incompatible interfaces compatible
- **Bridge:** Similar intent of decoupling abstraction from implementation
- **Strategy:** Both encapsulate varying behavior; Adapter often used with Strategy
- **Factory Method:** Can be used with Adapter to create appropriate adapters dynamically

## Additional Considerations

**When Designing Adapters:**
- Keep adapters thin - avoid adding business logic
- Use type hints and strict types for clarity
- Consider using inheritance for minimal adapters
- Document the adapted interface clearly
- Use dependency injection for flexibility

**Common Pitfall:**
Don't use Adapter to patch poor design. If you need adapters everywhere, reconsider your architecture design.

---
name: Strategy Design Pattern
description: Behavioral pattern that defines a family of algorithms, encapsulates each one, and makes them interchangeable. Strategy lets the algorithm vary independently from clients that use it, enabling runtime selection without conditional logic.
---

# Strategy Pattern

## Overview

The Strategy pattern is a behavioral design pattern that defines a family of algorithms, encapsulates each one, and makes them interchangeable. It allows the algorithm to vary independently from clients that use it, enabling runtime algorithm selection without scattered conditionals or hard-coded dependencies.

## Intent

- Define a family of algorithms and encapsulate each one
- Make algorithms interchangeable at runtime
- Eliminate complex conditional logic for selecting behavior
- Allow clients to choose algorithms dynamically
- Decouple algorithm selection from algorithm implementation
- Enable easy addition of new algorithms without modifying existing code

## Problem & Solution

### Problem

Applications often need multiple ways to perform the same task:

1. **Scattered Conditionals**: Code contains multiple if-else blocks choosing different algorithms
2. **Tight Coupling**: Algorithms are hard-coded into classes, making changes difficult
3. **Difficult Maintenance**: Adding new algorithms requires modifying existing code
4. **Code Duplication**: Similar conditional logic scattered throughout the codebase
5. **Testing Complexity**: Hard to test algorithm selection logic independently

### Solution

Extract algorithms into separate, interchangeable classes that implement a common interface. The client uses the interface to delegate algorithm execution, selecting the appropriate strategy at runtime without knowing its implementation details.

## Structure

```
┌─────────────────┐
│     Client      │
└─────────────────┘
        │
        │ uses
        ↓
┌──────────────────────┐       ┌──────────────────┐
│  Strategy (I)        │◄──────│ ConcreteStrategy │
├──────────────────────┤       ├──────────────────┤
│ + execute()          │       │ + execute()      │
└──────────────────────┘       └──────────────────┘
        ▲
        │ implements
        │
    ┌───┴─────┬──────────┐
    │          │          │
    ▼          ▼          ▼
┌─────────┐┌─────────┐┌─────────┐
│Strategy1││Strategy2││Strategy3│
└─────────┘└─────────┘└─────────┘
```

### Key Components

- **Strategy**: Interface defining the algorithm contract
- **ConcreteStrategy**: Implementations of specific algorithms
- **Context**: Uses strategies through the interface, delegates execution

## When to Use

✓ Multiple algorithms for the same task (payment methods, sorting strategies)
✓ Need to switch algorithms at runtime based on conditions
✓ Avoid complex conditional logic for behavior selection
✓ Algorithms change frequently and need easy updates
✓ Want to avoid modifying existing code when adding algorithms
✓ Algorithm logic is independent from client code

## Implementation (PHP 8.3+)

```php
<?php

declare(strict_types=1);

// Strategy Interface
interface PaymentStrategy
{
    public function pay(float $amount): void;
}

// Concrete Strategies
final readonly class CreditCardPayment implements PaymentStrategy
{
    public function __construct(
        private string $cardNumber,
        private string $cardHolder,
        private string $cvv
    ) {}

    public function pay(float $amount): void
    {
        echo "Processing credit card payment of $" . number_format($amount, 2) . "\n";
        echo "Card: {$this->cardNumber} ({$this->cardHolder})\n";
        // Payment processing logic
    }
}

final readonly class PayPalPayment implements PaymentStrategy
{
    public function __construct(
        private string $email
    ) {}

    public function pay(float $amount): void
    {
        echo "Processing PayPal payment of $" . number_format($amount, 2) . "\n";
        echo "Email: {$this->email}\n";
        // PayPal API call
    }
}

final readonly class CryptocurrencyPayment implements PaymentStrategy
{
    public function __construct(
        private string $walletAddress
    ) {}

    public function pay(float $amount): void
    {
        echo "Processing cryptocurrency payment of $" . number_format($amount, 2) . "\n";
        echo "Wallet: {$this->walletAddress}\n";
        // Blockchain transaction
    }
}

// Context Class
final class Order
{
    private PaymentStrategy $paymentStrategy;

    public function __construct(
        private string $orderId,
        private float $totalAmount
    ) {}

    public function setPaymentStrategy(PaymentStrategy $strategy): void
    {
        $this->paymentStrategy = $strategy;
    }

    public function checkout(): void
    {
        if (!isset($this->paymentStrategy)) {
            throw new \RuntimeException('Payment strategy not set');
        }

        echo "Order {$this->orderId} - Amount: $" .
             number_format($this->totalAmount, 2) . "\n";
        $this->paymentStrategy->pay($this->totalAmount);
        echo "Order completed successfully!\n";
    }
}

// Usage Example
$order = new Order('ORD-12345', 99.99);

// Pay with credit card
$order->setPaymentStrategy(
    new CreditCardPayment('4532-1234-5678-9010', 'John Doe', '123')
);
$order->checkout();

// Same order, different strategy
$order->setPaymentStrategy(new PayPalPayment('user@example.com'));
$order->checkout();

// Switch to cryptocurrency
$order->setPaymentStrategy(
    new CryptocurrencyPayment('1A1z7agoat2YLZW51Bc7M7WqXNMrZTU8d9')
);
$order->checkout();
```

### Sorting Strategy Example

```php
<?php

declare(strict_types=1);

interface SortStrategy
{
    /** @param array<int> $data */
    public function sort(array $data): array;
}

final readonly class BubbleSort implements SortStrategy
{
    public function sort(array $data): array
    {
        $n = count($data);
        for ($i = 0; $i < $n - 1; $i++) {
            for ($j = 0; $j < $n - $i - 1; $j++) {
                if ($data[$j] > $data[$j + 1]) {
                    [$data[$j], $data[$j + 1]] = [$data[$j + 1], $data[$j]];
                }
            }
        }
        return $data;
    }
}

final readonly class QuickSort implements SortStrategy
{
    public function sort(array $data): array
    {
        if (count($data) <= 1) {
            return $data;
        }

        $pivot = $data[0];
        $less = [];
        $greater = [];

        foreach (array_slice($data, 1) as $item) {
            if ($item <= $pivot) {
                $less[] = $item;
            } else {
                $greater[] = $item;
            }
        }

        return array_merge(
            $this->sort($less),
            [$pivot],
            $this->sort($greater)
        );
    }
}

final class DataSorter
{
    public function __construct(
        private SortStrategy $strategy
    ) {}

    public function sortData(array $data): array
    {
        return $this->strategy->sort($data);
    }

    public function setStrategy(SortStrategy $strategy): void
    {
        $this->strategy = $strategy;
    }
}

// Usage
$sorter = new DataSorter(new BubbleSort());
echo json_encode($sorter->sortData([5, 2, 8, 1, 9])); // Quick for large datasets
$sorter->setStrategy(new QuickSort());
echo json_encode($sorter->sortData([5, 2, 8, 1, 9]));
```

## Real-World Analogies

**Transportation**: Getting from point A to B can use different strategies (car, bus, train, plane). You choose based on distance, cost, and time—the destination doesn't change, only the method.

**Restaurant**: A restaurant uses different cooking strategies (grilling, frying, baking, steaming). The chef selects the method based on the dish type without changing the restaurant's interface.

**Shipping**: E-commerce uses different shipping strategies (standard, express, overnight). The checkout process remains the same; only the algorithm changes based on customer selection.

**Compression**: A file archiver supports multiple algorithms (ZIP, RAR, 7z). Users select which to use without the archiver needing to know internal details.

## Pros and Cons

### Advantages
✓ Eliminates complex conditional logic (if-else chains)
✓ Easy to add new algorithms without modifying existing code
✓ Runtime algorithm selection without recompilation
✓ Strategies are independently testable
✓ Follows Open/Closed Principle (open for extension, closed for modification)
✓ Encapsulates algorithm families into cohesive classes
✓ Enables algorithm swapping at runtime

### Disadvantages
✗ Increases class count; many strategies create more files to maintain
✗ Overhead for simple algorithms where conditionals suffice
✗ Clients must know strategy details to instantiate correctly
✗ Extra layer of indirection adds complexity
✗ May be premature optimization if algorithm selection rarely changes

## Relations with Other Patterns

- **State**: Similar structure but different intent—State allows object behavior change; Strategy encapsulates behavior selection
- **Template Method**: Defines algorithm skeleton; Strategy defines concrete algorithms
- **Command**: Both encapsulate requests, but Strategy encapsulates algorithms; Command encapsulates operations
- **Factory**: Often combined to create appropriate strategy instances
- **Dependency Injection**: Preferred modern approach to inject strategies
- **Decorator**: Can combine with decorators for algorithm composition
- **Observer**: Strategies can notify observers when execution completes

# Message Chains Code Smell

Message chains appear when client code reaches a value by walking through a series of intermediate objects: `$a->getB()->getC()->getD()`. Each link is an implicit dependency on the internal structure of the previous object. The client must understand the object it holds and also the whole graph of relationships behind it.

This is a coupling problem. The client knows far more about the object structure than it should, and any change to the relationships along the chain ripples out to every caller that navigates the same path.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

1. **Structural coupling**: the client depends on the internal layout of several objects, not just the one it references directly.
2. **Fragile paths**: restructuring any relationship along the chain forces updates in every client that traverses it.
3. **Context-bound code**: chain-dependent code cannot be reused where the object graph is structured differently.
4. **Inflexible design**: swapping implementations or restructuring relationships is hard when clients encode the navigation path.
5. **Obscured dependencies**: the real dependency set is hidden. Inspecting the direct class shows only the first hop.

## Signs and symptoms

- Chains of method calls like `$user->getAccount()->getBank()->getCode()`
- Client code that shows detailed knowledge of the internal structure of several objects
- Object relationship changes cascading into updates across many files
- Tests that must mock entire chains of objects to isolate one behavior
- Code that reads like a navigation instruction rather than a domain operation

## Before and after

### Before: message chain

```php
<?php

declare(strict_types=1);

namespace App\Order;

use App\Customer\Customer;
use App\Bank\BankAccount;

class OrderProcessor
{
    public function processOrder(Order $order): void
    {
        // Message chain - client knows entire structure
        $bankCode = $order->getCustomer()
            ->getAccount()
            ->getBank()
            ->getCode();

        $balance = $order->getCustomer()
            ->getAccount()
            ->getBalance();

        if ($balance > $order->getTotal()) {
            $this->chargeAccount($bankCode, $order->getTotal());
        }
    }

    private function chargeAccount(string $bankCode, float $amount): void
    {
        // charge logic
    }
}

class Order
{
    public function __construct(private Customer $customer) {}

    public function getCustomer(): Customer
    {
        return $this->customer;
    }
}
```

### After: Hide Delegate / encapsulate

```php
<?php

declare(strict_types=1);

namespace App\Order;

use App\Customer\Customer;

class OrderProcessor
{
    public function processOrder(Order $order): void
    {
        // Direct interaction with relevant object
        if ($order->canAfford($order->getTotal())) {
            $order->charge($order->getTotal());
        }
    }
}

class Order
{
    public function __construct(private Customer $customer) {}

    public function canAfford(float $amount): bool
    {
        return $this->customer->getAccountBalance() >= $amount;
    }

    public function charge(float $amount): void
    {
        $this->customer->chargeAccount($amount);
    }
}

class Customer
{
    public function __construct(
        private BankAccount $account,
        private string $name,
    ) {}

    public function getAccountBalance(): float
    {
        return $this->account->getBalance();
    }

    public function chargeAccount(float $amount): void
    {
        $this->account->debit($amount);
    }
}
```

## Recommended refactorings

### 1. Hide Delegate

Create methods on intermediate objects that expose only what clients need, hiding the chain structure.

- **When to use**: you want to keep the overall structure but reduce coupling
- **How**: add methods to intermediate objects that delegate to nested objects
- **Result**: client code depends only on the direct object, not the whole chain

### 2. Move Method / Extract and move

Identify what the client is actually trying to do and move that behavior to an object earlier in the chain.

- **When to use**: the operation logically belongs in an earlier object
- **How**: extract the logic and move it to a more appropriate place in the object graph
- **Result**: simpler client code, with the logic where it semantically belongs

### 3. Introduce Facade / Gateway object

Create a facade that encapsulates access to a complex object structure.

- **When to use**: the object graph is particularly complex, or there are several independent chains
- **How**: create a new object that knows the structure and offers simplified access
- **Result**: knowledge of the structure is centralized in one place

## Exceptions

Message chains are acceptable in these cases:

- **Fluent APIs**: intentional method chaining for building configurations or queries (e.g., query builders)
- **DSLs**: domain-specific languages that use chains for readability
- **Data access chains**: navigating relationships in ORMs (e.g., `$user->profile->settings->theme`) where they represent valid domain relationships
- **Standard library**: built-in methods like `array_map()` chains or stream operations

The difference is that these are *designed* as chains. The coupling is not incidental.

## Related smells

- **Middle Man**: the flip side of Message Chains. Hiding too much behind delegation obscures where functionality lives, so fixing chains too eagerly can create a Middle Man.
- **Feature Envy**: a method reaching deep into another object's structure is often both envious and chain-dependent.
- **Inappropriate Intimacy**: the broader coupling problem, of which Message Chains are one case.
- **Data Clumps**: objects that travel together along chains may signal data that should be grouped into one object.

Do not overcorrect. Hiding every chain behind delegation methods makes it hard to find where real work happens, so balance encapsulation with transparency.

# Message Chains Code Smell

## Overview

Message chains appear when client code reaches a value by walking through a series of intermediate objects: `$a->getB()->getC()->getD()`. Each link in the chain is an implicit dependency on the internal structure of the previous object. The client must understand not just the object it holds, but the entire graph of relationships behind it.

This is a coupling problem. The client knows far more about the object structure than it should, and any change to the relationships between objects in the chain ripples outward to every caller that navigates the same path.

## Why It's a Problem

1. **Structural Coupling**: The client depends on the internal layout of multiple objects, not just the one it directly references
2. **Fragile Paths**: Restructuring any relationship along the chain forces updates in every client that traverses it
3. **Context-Bound Code**: Chain-dependent code cannot be reused in contexts where the object graph is structured differently
4. **Inflexible Design**: Swapping implementations or restructuring object relationships becomes difficult when clients encode the navigation path directly
5. **Obscured Dependencies**: The real dependency set is hidden - inspecting the direct class reveals only the first hop, not the full chain

## Signs and Symptoms

- Chains of method calls like `$user->getAccount()->getBank()->getCode()`
- Client code that demonstrates detailed knowledge of multiple objects' internal structure
- Object relationship changes cascading into updates across many files
- Tests that must mock entire chains of objects to isolate a single behavior
- Code that reads like a navigation instruction rather than a domain operation

## Before/After

### Before: Message Chain

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

### After: Hide Delegate / Encapsulate

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

## Recommended Refactorings

### 1. Hide Delegate

Create methods on intermediate objects that expose only what clients need, hiding the chain structure.

- **When to use**: When you want to preserve the overall structure but reduce coupling
- **How**: Add methods to intermediate objects that delegate to nested objects
- **Result**: Client code depends only on the direct object, not the entire chain

### 2. Move Method / Extract and Move

Identify what the client is actually trying to do and move that behavior to an object earlier in the chain.

- **When to use**: When the operation belongs logically in an earlier object
- **How**: Extract the logic and move it to a more appropriate location in the object graph
- **Result**: Simplifies client code and places logic where it semantically belongs

### 3. Introduce Facade/Gateway Object

Create a facade that encapsulates access to complex object structures.

- **When to use**: When dealing with particularly complex object graphs or multiple independent chains
- **How**: Create a new object that knows about the structure and provides simplified access
- **Result**: Centralizes knowledge of the structure in one place

## Exceptions

Message chains are acceptable in specific scenarios:

- **Fluent APIs**: Intentional method chaining for building configurations or queries (e.g., query builders)
- **DSLs**: Domain-specific languages that use chains for readability
- **Data Access Chains**: Accessing navigational relationships in ORMs (e.g., `$user->profile->settings->theme`) where it represents valid domain relationships
- **Standard Library**: Built-in methods like `array_map()` chains or stream operations

The key difference: these are *designed* as chains, not *incidental* coupling.

## Related Smells

- **Middle Man**: The flip side of Message Chains - hiding too much delegation can obscure where functionality actually lives. Fixing chains aggressively can create Middle Man.
- **Feature Envy**: A method reaching deep into another object's structure is often both envious and chain-dependent
- **Inappropriate Intimacy**: The broader coupling problem of which Message Chains are a specific manifestation
- **Data Clumps**: Objects that travel together along chains may signal data that should be grouped into a single object

Be careful not to overcorrect: hiding every chain behind delegation methods can make it impossible to find where real work happens. The goal is to balance encapsulation with transparency.

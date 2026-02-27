# Message Chains Code Smell

## Overview

Message chains occur when client code accesses a value from an object by traversing a series of intermediate method calls, forming chains like `$a->getB()->getC()->getD()`. Each step in the chain represents a dependency on the internal structure of another object, creating tight coupling and fragile code.

This code smell often indicates that the client has intimate knowledge of the object graph structure, violating the principle of encapsulation. Any change to the relationship between objects in the chain requires updating all client code that depends on that path.

## Why It's a Problem

1. **Tight Coupling**: Client code becomes dependent on the internal structure of multiple objects, not just the immediate object it's calling
2. **Fragility**: Changes to intermediate relationships force updates in many places throughout the codebase
3. **Limited Reusability**: Code using chains is harder to reuse in different contexts where the chain structure differs
4. **Reduced Flexibility**: It's difficult to swap out implementations or restructure the object graph without breaking clients
5. **Hidden Dependencies**: The true dependencies are obscured; they're not immediately obvious from examining the direct class

## Signs and Symptoms

- Long sequences of method calls like `$user->getAccount()->getBank()->getCode()`
- Client code knows the detailed structure of multiple objects
- Changes to object relationships require cascading updates across multiple files
- Difficulty testing; mock objects need to mock the entire chain
- Code reads like a navigation path rather than a business operation

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

- **Middle Man**: The opposite problem—excessive delegation hiding obscures where functionality actually lives
- **Feature Envy**: A related smell where a method uses more features from another object than its own
- **Inappropriate Intimacy**: General coupling issue where classes know too much about each other
- **Data Clumps**: When objects frequently passed together suggest they should be grouped

## Refactoring.guru Guidance

### Signs and Symptoms

In code you see a series of calls resembling `$a->b()->c()->d()`.

### Reasons for the Problem

A message chain occurs when a client requests another object, that object requests yet another one, and so on. These chains mean the client is dependent on navigation along the class structure. Any changes in these relationships require modifying the client.

### Treatment

- **Hide Delegate**: Eliminate the chain by creating delegation methods on intermediate objects so the client only talks to its immediate neighbor.
- **Extract Method** and **Move Method**: Look at what the end object is being used for. Consider extracting that functionality and moving it to the beginning of the chain.

### Payoff

- Reduces dependencies between classes of a chain.
- Reduces the amount of bloated code.

### When to Ignore

Overly aggressive delegate hiding can cause the Middle Man smell, where it becomes unclear where the actual functionality resides. Balance is key.

## Overview

Change Value to Reference is a refactoring technique that converts a value object (created and discarded frequently) into a reference object (managed globally and reused). This is particularly useful when you have multiple copies of the same object that should always reflect the same state. Instead of creating new instances, you maintain a single instance and share references to it.

This refactoring is the inverse of Change Reference to Value and is commonly applied when dealing with entities that represent real-world objects that should have single, canonical representations in memory.

## Motivation

### When to Apply

- **Duplicate objects**: Multiple instances represent the same logical entity (e.g., customer, department)
- **State inconsistency**: Changes to one instance don't reflect in "equivalent" instances
- **Identity matters**: Objects should have identity-based equality rather than value-based equality
- **Memory pressure**: Creating many duplicate objects wastes memory
- **Shared mutable state**: Multiple references need to reflect changes immediately
- **Database records**: Representing rows from a database where identity is crucial

### Why It Matters

Converting to reference objects ensures that your system has a single source of truth for each entity. This eliminates the risk of inconsistent state, simplifies data synchronization, and makes the codebase more maintainable by clarifying that certain objects have identity-based semantics.

## Mechanics: Step-by-Step

1. **Create a registry or factory**: Establish a mechanism to store and retrieve reference objects
2. **Add identity access**: Implement a way to look up objects (usually by ID or unique key)
3. **Replace constructors**: Route object creation through the factory instead of direct instantiation
4. **Implement equality**: Change equality comparison from value-based to reference-based (identity)
5. **Update client code**: Replace value object creation with references from the registry
6. **Remove duplication**: Ensure old value object instances are no longer created
7. **Test consistency**: Verify that all references to the same entity stay in sync

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Customer
{
    public function __construct(
        private int $id,
        private string $name,
        private string $email,
    ) {}

    public function getId(): int
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): void
    {
        $this->name = $name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): void
    {
        $this->email = $email;
    }
}

class Order
{
    public function __construct(
        private int $id,
        private Customer $customer,
        private float $total,
    ) {}

    public function getCustomer(): Customer
    {
        return $this->customer;
    }
}

// Client code: creates multiple instances for the same logical customer
$customer1 = new Customer(1, 'John Doe', 'john@example.com');
$customer2 = new Customer(1, 'John Doe', 'john@example.com');

$order1 = new Order(101, $customer1, 150.00);
$order2 = new Order(102, $customer2, 200.00);

// Modify customer through order1
$order1->getCustomer()->setName('John Smith');
$order1->getCustomer()->setEmail('john.smith@example.com');

// order2's customer still has old values - inconsistent state!
echo $order1->getCustomer()->getName(); // "John Smith"
echo $order2->getCustomer()->getName(); // "John Doe" - INCONSISTENT!
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Customer
{
    private static array $instances = [];

    private function __construct(
        private readonly int $id,
        private string $name,
        private string $email,
    ) {}

    public static function getInstance(int $id, string $name, string $email): self
    {
        if (!isset(self::$instances[$id])) {
            self::$instances[$id] = new self($id, $name, $email);
        }
        return self::$instances[$id];
    }

    public static function getExistingInstance(int $id): ?self
    {
        return self::$instances[$id] ?? null;
    }

    public function getId(): int
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): void
    {
        $this->name = $name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): void
    {
        $this->email = $email;
    }
}

class Order
{
    public function __construct(
        private readonly int $id,
        private Customer $customer,
        private float $total,
    ) {}

    public function getCustomer(): Customer
    {
        return $this->customer;
    }
}

// Client code: retrieves reference objects from factory
$customer1 = Customer::getInstance(1, 'John Doe', 'john@example.com');
$customer2 = Customer::getInstance(1, 'John Doe', 'john@example.com');

// Same instance!
assert($customer1 === $customer2);

$order1 = new Order(101, $customer1, 150.00);
$order2 = new Order(102, $customer2, 200.00);

// Modify customer through order1
$order1->getCustomer()->setName('John Smith');
$order1->getCustomer()->setEmail('john.smith@example.com');

// order2's customer reflects the changes - consistent state!
echo $order1->getCustomer()->getName(); // "John Smith"
echo $order2->getCustomer()->getName(); // "John Smith" - CONSISTENT!
```

## Benefits

- **Data Consistency**: All references to the same entity reflect changes immediately
- **Identity Clarity**: Objects have clear identity semantics rather than value semantics
- **Memory Efficiency**: Eliminates duplicate instances of the same logical entity
- **Simplified Synchronization**: No need to manually propagate state changes across multiple instances
- **Easier Debugging**: Single source of truth makes it easier to track object state
- **Better Database Integration**: Aligns with how databases handle records (one canonical row per ID)
- **Reduced Bugs**: Prevents subtle bugs from inconsistent state across copies

## When NOT to Use

- **Immutable objects**: Value semantics work well for immutable data (strings, numbers)
- **Stateless objects**: Objects that never change don't need reference semantics
- **Lightweight DTOs**: Simple data transfer objects benefit from value semantics
- **Functional programming**: Pure functions with value objects are easier to reason about
- **No shared mutation**: If objects are never modified after creation, reference semantics add unnecessary complexity
- **Serialization concerns**: Reference objects with registries complicate serialization
- **Thread safety critical**: References require synchronization if shared across threads

## Related Refactorings

- **Change Reference to Value**: The inverse refactoring, converting reference objects back to values
- **Extract Class**: Often used alongside to separate concerns into distinct reference objects
- **Replace Data Value with Object**: For converting primitive values into reference objects
- **Introduce Null Object**: For handling missing references gracefully
- **Move Field**: To consolidate related fields into shared reference objects

## Overview

Change Value to Reference transforms a value object - one that is freely created and discarded - into a reference object managed through a central registry or factory. This is appropriate when multiple parts of the system should share a single canonical instance rather than working with independent copies.

The refactoring is the inverse of Change Reference to Value. It applies most naturally to entities that model real-world concepts requiring a single, authoritative representation in memory.

## Motivation

### When to Apply

- **Redundant copies**: Several instances represent the same logical entity (e.g., a customer or account)
- **Inconsistent state**: Updating one copy leaves other copies stale
- **Identity semantics**: The object should be compared by identity, not by field values
- **Memory waste**: Duplicating large or numerous objects consumes memory unnecessarily
- **Shared mutation**: All consumers should see changes immediately when the object is modified
- **Database alignment**: The object maps to a database row where a single record is the source of truth

### Why It Matters

When the same entity is represented by multiple independent instances, changes to one go unnoticed by the others. Converting to reference semantics establishes a single source of truth, guaranteeing that every part of the system operates on the same, current data.

## Mechanics: Step-by-Step

1. **Build a registry or factory**: Create a mechanism that stores and retrieves instances by a unique key
2. **Provide identity-based lookup**: Allow clients to obtain an existing instance by its identifier
3. **Route creation through the factory**: Replace direct constructor calls with factory lookups
4. **Switch to identity equality**: Adjust comparisons from value-based to reference-based
5. **Update all client code**: Ensure every consumer obtains instances from the registry
6. **Eliminate stale copies**: Remove code paths that create duplicate instances
7. **Validate consistency**: Confirm that all references to a given entity stay in sync

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

- **Guaranteed Consistency**: Every consumer works with the same instance, so changes propagate instantly
- **Clear Identity Semantics**: Objects are explicitly identity-based rather than ambiguously value-based
- **Lower Memory Footprint**: One instance per entity instead of many duplicates
- **No Manual Synchronization**: State changes are inherently visible everywhere
- **Easier Debugging**: A single canonical instance is straightforward to inspect and trace
- **Database Compatibility**: Mirrors how relational databases treat rows - one record per identity
- **Fewer State Bugs**: Eliminates a category of bugs caused by stale or divergent copies

## When NOT to Use

- **Immutable data**: Value semantics are a better fit for objects that never change
- **Stateless objects**: Objects without mutable state gain nothing from reference semantics
- **Simple DTOs**: Data transfer objects benefit from being lightweight and disposable
- **Functional style**: Pure functions and value objects are easier to reason about
- **No shared mutation**: If objects are never modified after creation, references add unneeded complexity
- **Serialization needs**: Registry-backed objects complicate serialization and deserialization
- **Concurrency concerns**: Shared mutable references require synchronization in multithreaded environments

## Related Refactorings

- **Change Reference to Value**: The opposite transformation, returning to value semantics
- **Extract Class**: Often paired with this refactoring to separate concerns among reference objects
- **Replace Data Value with Object**: Promotes primitive values into full reference objects
- **Introduce Null Object**: Provides a safe stand-in for missing references
- **Move Field**: Consolidates related data into shared reference objects

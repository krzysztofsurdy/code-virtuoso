## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before (PHP 8.3+)](#before-php-83)
- [After (PHP 8.3+)](#after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Change Value to Reference turns a value object, one that is created and discarded freely, into a reference object managed through a central registry or factory. Use it when several parts of the system should share one canonical instance instead of working with independent copies.

It is the inverse of Change Reference to Value. It fits best for entities that model real-world concepts and need a single authoritative representation in memory.

## Motivation

### When to apply

- **Redundant copies**: Several instances represent the same logical entity (e.g., a customer or account)
- **Inconsistent state**: Updating one copy leaves other copies stale
- **Identity semantics**: The object should be compared by identity, not by field values
- **Memory waste**: Duplicating large or numerous objects uses memory for nothing
- **Shared mutation**: All consumers should see a change as soon as the object is modified
- **Database alignment**: The object maps to a database row where a single record is the source of truth

### Why it matters

When several independent instances represent the same entity, a change to one goes unnoticed by the others. Reference semantics give you a single source of truth, so every part of the system works on the same current data.

## Mechanics

1. **Build a registry or factory**: Create a mechanism that stores and retrieves instances by a unique key
2. **Provide identity-based lookup**: Let clients get an existing instance by its identifier
3. **Route creation through the factory**: Replace direct constructor calls with factory lookups
4. **Switch to identity equality**: Change comparisons from value-based to reference-based
5. **Update all client code**: Make every consumer get instances from the registry
6. **Remove stale copies**: Remove code paths that create duplicate instances
7. **Validate consistency**: Confirm that all references to an entity stay in sync

## Before (PHP 8.3+)

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

## After (PHP 8.3+)

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

- **Consistency**: Every consumer works with the same instance, so changes are visible at once
- **Clear identity semantics**: Objects are identity-based, not ambiguously value-based
- **Lower memory use**: One instance per entity instead of many duplicates
- **No manual synchronization**: State changes are visible everywhere
- **Easier debugging**: A single canonical instance is easy to inspect and trace
- **Database fit**: Mirrors how relational databases treat rows: one record per identity
- **Fewer state bugs**: Removes a category of bugs caused by stale or divergent copies

## When NOT to use

- **Immutable data**: Value semantics suit objects that never change
- **Stateless objects**: Objects without mutable state gain nothing from reference semantics
- **Simple DTOs**: Data transfer objects should stay lightweight and disposable
- **Functional style**: Pure functions and value objects are easier to reason about
- **No shared mutation**: If objects are never modified after creation, references add needless complexity
- **Serialization needs**: Registry-backed objects complicate serialization and deserialization
- **Concurrency**: Shared mutable references need synchronization in multithreaded environments

## Related refactorings

- **Change Reference to Value**: The opposite: returns to value semantics
- **Extract Class**: Often paired with this refactoring to separate concerns among reference objects
- **Replace Data Value with Object**: Turns primitive values into full reference objects
- **Introduce Null Object**: Gives a safe stand-in for missing references
- **Move Field**: Gathers related data into shared reference objects

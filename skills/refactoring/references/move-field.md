## Overview

Move Field is a refactoring technique that relocates a field from one class to another where it is more appropriately used or accessed. This refactoring improves encapsulation, reduces coupling, and ensures data lives in the class with the greatest responsibility for managing it. It's particularly useful when a field is accessed more frequently by another class than its current container.

## Motivation

### When to Apply

- **Feature envy**: A class accesses another class's field frequently
- **Poor encapsulation**: A field belongs logically to another class
- **Reduced cohesion**: A field is tangential to the class's primary responsibility
- **Tight coupling**: Moving a field reduces interdependency between classes
- **Duplicated field access**: Multiple classes access a field through indirect paths
- **Preparation for Extract Class**: Moving fields often precedes extracting a new class

### Why It Matters

Move Field strengthens the principle of encapsulation by ensuring fields reside in the classes responsible for managing them. This reduces coupling between classes, improves code organization, and makes future maintenance and refactoring easier.

## Mechanics: Step-by-Step

1. **Identify the field**: Locate the field that should be moved and analyze its usage patterns
2. **Analyze dependencies**: Check where the field is read and written; verify it's safe to move
3. **Create the field in the target class**: Add the field declaration in the destination class
4. **Update accessors**: Create getter/setter methods in the target class if needed
5. **Redirect the source**: Modify the source class to access the field through the target class reference
6. **Remove the original field**: Delete the field from its original location after ensuring all references are updated
7. **Test thoroughly**: Verify that all functionality remains identical and no references were missed

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Customer
{
    private string $name;
    private string $email;
    private Order $currentOrder;

    public function __construct(string $name, string $email)
    {
        $this->name = $name;
        $this->email = $email;
        $this->currentOrder = new Order();
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function getCurrentOrder(): Order
    {
        return $this->currentOrder;
    }

    public function setCurrentOrder(Order $order): void
    {
        $this->currentOrder = $order;
    }

    public function addItemToOrder(Product $product, int $quantity): void
    {
        $this->currentOrder->addItem($product, $quantity);
    }

    public function getOrderTotal(): float
    {
        return $this->currentOrder->getTotal();
    }

    public function processOrder(): void
    {
        $this->currentOrder->process();
    }
}

class Order
{
    /** @var array<Product> */
    private array $items = [];
    private float $total = 0.0;

    public function addItem(Product $product, int $quantity): void
    {
        $this->items[] = $product;
        $this->total += $product->getPrice() * $quantity;
    }

    public function getTotal(): float
    {
        return $this->total;
    }

    public function process(): void
    {
        // Process order logic
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Customer
{
    private string $name;
    private string $email;
    private ?Order $currentOrder = null;

    public function __construct(string $name, string $email)
    {
        $this->name = $name;
        $this->email = $email;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function createOrder(): Order
    {
        if ($this->currentOrder === null) {
            $this->currentOrder = new Order($this);
        }
        return $this->currentOrder;
    }

    public function getCurrentOrder(): ?Order
    {
        return $this->currentOrder;
    }

    public function processCurrentOrder(): void
    {
        if ($this->currentOrder !== null) {
            $this->currentOrder->process();
        }
    }
}

class Order
{
    private Customer $customer;
    /** @var array<Product> */
    private array $items = [];
    private float $total = 0.0;

    public function __construct(Customer $customer)
    {
        $this->customer = $customer;
    }

    public function getCustomer(): Customer
    {
        return $this->customer;
    }

    public function addItem(Product $product, int $quantity): void
    {
        $this->items[] = $product;
        $this->total += $product->getPrice() * $quantity;
    }

    public function getTotal(): float
    {
        return $this->total;
    }

    public function process(): void
    {
        // Process order logic using $this->customer if needed
    }
}
```

## Benefits

- **Improved Encapsulation**: Fields reside in classes with proper ownership and responsibility
- **Reduced Coupling**: Classes have fewer dependencies on fields they don't directly manage
- **Enhanced Cohesion**: Classes become more focused with stronger relationships between fields and methods
- **Better Clarity**: Code intent improves when data lives where it's used most
- **Simplified Maintenance**: Easier to understand data flow and modify related logic
- **Facilitates Extraction**: Prepares code for Extract Class and other structural refactorings
- **Enables Testing**: Classes become more independent and easier to test in isolation

## When NOT to Use

- **Fields still heavily accessed by source class**: If the source class is the primary user, moving creates unnecessary indirection
- **Field required for source class identity**: Core fields defining the class shouldn't be moved
- **Bidirectional dependencies**: Moving fields creates circular dependencies between classes
- **Performance-sensitive code paths**: Moving fields may add indirection costs (rare in practice)
- **Frequent access pattern changes**: Uncertain data locality makes refactoring risky
- **Legacy code with obscure dependencies**: Unknown field usages make safe moves impossible without comprehensive testing

## Related Refactorings

- **Extract Class**: Often follows Move Field when moving multiple related fields to form a new class
- **Move Method**: Companion refactoring to ensure methods move with their primary data
- **Replace Data Value with Object**: Convert moved fields to objects for better encapsulation
- **Remove Middle Man**: If Move Field creates excessive indirection, remove delegating methods
- **Replace Type Code with Subclasses**: For fields representing discriminators that should move with their types

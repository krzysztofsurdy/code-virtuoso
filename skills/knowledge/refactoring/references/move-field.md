# Move Field

## Overview

Move Field relocates a field from one class to another that has a stronger claim to it. When a different class reads or writes a field more often than the class that holds it, moving the field aligns data ownership with actual usage. This tightens encapsulation, reduces coupling, and makes each class more cohesive.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics: step by step](#mechanics-step-by-step)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

### When to apply

- **Feature Envy**: another class accesses the field more than the owning class does
- **Misplaced data**: the field logically belongs to a different concept in the domain
- **Weak cohesion**: the field has little to do with the owning class's main responsibility
- **Tight coupling**: moving the field would remove a dependency between two classes
- **Duplicated access paths**: several classes reach the field through indirect chains
- **Preparing for Extract Class**: moving fields often comes before extracting a group of related data into a new class

### Why it matters

Placing data in the class that manages it most directly reduces cross-class communication, makes each class easier to understand on its own, and simplifies later refactoring.

## Mechanics: step by step

1. **Analyze usage**: find where the field is read and written across the codebase.
2. **Check safety**: verify that moving the field will not create circular dependencies or break invariants.
3. **Create the field in the target**: add the field declaration to the destination class.
4. **Add accessors if needed**: provide getter and setter methods in the target class.
5. **Redirect the source**: update the source class to access the field through the target.
6. **Delete the original**: remove the field from its original location once all references are updated.
7. **Run the tests**: confirm that behavior is unchanged.

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

- **Stronger encapsulation**: data lives in the class responsible for managing it.
- **Lower coupling**: classes interact less because each manages its own state.
- **Higher cohesion**: fields and the methods that use them live together.
- **Clearer ownership**: intent is easier to read when data sits where it is used most.
- **Easier maintenance**: data flow is simpler to follow.
- **Enables further refactoring**: often a precursor to Extract Class and other structural changes.
- **Independent testing**: classes that own their data need less setup to test.

## When not to use

- **Source class is the main consumer**: if the current class uses the field most, moving it adds needless indirection.
- **Core identity field**: fields that define what the class represents should stay.
- **Circular dependencies**: moving the field would create a bidirectional dependency.
- **Hot path performance**: added indirection can matter in tight loops (rare in practice).
- **Unstable access patterns**: if usage is shifting, wait until the pattern settles.
- **Obscure dependencies**: in legacy code with hidden callers, get a full test suite in place before moving.

## Related refactorings

- **Extract Class**: often follows Move Field when several related fields migrate to a new class.
- **Move Method**: the companion refactoring. Move methods alongside the fields they operate on.
- **Replace Data Value with Object**: promotes a moved primitive field into a richer object.
- **Remove Middle Man**: undo excessive indirection if Move Field creates too many delegation layers.
- **Replace Type Code with Subclasses**: for type-discriminator fields that should move with their associated behavior.

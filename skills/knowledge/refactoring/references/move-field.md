## Overview

Move Field relocates a field from one class to another that has a stronger claim to it. When a field is read or written more often by a different class than the one that currently holds it, moving the field aligns data ownership with actual usage. This tightens encapsulation, reduces coupling, and makes each class more cohesive.

## Motivation

### When to Apply

- **Feature envy**: Another class accesses the field more than the owning class does
- **Misplaced data**: The field logically belongs to a different concept in the domain
- **Weak cohesion**: The field has little to do with the owning class's primary responsibility
- **Tight coupling**: Moving the field would eliminate a dependency between two classes
- **Duplicated access paths**: Multiple classes reach the field through indirect chains
- **Preparing for Extract Class**: Moving fields often precedes extracting a group of related data into a new class

### Why It Matters

Placing data in the class that manages it most directly reduces the need for cross-class communication, makes each class easier to understand in isolation, and simplifies future refactoring.

## Mechanics: Step-by-Step

1. **Analyze usage**: Determine where the field is read and written across the codebase
2. **Check safety**: Verify that moving the field will not create circular dependencies or break invariants
3. **Create the field in the target**: Add the field declaration to the destination class
4. **Add accessors if needed**: Provide getter and setter methods in the target class
5. **Redirect the source**: Update the source class to access the field through the target
6. **Delete the original**: Remove the field from its original location once all references are updated
7. **Run the tests**: Confirm that all behavior is preserved

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

- **Stronger Encapsulation**: Data resides in the class responsible for managing it
- **Lower Coupling**: Classes interact less because each manages its own state
- **Higher Cohesion**: Fields and the methods that use them live together
- **Clearer Ownership**: Code intent improves when data lives where it is used most
- **Easier Maintenance**: Understanding data flow becomes simpler
- **Enables Further Refactoring**: Often a precursor to Extract Class and other structural improvements
- **Independent Testing**: Classes with their own data are easier to test without complex setup

## When NOT to Use

- **Source class is the primary consumer**: If the current class uses the field most, moving it creates unnecessary indirection
- **Core identity field**: Fields that define what the class represents should stay
- **Circular dependencies**: Moving the field would create a bidirectional dependency
- **Hot path performance**: Added indirection can matter in tight loops (rare in practice)
- **Unstable access patterns**: If usage is shifting, wait until the pattern stabilizes before moving
- **Obscure dependencies**: In legacy code with hidden callers, a comprehensive test suite is needed before moving

## Related Refactorings

- **Extract Class**: Often follows Move Field when multiple related fields migrate to a new class
- **Move Method**: The companion refactoring - move methods alongside the fields they operate on
- **Replace Data Value with Object**: Promotes a moved primitive field into a richer object
- **Remove Middle Man**: Undo excessive indirection if Move Field creates too many delegation layers
- **Replace Type Code with Subclasses**: For type-discriminator fields that should move with their associated behavior

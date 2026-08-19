## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions: when data classes are acceptable](#exceptions-when-data-classes-are-acceptable)
- [Related smells](#related-smells)

## Overview

A Data Class is a passive container for data. It exposes fields through getters and setters but has no meaningful behavior. The class cannot act on its own data, so all the logic that works with that data ends up in client code. This misses a chance for encapsulation and often means the class is not fully designed yet.

## Why it's a problem

- **Behavior without a home**: Objects should bundle data with the operations that act on it. A data-only class pushes behavior into every consumer
- **Scattered logic**: Business rules that belong to the data end up spread across client classes
- **Fragile coupling**: Client code becomes tightly bound to the data class's internal structure
- **Duplicated effort**: Several consumers implement the same calculations, validations, or transformations on the same data
- **Costly structural changes**: Changing the data layout means updating every client that touches the fields

## Signs and symptoms

- The class contains only public fields or trivial getter/setter methods
- No operations beyond basic data access exist on the class
- Client code performs calculations, transformations, or validation using the class's fields
- The class only holds data temporarily between other operations
- Methods on the class do not use the object's own state

## Before and after

### Before: Data Class anti-pattern

```php
<?php
declare(strict_types=1);

class OrderItem
{
    public function __construct(
        public string $productName,
        public float $price,
        public int $quantity,
        public float $discount = 0.0,
    ) {}

    public function getProductName(): string
    {
        return $this->productName;
    }

    public function getPrice(): float
    {
        return $this->price;
    }

    public function getQuantity(): int
    {
        return $this->quantity;
    }

    public function getDiscount(): float
    {
        return $this->discount;
    }

    public function setDiscount(float $discount): void
    {
        $this->discount = $discount;
    }
}

// Client code handles all logic
$item = new OrderItem('Widget', 29.99, 2, 5.0);
$subtotal = $item->getPrice() * $item->getQuantity();
$discountAmount = $subtotal * ($item->getDiscount() / 100);
$total = $subtotal - $discountAmount;
```

### After: object with behavior

```php
<?php
declare(strict_types=1);

readonly class OrderItem
{
    public function __construct(
        private string $productName,
        private float $price,
        private int $quantity,
        private float $discountPercentage = 0.0,
    ) {
        if ($this->price < 0 || $this->quantity < 0 || $this->discountPercentage < 0) {
            throw new InvalidArgumentException('Invalid order item values');
        }
    }

    public function getProductName(): string
    {
        return $this->productName;
    }

    public function calculateSubtotal(): float
    {
        return $this->price * $this->quantity;
    }

    public function calculateDiscountAmount(): float
    {
        return $this->calculateSubtotal() * ($this->discountPercentage / 100);
    }

    public function calculateTotal(): float
    {
        return $this->calculateSubtotal() - $this->calculateDiscountAmount();
    }

    public function applyBulkDiscount(float $percentage): self
    {
        return new self(
            $this->productName,
            $this->price,
            $this->quantity,
            $this->discountPercentage + $percentage,
        );
    }
}

// Client code is simpler and more intuitive
$item = new OrderItem('Widget', 29.99, 2, 5.0);
$total = $item->calculateTotal();
$discountedItem = $item->applyBulkDiscount(10.0);
```

## Recommended refactorings

### 1. **Move Method** - Move logic into the data class
Move methods that operate on the class's data into the class itself. This raises cohesion and lowers coupling.

### 2. **Encapsulate Field** - Hide public data
Make fields private and give access through methods that validate or transform data.

### 3. **Extract Method** - Find reusable operations
When client code repeatedly performs the same calculation on the data, extract it into a method on the class.

### 4. **Value Object** - Make it immutable
Convert data classes to immutable value objects with PHP 8.1+ readonly properties. Their state can no longer change unexpectedly.

### 5. **Remove Setting Method** - Prefer immutability
Once you know an object's responsibilities, remove its setter methods. Create new instances with constructors or factory methods instead.

### 6. **Encapsulate Collection** - Hide collection details
If the class holds arrays, provide domain-specific collection methods instead of exposing the raw structure.

## Exceptions: when data classes are acceptable

Data classes are sometimes appropriate:

- **Data Transfer Objects (DTOs)**: DTOs that carry data across system boundaries (API responses, form submissions) are legitimate
- **Value Objects**: Immutable objects representing a specific value (Money, Point, Date range) look minimal on purpose
- **Configuration objects**: Simple configuration containers with no behavior
- **Database entities**: Entity classes in mapping frameworks where the ORM handles the mapping
- **Temporary structures**: Classes created only to collect and pass related data to one function

The difference is intent. A DTO has a clear purpose. An accidental data class is one that never got its behavior.

## Related smells

- **Anemic Domain Model**: The architectural-scale version of this problem, where all domain objects are data-only and behavior lives entirely in service layers
- **Middle Man**: Too much delegation through wrapper classes, which may themselves look like data classes
- **Feature Envy**: Methods that pull data from a data class to perform logic that belongs inside that class
- **Primitive Obsession**: Using raw primitives instead of small domain objects. Data classes often consist entirely of primitives
- **Inappropriate Intimacy**: Client classes that depend on a data class's internal structure

---

**Key takeaway**: A new class with only fields is normal. It becomes a smell when it stays that way. Objects combine data with the operations that act on it. When client code calculates, validates, or transforms using a class's fields, that logic belongs in the class. Moving it there centralizes the behavior and removes duplication across clients.

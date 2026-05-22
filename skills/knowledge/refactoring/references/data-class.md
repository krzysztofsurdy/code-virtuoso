## Overview

A Data Class is a class that exists solely as a passive container for data - it exposes fields through getters and setters but contains no meaningful behavior. The class cannot act on its own data; instead, all the logic that operates on that data is pushed out into client code. This is a missed opportunity for encapsulation, and it often signals that the class has not yet been fully designed.

## Why It's a Problem

- **Behavior Without a Home**: Objects should bundle data with the operations that act on it; a data-only class pushes behavior into every consumer
- **Logic Scattering**: Business rules that belong to the data end up dispersed across multiple client classes
- **Fragile Coupling**: Client code becomes tightly bound to the data class's internal structure
- **Duplicated Effort**: Multiple consumers independently implement the same calculations, validations, or transformations on the same data
- **Costly Structural Changes**: Modifying the data layout requires updating every client that directly manipulates the fields

## Signs and Symptoms

- The class contains only public fields or trivial getter/setter methods
- No operations beyond basic data access exist on the class
- Client code performs calculations, transformations, or validation using the class's fields
- The class serves no purpose beyond temporarily holding data between other operations
- Methods on the class do not meaningfully interact with the object's own state

## Before/After Examples

### Before: Data Class Anti-Pattern

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

### After: Proper Object with Behavior

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

## Recommended Refactorings

### 1. **Move Method** - Transfer Logic to the Data Class
Move methods that operate on the class's data into the class itself. This increases cohesion and reduces coupling.

### 2. **Encapsulate Field** - Hide Public Data
Make fields private and provide controlled access through methods that validate or transform data.

### 3. **Extract Method** - Identify Reusable Operations
When client code repeatedly performs the same calculation on the data, extract it into a dedicated method within the class.

### 4. **Value Object Pattern** - Make Immutable
Convert data classes to immutable value objects using PHP 8.1+ readonly properties. This improves safety and predictability.

### 5. **Remove Setter Methods** - Prefer Immutability
Once you identify an object's responsibilities, eliminate setter methods. Use constructors or factory methods to create new instances instead.

### 6. **Encapsulate Collections** - Hide Collection Details
If the class holds arrays, provide domain-specific collection methods instead of exposing the raw structure.

## Exceptions: When Data Classes Are Acceptable

Data classes are occasionally appropriate in these contexts:

- **Data Transfer Objects (DTOs)**: When explicitly used for transferring data between system boundaries (API responses, form submissions), DTOs are legitimate
- **Value Objects**: Immutable objects representing a specific value (Money, Point, Date range) may appear minimal but are intentionally limited
- **Configuration Objects**: Simple configuration containers with no behavior requirements
- **Database Entities**: Entity classes in mapping frameworks where ORM handles the mapping
- **Temporary Structures**: Classes created solely to collect and pass related data to a specific function

The key distinction: intentional DTOs with clear purpose differ from accidental data classes that missed their refactoring opportunity.

## Related Smells

- **Anemic Domain Model**: The architectural-scale version of this problem, where all domain objects are data-only and behavior lives entirely in service layers
- **Middle Man**: Excessive delegation through wrapper classes, which may themselves be data-class-like
- **Feature Envy**: Methods that pull data from a data class to perform logic that belongs inside that class
- **Primitive Obsession**: Using raw primitives instead of small domain objects - data classes often consist entirely of primitives
- **Inappropriate Intimacy**: Client classes that rely heavily on a data class's internal structure

---

**Key Takeaway**: A newly created class with only fields is normal - it becomes a smell when it stays that way. The power of objects lies in combining data with the operations that act on it. When client code performs calculations, validations, or transformations using a class's fields, that logic belongs inside the class itself. Moving it there centralizes the behavior, eliminates duplication across clients, and makes the class a genuine participant in the system rather than an inert container.

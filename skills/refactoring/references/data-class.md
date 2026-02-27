## Overview

A Data Class is a code smell where a class serves primarily as a passive container for data with only getters and setters, lacking meaningful behavior or responsibility. These classes function as data transfer objects but miss opportunities to encapsulate logic that operates on that data. The class cannot perform independent actions with its own data.

## Why It's a Problem

- **Violated OOP Principles**: Objects should contain both data and behavior that operates on that data
- **Scattered Logic**: Business logic ends up scattered across client classes instead of residing in cohesive objects
- **Poor Cohesion**: Classes become fragile and disconnected from the operations they support
- **Duplicated Code**: Multiple clients may implement similar logic to process the same data structure
- **Harder Maintenance**: Changes to data structure or behavior require updates across multiple classes

## Signs and Symptoms

- Class contains only public fields or simple getter/setter methods
- No business methods or meaningful operations beyond data access
- Client code performs calculations, transformations, or validations using the class's data
- Class has no reason to exist beyond holding data temporarily
- Methods are trivial and don't interact with the object's state

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

- **Anemic Domain Model**: The larger architectural pattern where all behavior lives outside domain objects
- **Middle Man**: Excessive delegation of method calls through wrapper classes
- **Feature Envy**: When a method uses more of another object's fields than its own
- **Primitive Obsession**: Using primitives instead of small domain objects to represent concepts
- **Inappropriate Intimacy**: Classes that rely too heavily on internals of other classes (often paired with data classes)

---

**Key Takeaway**: Classes should encapsulate both data and the behavior that operates on that data. If your class exists only to hold data while client code performs the work, move that work into the class where it belongs.

## Refactoring.guru Guidance

### Signs and Symptoms

A class contains only fields and crude methods for accessing them (getters and setters). It is simply a container for data used by other classes and cannot independently operate on the data it owns.

### Reasons for the Problem

It is normal when a newly created class contains only a few public fields. But the true power of objects is that they can contain behavior or operations on their data.

### Treatment

- **Encapsulate Field**: Make public fields private and provide controlled access through getters and setters.
- **Encapsulate Collection**: Apply similar protection to collection data.
- **Move Method** and **Extract Method**: Find operations in client code that logically belong in the data class and migrate them there.
- **Remove Setting Method** and **Hide Method**: Once the class gains meaningful behavior, restrict overly permissive access to its internals.

### Payoff

- Improves understanding and organization of code by centralizing operations on related data.
- Helps discover duplication of client code that operates on the same data.

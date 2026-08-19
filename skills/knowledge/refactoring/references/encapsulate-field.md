## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Encapsulate Field replaces direct access to a public class field with getter and setter methods. This separates the internal representation from the external contract. You can then add validation, change how data is stored, or add computed properties without affecting calling code.

## Motivation

**Why wrap fields in accessor methods:**

1. **Guard external access**: Prevent callers from assigning invalid or inconsistent values
2. **Hide storage details**: How data is stored becomes an internal decision
3. **Enforce constraints**: Setter methods can reject values that violate business rules
4. **Support change**: Swap a stored field for a computed property without breaking clients
5. **Clean boundaries**: Public methods form a stable contract; private fields can change freely
6. **Allow side effects**: Add logging, caching, or event notifications later without a signature change
7. **Stronger typing**: Method signatures state types more explicitly than raw field access

## Mechanics

1. Locate public or protected fields that external code reads or writes
2. Create a getter method that returns the field value
3. Create a setter method that assigns the value (with optional validation)
4. Find every external read and replace it with a getter call
5. Find every external write and replace it with a setter call
6. Change the field visibility to private
7. Add validation or constraints inside the setter

## Before and after (PHP 8.3+)

### Before: public field access

```php
<?php

declare(strict_types=1);

class Product
{
    public string $name;
    public float $price;
    public int $stock;

    public function __construct(string $name, float $price, int $stock)
    {
        $this->name = $name;
        $this->price = $price;
        $this->stock = $stock;
    }
}

// Client code accessing fields directly
$product = new Product('Laptop', 999.99, 10);
$product->price = -50; // Invalid: negative price allowed!
$product->stock = -5; // Invalid: negative stock allowed!
$product->name = ''; // Invalid: empty name allowed!

// Reading fields directly
echo "Product: " . $product->name;
echo "Price: " . $product->price;
echo "Stock: " . $product->stock;

// Risky modifications
$product->price *= 0.5; // Direct manipulation
```

### After: encapsulated access

```php
<?php

declare(strict_types=1);

class Product
{
    private string $name;
    private float $price;
    private int $stock;

    public function __construct(string $name, float $price, int $stock)
    {
        $this->setName($name);
        $this->setPrice($price);
        $this->setStock($stock);
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): void
    {
        if (empty(trim($name))) {
            throw new InvalidArgumentException('Product name cannot be empty');
        }
        $this->name = $name;
    }

    public function getPrice(): float
    {
        return $this->price;
    }

    public function setPrice(float $price): void
    {
        if ($price < 0) {
            throw new InvalidArgumentException('Price cannot be negative');
        }
        $this->price = $price;
    }

    public function getStock(): int
    {
        return $this->stock;
    }

    public function setStock(int $stock): void
    {
        if ($stock < 0) {
            throw new InvalidArgumentException('Stock cannot be negative');
        }
        $this->stock = $stock;
    }

    public function applyDiscount(float $percentage): void
    {
        if ($percentage < 0 || $percentage > 100) {
            throw new InvalidArgumentException('Discount must be 0-100%');
        }
        // Setter ensures validation
        $this->setPrice($this->price * (1 - $percentage / 100));
    }
}

// Client code using methods
$product = new Product('Laptop', 999.99, 10);
$product->setPrice(-50); // InvalidArgumentException thrown!
$product->setStock(-5); // InvalidArgumentException thrown!
$product->setName(''); // InvalidArgumentException thrown!

// Reading through getters
echo "Product: " . $product->getName();
echo "Price: " . $product->getPrice();
echo "Stock: " . $product->getStock();

// Safe modifications through methods
$product->applyDiscount(10); // Controlled, validated change
```

## Benefits

- **Input validation**: Setters reject values that break business rules
- **Hidden internals**: Callers interact with a stable method-based contract
- **Painless migration**: Switch from a stored field to a derived computation without touching clients
- **Computed properties**: A getter can calculate its return value on demand
- **Observable state changes**: Setters can trigger logging, events, or cache invalidation
- **Strict types**: Method signatures give callers and IDEs precise type information
- **Self-documenting**: Method names and signatures show what the class offers
- **Room to grow**: New behavior can be added to accessors without changing the public contract

## When NOT to use

- **Immutable value objects**: Final readonly classes may not need setters at all
- **Simple DTOs in private layers**: Internal data carriers with no validation needs gain little
- **Internal utility classes**: Private helpers with no outside consumers
- **Already encapsulated**: If callers already go through methods, the work is done
- **Minimal payoff**: Wrapping a field that will never need validation or change adds ceremony for little gain

## Related refactorings

- **Self Encapsulate Field**: Applies the same idea to access inside the class itself
- **Hide Delegate**: Wraps another object's fields behind the delegating class
- **Replace Data Value with Object**: Turns a primitive field into a dedicated class
- **Extract Class**: Moves related fields into their own class
- **Introduce Parameter Object**: Groups related fields into one parameter object
- **Remove Setting Method**: Makes fields read-only by dropping the setter

## Examples in other languages

### Java

**Before:**
```java
class Person {
  public String name;
}
```

**After:**
```java
class Person {
  private String name;

  public String getName() {
    return name;
  }
  public void setName(String arg) {
    name = arg;
  }
}
```

### C#

**Before:**
```csharp
class Person
{
  public string name;
}
```

**After:**
```csharp
class Person
{
  private string name;

  public string Name
  {
    get { return name; }
    set { name = value; }
  }
}
```

### TypeScript

**Before:**
```typescript
class Person {
  name: string;
}
```

**After:**
```typescript
class Person {
  private _name: string;

  get name() {
    return this._name;
  }
  setName(arg: string): void {
    this._name = arg;
  }
}
```

## Overview

Encapsulate Field is a fundamental refactoring that replaces direct access to a class's public fields with getter and setter methods. Unlike Self Encapsulate Field which applies to internal class usage, this refactoring focuses on controlling external access by forcing clients to interact with fields through methods rather than direct property access.

This creates a boundary between the internal state representation and the external interface, enabling you to change how data is stored without affecting code that uses the class.

## Motivation

**Why encapsulate fields for external access:**

1. **Control External Access**: Prevent unauthorized or invalid modifications from client code
2. **Hide Implementation Details**: Storage mechanism becomes an internal concern
3. **Add Validation**: Enforce constraints and business rules at the boundary
4. **Enable Change**: Switch from fields to computed properties without breaking clients
5. **Observable Boundaries**: Clear separation between public interface and private state
6. **Future Flexibility**: Add side effects, caching, or notifications later
7. **Type Safety**: Enforce type constraints through method signatures

## Mechanics

The refactoring process involves:

1. Identify public or protected fields accessed by external code
2. Create a public getter method that returns the field's current value
3. Create a public setter method that assigns a new value to the field
4. Find all external accesses to the field (in client code)
5. Replace direct field reads with getter method calls
6. Replace direct field writes with setter method calls
7. Make the field private
8. Add validation and constraints to setter methods

## Before/After PHP 8.3+ Code

### Before: Public Field Access

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

### After: Encapsulated Access

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

- **Validation**: Enforce business rules and constraints in setter methods
- **Encapsulation**: Hide implementation details from client code
- **Change Control**: Switch storage mechanism without affecting clients
- **Computed Properties**: Replace simple fields with derived calculations
- **Observable Changes**: Add logging, notifications, or triggers when state changes
- **Type Enforcement**: Strict typing through method signatures
- **Documentation**: Method names and docblocks clarify intent
- **Flexibility**: Add side effects or lazy evaluation without breaking contracts

## When NOT to Use

- **Value Objects**: Immutable, final objects might not benefit
- **DTOs**: Simple data containers in private layers may not need encapsulation
- **Internal Helpers**: Private utility classes accessed only internally
- **Performance-Critical Hot Paths**: Though modern PHP optimizes method calls well
- **Already Encapsulated**: If clients already use methods exclusively
- **Frequent Direct Access**: If changing numerous access points is costly and low-value

## Related Refactorings

- **Self Encapsulate Field**: Encapsulate fields accessed internally within a class
- **Hide Delegate**: Encapsulate another object's fields within a wrapper
- **Replace Data Value with Object**: Convert primitive field to a dedicated class
- **Extract Class**: Move related fields into a separate class
- **Introduce Parameter Object**: Group related fields into a parameter object
- **Remove Setter**: Make fields read-only by removing setter methods

## Examples in Other Languages

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

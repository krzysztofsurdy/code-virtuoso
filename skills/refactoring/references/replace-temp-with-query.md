## Overview

Replace Temp with Query is a refactoring technique that replaces temporary variables holding intermediate calculation results with method calls. This extracts the calculation logic into a separate method, making the code more readable, reusable, and easier to maintain.

Instead of storing a computed value in a temporary variable, you create a method that performs the calculation and call that method whenever you need the value.

## Motivation

Temporary variables create several problems:

- **Limited Scope**: Variables are visible only within the current method, making logic hard to reuse
- **Cognitive Load**: Each temporary variable adds complexity to understanding the method
- **Duplication**: The same calculation might be repeated elsewhere in the codebase
- **Testing Difficulty**: Logic trapped in local variables cannot be unit tested independently
- **Code Smell**: Methods that are too long often indicate the need to extract logic into separate methods

By replacing temporaries with method calls, you gain:

- **Better Separation of Concerns**: Each method has a single responsibility
- **Easier Testing**: Extracted methods can be tested in isolation
- **Code Reuse**: The extracted method can be called from multiple locations
- **Improved Readability**: The code becomes self-documenting through method names

## Mechanics

1. **Identify the temporary variable** holding a calculated value
2. **Create a new method** that returns this calculated value
3. **Move the calculation logic** into the new method
4. **Replace all references** to the temporary variable with calls to the new method
5. **Remove the temporary variable declaration**
6. **Consider making the method private** if it's only used within the class

## Before/After PHP 8.3+ Code Examples

### Before: Using Temporary Variables

```php
<?php

class Order
{
    private float $quantity;
    private float $itemPrice;
    private float $basePrice;

    public function __construct(float $quantity, float $itemPrice, float $basePrice)
    {
        $this->quantity = $quantity;
        $this->itemPrice = $itemPrice;
        $this->basePrice = $basePrice;
    }

    public function getPrice(): float
    {
        // Temporary variable for base price calculation
        $basePrice = $this->quantity * $this->itemPrice;

        // Temporary variable for discount
        $discountFactor = $this->getDiscountFactor($basePrice);

        // Use of temporary variables
        return $basePrice - ($basePrice * $discountFactor);
    }

    private function getDiscountFactor(float $price): float
    {
        if ($price > 1000) {
            return 0.15;
        } elseif ($price > 500) {
            return 0.10;
        }
        return 0.05;
    }
}

// Client code
$order = new Order(quantity: 100, itemPrice: 15.0, basePrice: 0);
$totalPrice = $order->getPrice();
```

### After: Using Query Methods

```php
<?php

class Order
{
    private float $quantity;
    private float $itemPrice;
    private float $basePrice;

    public function __construct(float $quantity, float $itemPrice, float $basePrice)
    {
        $this->quantity = $quantity;
        $this->itemPrice = $itemPrice;
        $this->basePrice = $basePrice;
    }

    public function getPrice(): float
    {
        // Direct method calls instead of temporary variables
        return $this->getBasePrice() - $this->getDiscount();
    }

    private function getBasePrice(): float
    {
        return $this->quantity * $this->itemPrice;
    }

    private function getDiscount(): float
    {
        return $this->getBasePrice() * $this->getDiscountFactor();
    }

    private function getDiscountFactor(): float
    {
        return match (true) {
            $this->getBasePrice() > 1000 => 0.15,
            $this->getBasePrice() > 500 => 0.10,
            default => 0.05,
        };
    }
}

// Client code
$order = new Order(quantity: 100, itemPrice: 15.0, basePrice: 0);
$totalPrice = $order->getPrice();
```

### Complex Example with Multiple Temporaries

**Before:**
```php
<?php

class Invoice
{
    private array $items = [];

    public function getTotalWithTax(): float
    {
        $subtotal = 0;

        foreach ($this->items as $item) {
            $subtotal += $item['price'] * $item['quantity'];
        }

        $taxRate = $this->calculateTaxRate();
        $tax = $subtotal * $taxRate;

        return $subtotal + $tax;
    }

    private function calculateTaxRate(): float
    {
        // Tax calculation logic
        return 0.19;
    }
}
```

**After:**
```php
<?php

class Invoice
{
    private array $items = [];

    public function getTotalWithTax(): float
    {
        return $this->getSubtotal() + $this->getTax();
    }

    private function getSubtotal(): float
    {
        return array_reduce(
            $this->items,
            fn ($carry, $item) => $carry + ($item['price'] * $item['quantity']),
            0
        );
    }

    private function getTax(): float
    {
        return $this->getSubtotal() * $this->getTaxRate();
    }

    private function getTaxRate(): float
    {
        return 0.19;
    }
}
```

## Benefits

- **Improved Readability**: Method names act as documentation, making intent clearer
- **Enhanced Maintainability**: Changes to the calculation logic only need to be made in one place
- **Better Testability**: Extracted methods can be unit tested independently
- **Code Reuse**: Other methods in the class can call the same query methods
- **Reduced Method Length**: Shorter methods are easier to understand and less prone to bugs
- **Single Responsibility**: Each method focuses on a specific concern
- **Easier Refactoring**: Enables further refactoring opportunities like Extract Class or Move Method

## When NOT to Use

- **Performance Critical Code**: Multiple method calls might have measurable overhead compared to temporary variables (consider caching/memoization instead)
- **Simple One-Time Calculations**: For very simple, single-use expressions, temporary variables might be more efficient
- **Loop-Heavy Code**: In tight loops, the overhead of method calls might impact performance
- **Complex Conditionals**: Sometimes a temporary variable makes complex conditional logic clearer than multiple method calls

In such cases, consider caching/memoization or keeping the temporary variable but extracting the method anyway for clarity.

## Related Refactorings

- **Extract Method**: The complementary technique used to create the query methods
- **Introduce Parameter Object**: When multiple temporaries exist, consider grouping them into an object
- **Introduce Variable**: Use temporary variables to simplify complex expressions before extracting methods
- **Cache Query Result**: If performance is critical, cache the result of expensive query methods
- **Remove Middle Man**: Avoid over-extracting query methods that simply delegate to other methods

## Examples in Other Languages

### Java

**Before:**
```java
double calculateTotal() {
  double basePrice = quantity * itemPrice;
  if (basePrice > 1000) {
    return basePrice * 0.95;
  }
  else {
    return basePrice * 0.98;
  }
}
```

**After:**
```java
double calculateTotal() {
  if (basePrice() > 1000) {
    return basePrice() * 0.95;
  }
  else {
    return basePrice() * 0.98;
  }
}
double basePrice() {
  return quantity * itemPrice;
}
```

### C#

**Before:**
```csharp
double CalculateTotal()
{
  double basePrice = quantity * itemPrice;

  if (basePrice > 1000)
  {
    return basePrice * 0.95;
  }
  else
  {
    return basePrice * 0.98;
  }
}
```

**After:**
```csharp
double CalculateTotal()
{
  if (BasePrice() > 1000)
  {
    return BasePrice() * 0.95;
  }
  else
  {
    return BasePrice() * 0.98;
  }
}
double BasePrice()
{
  return quantity * itemPrice;
}
```

### Python

**Before:**
```python
def calculateTotal():
    basePrice = quantity * itemPrice
    if basePrice > 1000:
        return basePrice * 0.95
    else:
        return basePrice * 0.98
```

**After:**
```python
def calculateTotal():
    if basePrice() > 1000:
        return basePrice() * 0.95
    else:
        return basePrice() * 0.98

def basePrice():
    return quantity * itemPrice
```

### TypeScript

**Before:**
```typescript
calculateTotal(): number {
  let basePrice = quantity * itemPrice;
  if (basePrice > 1000) {
    return basePrice * 0.95;
  }
  else {
    return basePrice * 0.98;
  }
}
```

**After:**
```typescript
calculateTotal(): number {
  if (basePrice() > 1000) {
    return basePrice() * 0.95;
  }
  else {
    return basePrice() * 0.98;
  }
}
basePrice(): number {
  return quantity * itemPrice;
}
```

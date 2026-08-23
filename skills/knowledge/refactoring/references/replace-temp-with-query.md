## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After PHP 8.3+ code examples](#beforeafter-php-83-code-examples)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Temp with Query swaps temporary variables that hold intermediate results for method calls that compute the same values on demand. The calculation moves into its own method, and every place that read the variable now calls that method.

Instead of storing a computed value in a local variable, you define a method that produces it and call that method wherever the value is needed.

## Motivation

Temporary variables cause several problems:

- **Trapped scope**: A variable is visible only in the method that declares it, so other methods cannot reuse it
- **Cognitive weight**: Each temp is one more thing the reader must track
- **Repeated logic**: The same calculation may be duplicated in other methods
- **Untestable logic**: A calculation buried in a local variable cannot be unit tested on its own
- **Long methods**: A method full of temporaries often has logic that should be extracted

Replacing temps with query methods gives you:

- **Separation of concerns**: Each method encapsulates one computation
- **Independent testing**: Extracted methods can be tested in isolation
- **Reuse**: Other methods in the class can call the same query
- **Self-documenting code**: Method names describe what is being calculated

## Mechanics

1. **Find the temporary variable** that stores a calculated result
2. **Create a method** that returns the same result
3. **Move the calculation** into the new method body
4. **Replace all reads** of the temporary variable with calls to the new method
5. **Delete the variable declaration**
6. **Make the method private** if it is only needed inside the class

## Before/After PHP 8.3+ code examples

### Before: temporary variables

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

### After: query methods

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

### Complex example with multiple temporaries

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

- **Readable intent**: Method names document the purpose of each computation
- **Centralized changes**: Changing a calculation means editing one method
- **Isolated testing**: Query methods can be unit tested on their own
- **Cross-method reuse**: Other methods in the class can call the same queries
- **Shorter methods**: Moving calculations out makes the host method shorter
- **Focused responsibility**: Each method handles one concern
- **Prepares further refactoring**: Makes Extract Class or Move Method easier later

## When NOT to use

- **Performance-sensitive code**: Repeated method calls may be measurably slower than a cached local variable (memoization is a compromise)
- **Trivial single-use expressions**: For a very simple, one-off calculation, a temp is plainer
- **Tight loops**: Method call overhead adds up in hot loops
- **Complex conditionals**: A well-named temporary variable can make a multi-clause conditional easier to follow than nested method calls

In these cases you can keep the temp and still extract the method for clarity, or add memoization to avoid repeated computation.

## Related Refactorings

- **Extract Method**: The complementary technique that creates the query method itself
- **Introduce Parameter Object**: When there are many temporaries, bundling them into a value object may fit better
- **Introduce Variable**: Use a descriptive temp to simplify a complex expression before deciding whether to extract a method
- **Cache Query Result**: Memoize the result of expensive query methods to preserve performance
- **Remove Middle Man**: Avoid extracting queries that only delegate to another method

## Examples in other languages

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

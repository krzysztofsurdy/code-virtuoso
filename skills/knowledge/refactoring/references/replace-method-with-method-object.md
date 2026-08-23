## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples](#beforeafter-examples)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Method with Method Object moves a complex method into its own class. The method's logic becomes the main operation of the new object, its parameters become constructor arguments, and its local variables become instance fields. It helps most when a method has grown hard to handle because of many parameters, tangled logic, or local variables that depend on each other.

## Motivation

### Problem
- **Unwieldy methods**: A method with many parameters and local variables is hard to follow
- **Low reusability**: Logic locked inside one class cannot be reused or tested on its own
- **Hard to decompose**: Splitting the method into smaller pieces in the same class is awkward
- **Testing friction**: Exercising specific branches of complex logic means building the whole host class
- **Long signatures**: A long parameter list is hard to call and maintain

### Solution
Introduce a new class where:
- The method becomes a public operation (typically `__invoke()` or `execute()`)
- Parameters arrive through the constructor
- Local variables become instance properties
- The original logic moves into the class

## Mechanics

1. Create a new class with a descriptive name (for example, `CalculateOrderTotal` or `GenerateReport`)
2. Accept all method parameters through the constructor
3. Turn local variables into instance properties
4. Move the method body into a `__invoke()` or `execute()` method
5. Replace the original method with code that creates the new class and invokes it
6. Run the full test suite to confirm identical behavior
7. Split the new class into private helper methods where that helps

## Before/After Examples

### Before: complex method with multiple parameters

```php
class OrderProcessor
{
    public function calculateTotal(
        Order $order,
        Customer $customer,
        string $couponCode = null
    ): float {
        $subtotal = 0;

        foreach ($order->getItems() as $item) {
            $subtotal += $item->getPrice() * $item->getQuantity();
        }

        $taxRate = $customer->getLocation() === 'US' ? 0.08 : 0;
        $tax = $subtotal * $taxRate;

        $discount = 0;
        if ($couponCode) {
            $coupon = new CouponService()->findByCode($couponCode);
            if ($coupon && $coupon->isValid()) {
                $discount = $coupon->getPercentage() * $subtotal / 100;
            }
        }

        $shipping = $subtotal > 100 ? 0 : 15;

        return $subtotal + $tax - $discount + $shipping;
    }
}
```

### After: method object

```php
// New dedicated class
class CalculateOrderTotal
{
    private float $subtotal = 0;
    private float $tax = 0;
    private float $discount = 0;
    private float $shipping = 0;

    public function __construct(
        private Order $order,
        private Customer $customer,
        private ?string $couponCode = null
    ) {}

    public function __invoke(): float
    {
        $this->calculateSubtotal();
        $this->calculateTax();
        $this->applyDiscount();
        $this->calculateShipping();

        return $this->subtotal + $this->tax - $this->discount + $this->shipping;
    }

    private function calculateSubtotal(): void
    {
        foreach ($this->order->getItems() as $item) {
            $this->subtotal += $item->getPrice() * $item->getQuantity();
        }
    }

    private function calculateTax(): void
    {
        $taxRate = $this->customer->getLocation() === 'US' ? 0.08 : 0;
        $this->tax = $this->subtotal * $taxRate;
    }

    private function applyDiscount(): void
    {
        if (!$this->couponCode) {
            return;
        }

        $coupon = (new CouponService())->findByCode($this->couponCode);
        if ($coupon?->isValid()) {
            $this->discount = $coupon->getPercentage() * $this->subtotal / 100;
        }
    }

    private function calculateShipping(): void
    {
        $this->shipping = $this->subtotal > 100 ? 0 : 15;
    }
}

// Usage in OrderProcessor
class OrderProcessor
{
    public function calculateTotal(
        Order $order,
        Customer $customer,
        string $couponCode = null
    ): float {
        return (new CalculateOrderTotal($order, $customer, $couponCode))();
    }
}
```

## Benefits

- **Readable structure**: Complex logic splits into named private methods that describe each step
- **Independent testing**: The method object can be built and tested without the original host class
- **Easier decomposition**: Complex logic breaks into small pieces inside one cohesive class
- **Portability**: The method object can be used from different contexts and callers
- **Single Responsibility**: Each class has one reason to exist
- **Easier debugging**: State lives in instance fields, so it is easy to inspect
- **Callable syntax**: `__invoke()` makes the object callable like a function

## When NOT to use

- **Simple methods**: If the method is short and easy to understand, a whole class is overkill
- **Hot paths**: Object construction costs little, but if the method runs billions of times, weigh the trade-off
- **One-off logic**: For logic that is never reused, a dedicated class may not pay for itself
- **Plain parameter forwarding**: If the method only passes arguments along, extract a smaller helper instead
- **Conflicting architecture**: Do not introduce this pattern if the codebase follows a different architectural convention

## Related Refactorings

- **Extract Method**: Often the first refactoring to try when complex logic appears inside a method
- **Extract Class**: A broader variant that pulls out a whole responsibility instead of a single operation
- **Decompose Conditional**: Simplifies branching logic before you move it to a method object
- **Introduce Parameter Object**: Pairs with this technique to bundle related constructor arguments
- **Strategy Pattern**: Method objects often grow into Strategy implementations with interchangeable variants

## Examples in other languages

### Java

**Before:**
```java
class Order {
  // ...
  public double price() {
    double primaryBasePrice;
    double secondaryBasePrice;
    double tertiaryBasePrice;
    // Perform long computation.
  }
}
```

**After:**
```java
class Order {
  // ...
  public double price() {
    return new PriceCalculator(this).compute();
  }
}

class PriceCalculator {
  private double primaryBasePrice;
  private double secondaryBasePrice;
  private double tertiaryBasePrice;

  public PriceCalculator(Order order) {
    // Copy relevant information from the
    // order object.
  }

  public double compute() {
    // Perform long computation.
  }
}
```

### C#

**Before:**
```csharp
public class Order
{
  // ...
  public double Price()
  {
    double primaryBasePrice;
    double secondaryBasePrice;
    double tertiaryBasePrice;
    // Perform long computation.
  }
}
```

**After:**
```csharp
public class Order
{
  // ...
  public double Price()
  {
    return new PriceCalculator(this).Compute();
  }
}

public class PriceCalculator
{
  private double primaryBasePrice;
  private double secondaryBasePrice;
  private double tertiaryBasePrice;

  public PriceCalculator(Order order)
  {
    // Copy relevant information from the
    // order object.
  }

  public double Compute()
  {
    // Perform long computation.
  }
}
```

### Python

**Before:**
```python
class Order:
    # ...
    def price(self):
        primaryBasePrice = 0
        secondaryBasePrice = 0
        tertiaryBasePrice = 0
        # Perform long computation.
```

**After:**
```python
class Order:
    # ...
    def price(self):
        return PriceCalculator(self).compute()


class PriceCalculator:
    def __init__(self, order):
        self._primaryBasePrice = 0
        self._secondaryBasePrice = 0
        self._tertiaryBasePrice = 0
        # Copy relevant information from the
        # order object.

    def compute(self):
        # Perform long computation.
```

### TypeScript

**Before:**
```typescript
class Order {
  // ...
  price(): number {
    let primaryBasePrice;
    let secondaryBasePrice;
    let tertiaryBasePrice;
    // Perform long computation.
  }
}
```

**After:**
```typescript
class Order {
  // ...
  price(): number {
    return new PriceCalculator(this).compute();
  }
}

class PriceCalculator {
  private _primaryBasePrice: number;
  private _secondaryBasePrice: number;
  private _tertiaryBasePrice: number;

  constructor(order: Order) {
    // Copy relevant information from the
    // order object.
  }

  compute(): number {
    // Perform long computation.
  }
}
```

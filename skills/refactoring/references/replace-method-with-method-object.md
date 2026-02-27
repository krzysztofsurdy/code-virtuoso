## Overview

Replace Method with Method Object is a refactoring technique that transforms a complex method into a dedicated class. The method becomes the primary operation of this new object, while local variables become instance attributes. This pattern is particularly useful for methods with many parameters, complex logic, or interdependent local variables.

## Motivation

### Problem
- **Complex methods**: Methods with multiple parameters and local variables become difficult to understand
- **Poor reusability**: Logic is tied to a single class and cannot be easily extracted or tested independently
- **Limited decomposition**: Breaking the method into smaller pieces within the same class is awkward
- **Testing difficulties**: Testing specific branches of complex logic requires instantiating the entire parent class
- **Parameter passing**: Methods with many parameters lead to verbose signatures and maintenance issues

### Solution
Create a new class where:
- The method becomes a public operation (usually `__invoke()` or `execute()`)
- Parameters become constructor arguments
- Local variables become instance properties
- Method logic moves into the class

## Mechanics

1. Create a new class named appropriately (e.g., `CalculateOrderTotal`, `GenerateReport`)
2. Move all method parameters to the constructor
3. Move all local variables to instance properties
4. Copy the method's logic into a `__invoke()` or `execute()` method
5. Replace the original method with an instantiation and call to the new class
6. Test thoroughly to ensure identical behavior
7. Consider extracting sub-methods within the Method Object

## Before/After Examples

### Before: Complex Method with Multiple Parameters

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

### After: Method Object Pattern

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

- **Improved Readability**: Method Object divides complex logic into named private methods that explain intent
- **Better Testability**: Method Object can be tested independently without the parent class
- **Enhanced Decomposition**: Complex logic is broken into manageable pieces within a focused class
- **Reusability**: Method Object can be instantiated in different contexts
- **Single Responsibility**: Each class has one reason to change
- **Easier Debugging**: State is encapsulated and easier to inspect
- **Callable Pattern**: Using `__invoke()` makes the object callable and elegant in PHP 8.3+

## When NOT to Use

- **Simple Methods**: If the method is straightforward and easy to understand, don't over-engineer
- **Performance Critical**: Creating objects has minimal overhead, but if called billions of times, consider alternatives
- **One-time Logic**: For truly single-use logic, the overhead may not justify the benefit
- **Simple Parameter Passing**: If the method only passes parameters without complex logic, extract a smaller method instead
- **Existing Architecture**: Don't apply this pattern if your codebase already uses a different architectural style

## Related Refactorings

- **Extract Method**: Often the first step when identifying complex logic within a method
- **Extract Class**: Similar concept but applied at a broader scope to extract responsibilities
- **Decompose Conditional**: Useful for breaking down complex conditional logic before extracting a Method Object
- **Introduce Parameter Object**: Combine with this pattern to group related parameters
- **Strategy Pattern**: Method Objects often evolve into Strategy implementations with multiple variants

## Examples in Other Languages

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

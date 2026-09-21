## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After (PHP 8.3+)](#beforeafter-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Parameter with Method Call shortens method signatures by removing parameters whose values the method can get itself. The caller no longer computes and passes the value. The method fetches it through a query call.

## Motivation

Long parameter lists are hard to read and easy to call wrong. This refactoring helps by:

- Removing parameters that were added "just in case" for future use
- Reducing the effort of tracking intermediate values across call sites
- Giving methods shorter, clearer signatures
- Lowering the coupling between calling code and the method's internals

## Mechanics

1. **Check independence**: Confirm the value-retrieval logic does not depend on parameters of the method being changed
2. **Extract if complex**: If the retrieval logic is non-trivial, move it into its own method first
3. **Substitute references**: Replace every use of the parameter inside the method with a call to the retrieval method
4. **Drop the parameter**: Remove the unused parameter from the method signature
5. **Fix call sites**: Delete the matching argument from every caller

## Before/After (PHP 8.3+)

**Before:**
```php
class Order
{
    private int $quantity;
    private float $basePrice;

    public function getPrice(float $discountPercentage): float
    {
        return $this->calculateFinalPrice($discountPercentage);
    }

    private function calculateFinalPrice(float $discount): float
    {
        $baseTotal = $this->quantity * $this->basePrice;
        return $baseTotal * (1 - $discount / 100);
    }
}

// Usage
$order = new Order();
$discount = $order->getDiscount();
$price = $order->getPrice($discount);
```

**After:**
```php
class Order
{
    private int $quantity;
    private float $basePrice;

    public function getPrice(): float
    {
        return $this->calculateFinalPrice();
    }

    private function calculateFinalPrice(): float
    {
        $baseTotal = $this->quantity * $this->basePrice;
        return $baseTotal * (1 - $this->getDiscount() / 100);
    }

    private function getDiscount(): float
    {
        // Query the discount value directly
        return 10.0;
    }
}

// Usage
$order = new Order();
$price = $order->getPrice();
```

## Benefits

- **Shorter signatures**: Fewer parameters make methods easier to understand and call
- **Lower coupling**: The method no longer depends on the caller for data it can get itself
- **Better encapsulation**: The object retrieves its own information instead of relying on outside computation
- **Cleaner call sites**: Calling code is shorter and more focused
- **Localized changes**: A change in how a value is computed affects only the object that owns it

## When NOT to use

- **Caller-dependent values**: If the value depends on the caller's context and cannot be derived internally, keep the parameter
- **Different inputs per context**: The same method must give different results depending on what the caller provides
- **Hot code paths**: Repeated internal queries may be slower than passing a precomputed value
- **Cross-object data**: The value belongs to another object's domain and should not be fetched here
- **Intended flexibility**: You expect to inject alternative values for testing or future variations

## Related Refactorings

- **Extract Method**: Apply when the retrieval logic is complex enough to warrant its own method
- **Add Parameter**: The inverse refactoring, used when a method needs more flexibility
- The simplifying method calls group of refactorings: Other techniques that reduce parameter list complexity
- **Remove Parameter**: A related technique for eliminating parameters that are no longer used

## Examples in other languages

### Java

**Before:**
```java
int basePrice = quantity * itemPrice;
double seasonDiscount = this.getSeasonalDiscount();
double fees = this.getFees();
double finalPrice = discountedPrice(basePrice, seasonDiscount, fees);
```

**After:**
```java
int basePrice = quantity * itemPrice;
double finalPrice = discountedPrice(basePrice);
```

### C#

**Before:**
```csharp
int basePrice = quantity * itemPrice;
double seasonDiscount = this.GetSeasonalDiscount();
double fees = this.GetFees();
double finalPrice = DiscountedPrice(basePrice, seasonDiscount, fees);
```

**After:**
```csharp
int basePrice = quantity * itemPrice;
double finalPrice = DiscountedPrice(basePrice);
```

### Python

**Before:**
```python
basePrice = quantity * itemPrice
seasonalDiscount = self.getSeasonalDiscount()
fees = self.getFees()
finalPrice = discountedPrice(basePrice, seasonalDiscount, fees)
```

**After:**
```python
basePrice = quantity * itemPrice
finalPrice = discountedPrice(basePrice)
```

### TypeScript

**Before:**
```typescript
let basePrice = quantity * itemPrice;
const seasonDiscount = this.getSeasonalDiscount();
const fees = this.getFees();
const finalPrice = discountedPrice(basePrice, seasonDiscount, fees);
```

**After:**
```typescript
let basePrice = quantity * itemPrice;
let finalPrice = discountedPrice(basePrice);
```

## Overview

Replace Parameter with Method Call is a refactoring technique that simplifies method signatures by eliminating parameters whose values can be computed or retrieved internally. Instead of passing calculated values as arguments, the method retrieves them directly through query calls.

## Motivation

Long parameter lists are difficult to understand and maintain. This refactoring addresses this complexity by:

- Eliminating parameters created speculatively for hypothetical future needs
- Reducing cognitive load when tracking intermediate values through multiple method calls
- Making method signatures more concise and readable
- Reducing coupling between methods

## Mechanics

1. **Verify independence**: Ensure the value-retrieval code doesn't depend on parameters of the method being refactored
2. **Extract if needed**: If retrieval logic is complex, extract it into a dedicated method first
3. **Replace references**: Replace all references to the parameter with calls to the new method
4. **Remove parameter**: Delete the now-unused parameter from the method signature
5. **Update callers**: Remove the argument from all call sites

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

- **Simpler method signatures**: Shorter parameter lists are easier to understand and remember
- **Reduced coupling**: Methods become less dependent on caller context
- **Better encapsulation**: Objects retrieve their own data rather than receiving it
- **Improved readability**: Call sites become cleaner and more expressive
- **Easier maintenance**: Changes to value computation affect only the object

## When NOT to Use

- **Parameter-dependent values**: If the retrieved value depends on method parameters, this refactoring is inappropriate
- **Different contexts need different values**: When the same method must return different results based on caller-provided context
- **Performance critical**: Repeated method calls might be slower than parameter passing
- **Cross-object retrieval**: When the value belongs to another object's domain
- **Future flexibility needed**: If you anticipate needing to inject different values in testing or future versions

## Related Refactorings

- **Extract Method**: Use when retrieval logic is complex and should become a dedicated method
- **Add Parameter**: The opposite refactoring when you need to increase flexibility
- **Simplify Method Calls**: Parent category addressing long parameter lists
- **Remove Parameter**: Similar technique for eliminating unused parameters

## Examples in Other Languages

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

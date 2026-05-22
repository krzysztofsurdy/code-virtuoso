## Overview

Remove Assignments to Parameters stops the practice of overwriting method parameters inside the method body. When a parameter is reassigned, readers lose track of the value it originally carried, and the method's intent becomes muddled. Introducing a local variable to hold the evolving value preserves the parameter's original meaning while keeping the computation correct.

## Motivation

### When to Apply

- **Parameters are reassigned**: A method parameter is assigned a new value within the method body
- **Value transformation**: A parameter undergoes transformation or modification during execution
- **Confusion about intent**: Readers can't distinguish between the original parameter and its modified state
- **Parameter reuse**: Parameters are reused for different purposes throughout the method
- **Debugging difficulty**: It's hard to trace what the parameter originally contained versus its current value

### Why It Matters

A parameter name communicates what the caller sent in. The moment the method overwrites that value, the name becomes misleading - it no longer represents the caller's input. A local variable with a distinct name separates the "what came in" from the "what we computed," making the method easier to read, debug, and extend.

## Mechanics: Step-by-Step

1. **Identify reassignments**: Find all places where a parameter is assigned a new value
2. **Create local variable**: Introduce a new local variable with a meaningful name
3. **Assign from parameter**: Initialize the local variable with the parameter's value
4. **Replace usages**: Replace all assignments to the parameter with assignments to the local variable
5. **Update references**: Change all subsequent references to use the local variable instead of the parameter
6. **Test thoroughly**: Verify the method's behavior remains unchanged

## Before: PHP 8.3+ Example

```php
<?php declare(strict_types=1);

class PriceCalculator
{
    public function calculateDiscount(float $price, int $quantity): float
    {
        // Price parameter gets reassigned - confusing!
        $price = $price * $quantity;

        if ($price > 100) {
            $price = $price * 0.9; // 10% bulk discount
        }

        if ($price > 500) {
            $price = $price * 0.85; // Additional 15% discount
        }

        return $price;
    }

    public function processOrder(string $status, array $items): void
    {
        // Status parameter reassigned - unclear intent
        $status = strtolower($status);

        if ($status === 'pending') {
            $this->validateItems($items);
            $status = 'validated';
        }

        if ($status === 'validated') {
            $this->chargePayment($items);
            $status = 'completed';
        }

        // Which status is being returned - the original or current?
        $this->logStatus($status);
    }
}
```

## After: PHP 8.3+ Example

```php
<?php declare(strict_types=1);

class PriceCalculator
{
    public function calculateDiscount(float $price, int $quantity): float
    {
        // Original parameter intent is preserved
        // Local variable tracks the calculated total
        $totalPrice = $price * $quantity;

        if ($totalPrice > 100) {
            $totalPrice = $totalPrice * 0.9; // 10% bulk discount
        }

        if ($totalPrice > 500) {
            $totalPrice = $totalPrice * 0.85; // Additional 15% discount
        }

        return $totalPrice;
    }

    public function processOrder(string $status, array $items): void
    {
        // Original status parameter remains unchanged and meaningful
        // Local variable tracks the processing state transitions
        $currentStatus = strtolower($status);

        if ($currentStatus === 'pending') {
            $this->validateItems($items);
            $currentStatus = 'validated';
        }

        if ($currentStatus === 'validated') {
            $this->chargePayment($items);
            $currentStatus = 'completed';
        }

        // Clear intent: logging the current processing status
        $this->logStatus($currentStatus);
    }
}
```

## Benefits

- **Preserved Semantics**: Parameters keep their original meaning from first line to last
- **Straightforward Debugging**: The input value is always available for inspection
- **Improved Readability**: Developers see at a glance what arrived versus what was computed
- **Lower Cognitive Load**: No need to mentally track when a parameter's meaning shifted
- **Cleaner Testing**: Test assertions can reference both input and result without ambiguity
- **Accident Prevention**: New contributors will not unknowingly depend on a mutated parameter

## When NOT to Use

- **Simple transformations**: If a parameter is reassigned once at the start with a clear purpose, it may be acceptable
- **Language idioms**: Some languages or codebases have conventions where parameter reassignment is standard
- **Performance-critical code**: In rare cases where avoiding extra variable allocation is crucial (typically negligible)
- **Parameter is output**: If the method intends to modify the parameter for the caller (pass-by-reference behavior), reassignment is intentional
- **Single responsibility**: If the method is already refactored to be very short, parameter reassignment becomes less problematic

## Related Refactorings

- **Extract Method**: Often combined to reduce parameter reassignment complexity in large methods
- **Replace Temp with Query**: Eliminates local variables that might be reassigned
- **Introduce Parameter Object**: Groups related parameters to reduce reassignment of individual parameters
- **Replace Method with Method Object**: When parameter reassignment indicates the method is doing too much
- **Decompose Conditional**: Breaks complex logic that causes multiple parameter reassignments

## Examples in Other Languages

### Java

**Before:**
```java
int discount(int inputVal, int quantity) {
  if (quantity > 50) {
    inputVal -= 2;
  }
  // ...
}
```

**After:**
```java
int discount(int inputVal, int quantity) {
  int result = inputVal;
  if (quantity > 50) {
    result -= 2;
  }
  // ...
}
```

### C#

**Before:**
```csharp
int Discount(int inputVal, int quantity)
{
  if (quantity > 50)
  {
    inputVal -= 2;
  }
  // ...
}
```

**After:**
```csharp
int Discount(int inputVal, int quantity)
{
  int result = inputVal;

  if (quantity > 50)
  {
    result -= 2;
  }
  // ...
}
```

### Python

**Before:**
```python
def discount(inputVal, quantity):
    if quantity > 50:
        inputVal -= 2
    # ...
```

**After:**
```python
def discount(inputVal, quantity):
    result = inputVal
    if quantity > 50:
        result -= 2
    # ...
```

### TypeScript

**Before:**
```typescript
discount(inputVal: number, quantity: number): number {
  if (quantity > 50) {
    inputVal -= 2;
  }
  // ...
}
```

**After:**
```typescript
discount(inputVal: number, quantity: number): number {
  let result = inputVal;
  if (quantity > 50) {
    result -= 2;
  }
  // ...
}
```

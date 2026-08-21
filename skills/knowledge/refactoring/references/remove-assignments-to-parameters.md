# Remove Assignments to Parameters

## Overview

Remove Assignments to Parameters stops the practice of overwriting method parameters inside the method body. When a parameter is reassigned, readers lose track of the value it first held, and the method's intent gets muddled. A local variable that holds the changing value keeps the parameter's original meaning and the computation correct.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics: step by step](#mechanics-step-by-step)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

### When to apply

- **Parameters are reassigned**: a method parameter gets a new value inside the method body
- **Value transformation**: a parameter is transformed or modified during execution
- **Confusion about intent**: readers cannot tell the original parameter from its modified state
- **Parameter reuse**: a parameter is reused for different purposes in the same method
- **Debugging difficulty**: it is hard to tell what the parameter originally held versus its current value

### Why it matters

A parameter name tells the reader what the caller sent in. Once the method overwrites that value, the name is misleading, because it no longer represents the caller's input. A local variable with its own name separates what came in from what was computed. The method is then easier to read, debug, and extend.

## Mechanics: step by step

1. **Identify reassignments**: find every place where a parameter is assigned a new value.
2. **Create a local variable**: add a new local variable with a meaningful name.
3. **Assign from the parameter**: initialize the local variable with the parameter's value.
4. **Replace assignments**: change each assignment to the parameter into an assignment to the local variable.
5. **Update references**: change all later references to use the local variable instead of the parameter.
6. **Test**: verify that the method behaves as before.

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

- **Preserved meaning**: parameters keep their original meaning from the first line to the last.
- **Easier debugging**: the input value is always available for inspection.
- **Better readability**: readers see what arrived and what was computed.
- **Lower cognitive load**: no need to track when a parameter's meaning changed.
- **Cleaner testing**: assertions can refer to both input and result without ambiguity.
- **Fewer accidents**: new contributors will not depend on a mutated parameter by mistake.

## When not to use

- **Simple transformations**: if a parameter is reassigned once at the start with a clear purpose, it may be acceptable.
- **Language idioms**: some languages or codebases treat parameter reassignment as standard.
- **Performance-critical code**: in rare cases where avoiding an extra variable matters (the cost is usually tiny).
- **Parameter is output**: if the method is meant to modify the parameter for the caller (pass-by-reference), the reassignment is intentional.
- **Very short methods**: if the method is already very short, parameter reassignment is less of a problem.

## Related refactorings

- **Extract Method**: often combined with this refactoring to reduce reassignment in large methods.
- **Replace Temp with Query**: removes local variables that might be reassigned.
- **Introduce Parameter Object**: groups related parameters so fewer individual parameters get reassigned.
- **Replace Method with Method Object**: for when parameter reassignment shows the method does too much.
- **Decompose Conditional**: breaks up complex logic that causes several parameter reassignments.

## Examples in other languages

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

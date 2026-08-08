## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after examples](#before-and-after-examples)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Inline Temp removes a temporary variable that adds no clarity by replacing it with the expression it holds. If a variable is assigned once, used once, and its name says nothing the expression does not, the variable is a detour. Removing it makes the code more direct.

## Motivation

Temporary variables often appear for reasons that no longer apply:

- **Pass-through assignments**: A variable stores a value only to hand it to the next line
- **Leftover debugging aids**: Variables introduced to inspect values during development that stayed
- **Over-explanation**: Variables whose names restate the expression without adding insight
- **Needless decomposition**: Steps split apart without improving readability
- **Single-use intermediaries**: Variables that exist only to bridge two adjacent lines

When a variable does not help the reader, removing it tightens the logic and often shows further simplifications.

## Mechanics

1. **Identify the variable**: Find a temporary that is assigned once and used once or a small number of times
2. **Check for side effects**: Confirm the expression has no side effects that would be duplicated
3. **Substitute each usage**: Replace every reference to the variable with the original expression
4. **Delete the declaration**: Remove the variable and its assignment
5. **Run the tests**: Confirm behavior is unchanged
6. **Reassess**: If the resulting expression is too dense, consider Extract Variable for selected parts

## Before and after examples

### Example 1: simple arithmetic expression

**Before:**
```php
<?php

declare(strict_types=1);

class Calculator
{
    public function calculateTotal(int $basePrice, float $taxRate): float
    {
        $taxAmount = $basePrice * $taxRate;
        $total = $basePrice + $taxAmount;
        return $total;
    }
}

// Usage
$calc = new Calculator();
$result = $calc->calculateTotal(100, 0.1);
```

**After:**
```php
<?php

declare(strict_types=1);

class Calculator
{
    public function calculateTotal(int $basePrice, float $taxRate): float
    {
        return $basePrice + ($basePrice * $taxRate);
    }
}

// Usage
$calc = new Calculator();
$result = $calc->calculateTotal(100, 0.1);
```

### Example 2: method call result

**Before:**
```php
<?php

declare(strict_types=1);

class UserService
{
    public function processUser(User $user): string
    {
        $username = $user->getUsername();
        $greeting = "Hello, " . strtoupper($username);
        return $greeting;
    }
}

// Usage
$service = new UserService();
$message = $service->processUser($user);
```

**After:**
```php
<?php

declare(strict_types=1);

class UserService
{
    public function processUser(User $user): string
    {
        return "Hello, " . strtoupper($user->getUsername());
    }
}

// Usage
$service = new UserService();
$message = $service->processUser($user);
```

### Example 3: conditional expression

**Before:**
```php
<?php

declare(strict_types=1);

class OrderProcessor
{
    public function determineDiscount(int $totalAmount, bool $isLoyalCustomer): float
    {
        $baseDiscount = $isLoyalCustomer ? 0.15 : 0.05;
        $finalDiscount = $totalAmount > 1000 ? $baseDiscount * 2 : $baseDiscount;
        return $finalDiscount;
    }
}

// Usage
$processor = new OrderProcessor();
$discount = $processor->determineDiscount(1500, true);
```

**After:**
```php
<?php

declare(strict_types=1);

class OrderProcessor
{
    public function determineDiscount(int $totalAmount, bool $isLoyalCustomer): float
    {
        $baseDiscount = $isLoyalCustomer ? 0.15 : 0.05;
        return $totalAmount > 1000 ? $baseDiscount * 2 : $baseDiscount;
    }
}

// Usage
$processor = new OrderProcessor();
$discount = $processor->determineDiscount(1500, true);
```

## Benefits

- **Tighter code**: Fewer lines and variables to track
- **Clearer data flow**: The relationship between expressions is visible without intermediate stops
- **Faster reading**: Readers parse fewer declarations
- **Shows further refactoring**: Removing intermediaries often exposes chances for Extract Method
- **Less noise**: No naming decisions that carry no information

## When not to use

- **The name adds meaning**: If the variable name says something the expression does not, keep it
- **Multiple usages**: A variable used in several places avoids repeating the expression
- **Expressions with side effects**: Inlining would evaluate the expression several times and repeat the side effects
- **Complex expressions**: If the result would be a dense, hard-to-read compound expression, the variable is useful
- **Expensive computations**: A variable can name an operation and avoid paying for it twice
- **Stateful method calls**: Calls that depend on or change object state should not be repeated
- **Debugging breakpoints**: Variables kept for breakpoint placement may be worth keeping during development

## Related refactorings

- **Extract Variable**: The opposite: introducing a named variable when an expression is too complex
- **Inline Method**: The same idea applied to methods instead of temporary variables
- **Replace Temp with Query**: Converts a temp into a method call, which helps when the expression should be reusable
- **Remove Dead Code**: Removes variables that are declared but never read

## Examples in other languages

### Java

**Before:**
```java
boolean hasDiscount(Order order) {
  double basePrice = order.basePrice();
  return basePrice > 1000;
}
```

**After:**
```java
boolean hasDiscount(Order order) {
  return order.basePrice() > 1000;
}
```

### C#

**Before:**
```csharp
bool HasDiscount(Order order)
{
  double basePrice = order.BasePrice();
  return basePrice > 1000;
}
```

**After:**
```csharp
bool HasDiscount(Order order)
{
  return order.BasePrice() > 1000;
}
```

### Python

**Before:**
```python
def hasDiscount(order):
    basePrice = order.basePrice()
    return basePrice > 1000
```

**After:**
```python
def hasDiscount(order):
    return order.basePrice() > 1000
```

### TypeScript

**Before:**
```typescript
hasDiscount(order: Order): boolean {
  let basePrice: number = order.basePrice();
  return basePrice > 1000;
}
```

**After:**
```typescript
hasDiscount(order: Order): boolean {
  return order.basePrice() > 1000;
}
```

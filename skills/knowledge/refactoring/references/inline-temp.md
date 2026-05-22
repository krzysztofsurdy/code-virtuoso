## Overview

Inline Temp removes a temporary variable that adds no clarity by replacing it with the expression it holds. When a variable is assigned once, used once, and its name does not reveal anything the expression itself does not already say, the variable is just a detour. Removing it makes the code more direct.

## Motivation

Temporary variables sometimes appear for valid reasons that no longer apply:

- **Pass-through assignments**: A variable stores a value only to hand it to the next line
- **Leftover debugging aids**: Variables introduced to inspect values during development that stayed
- **Over-explanation**: Variables whose names restate the expression without adding insight
- **Unnecessary decomposition**: Steps broken apart that do not actually improve readability
- **Single-use intermediaries**: Variables that exist solely to bridge two adjacent lines

When a variable does not help the reader understand what the code does, removing it tightens the logic and often reveals further simplification opportunities.

## Mechanics

### Step-by-Step Process

1. **Identify the variable**: Find a temporary that is assigned once and used once or a small number of times
2. **Verify safety**: Confirm that the expression has no side effects that would be duplicated
3. **Substitute each usage**: Replace every reference to the variable with the original expression
4. **Delete the declaration**: Remove the variable and its assignment
5. **Run the tests**: Confirm behavior is unchanged
6. **Reassess**: If the resulting expression is too dense, consider Extract Variable for selected parts

## Before/After Examples

### Example 1: Simple Arithmetic Expression

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

### Example 2: Method Call Result

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

### Example 3: Conditional Expression

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
- **Faster reading**: Readers parse fewer declarations to understand what happens
- **Reveals further refactoring**: Removing intermediaries often exposes opportunities like Extract Method
- **Less noise**: Eliminates naming decisions that do not carry meaningful information

## When NOT to Use

- **Readable names add meaning**: If the variable name conveys something the expression does not, keep it
- **Multiple usages**: A variable used in several places prevents duplication of the expression
- **Side-effect-producing expressions**: Inlining would evaluate the expression multiple times, duplicating side effects
- **Complex expressions**: If the result would be a dense, hard-to-read compound expression, the variable is doing useful work
- **Expensive computations**: A variable can document and cache the cost of an operation
- **Stateful method calls**: Calls that depend on or modify object state should not be repeated
- **Debugging breakpoints**: Variables kept specifically for breakpoint placement may be worth retaining during development

## Related Refactorings

- **Extract Variable**: The opposite - introducing a named variable when an expression is too complex
- **Inline Method**: The same principle applied to methods rather than temporary variables
- **Replace Temp with Query**: Converts a temp into a method call, useful when the expression should be reusable
- **Remove Dead Code**: Identifies variables that are declared but never read

## Examples in Other Languages

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

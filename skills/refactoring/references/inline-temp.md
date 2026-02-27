## Overview

The Inline Temp refactoring technique eliminates unnecessary temporary variables by replacing them with the expressions that are assigned to them. This refactoring is typically applied when a temporary variable doesn't make the code more readable or when it's assigned a value only once and used only once. By removing these "pass-through" variables, you reduce visual noise and make the actual computation more apparent.

## Motivation

Temporary variables are often introduced for various reasons:

- **Simple assignments**: A variable created to hold the result of a simple expression that's only used once
- **Debugging convenience**: Variables added during development to make debugging easier but no longer needed
- **Over-explanation**: Variables that don't actually clarify intent, just add lines of code
- **Expression complexity**: Breaking complex expressions into steps that don't truly improve readability
- **Single-use assignments**: Variables that are assigned once and immediately used in the next line

When these variables don't provide meaningful insight into what the code does, inlining them makes the code more direct and often easier to understand at a glance.

## Mechanics

### Step-by-Step Process

1. **Identify the temporary variable**: Find a variable that is assigned once and used once or a few times
2. **Check usage patterns**: Verify that inlining won't create overly complex expressions
3. **Replace all usages**: Replace each use of the variable with the right-hand side of its assignment
4. **Handle side effects**: Ensure the expression has no side effects that would be duplicated
5. **Remove the variable**: Delete the temporary variable declaration and assignment
6. **Test**: Run tests to ensure behavior is preserved
7. **Refactor further if needed**: Use Extract Variable if the resulting expression is too complex

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

- **Reduced visual clutter**: Fewer variable declarations means less code to read
- **Improved clarity**: Removes "pass-through" variables that don't add meaning
- **Faster comprehension**: Shows the relationship between expressions directly
- **Easier refactoring**: Often reveals opportunities for further improvements
- **Lower memory footprint**: Eliminates unnecessary variable allocations (though modern optimizers often handle this)
- **Clearer intent**: Removes redundant naming that doesn't clarify purpose

## When NOT to Use

- **Complex expressions**: Don't inline if the result would be hard to understand at a glance
- **Repeated usage**: Keep the variable if it's used multiple times in different contexts
- **Side effects**: Don't inline if the expression has side effects that would be duplicated
- **Clarity purpose**: If a variable name significantly documents intent, preserve it
- **Performance-critical code**: When the expression involves expensive operations, a variable can serve as documentation and potential optimization point
- **Method calls with state**: Be careful inlining calls that depend on or modify object state
- **Debugging aid**: Variables added for debugging breakpoints may be worth keeping

## Related Refactorings

- **Extract Variable**: The reverse operation; use when expressions become too complex to inline
- **Inline Method**: Similar concept but applied to methods instead of temporary variables
- **Replace Temp with Query**: When a temp variable stores the result of a method call that could be called multiple times
- **Simplify Expression**: Use before inlining if the original expression is overly complex
- **Remove Dead Code**: Often identifies temp variables that are declared but never used

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

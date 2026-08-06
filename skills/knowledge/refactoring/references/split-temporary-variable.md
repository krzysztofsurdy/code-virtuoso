## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples](#beforeafter-examples)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Split Temporary Variable fixes temporary variables that are reused for different purposes within a method or function. When one variable holds different values at different points, it is unclear what it represents. The refactoring gives each distinct use its own variable with a meaningful name.

## Motivation

A temporary variable that serves several purposes in one method causes problems:

- **Ambiguous intent**: a variable named `temp` or `result` reused for different calculations obscures what the code is doing.
- **Difficult debugging**: it is hard to tell what the variable should contain at any given point.
- **Reduced readability**: readers must trace the variable's assignments to understand its purpose.
- **Increased error risk**: misusing a variable is easier when its purpose is unclear.
- **Harder refactoring**: extracting methods is difficult when variables have unclear responsibilities.

After the split, each variable has one purpose, stated in its name.

## Mechanics

1. **Identify variables**: find temporary variables that are assigned multiple times for different purposes.
2. **Analyze each assignment**: determine what each assignment represents and what value is being calculated.
3. **Create new variables**: introduce a descriptively named variable for each distinct purpose.
4. **Replace references**: update the code to use the appropriate new variable.
5. **Remove the original variable**: delete the original temporary variable.
6. **Test**: confirm the refactored code behaves identically.

## Before/After Examples

### Example 1: distance calculation

**Before:**
```php
function getDistance(float $initialVelocity, float $acceleration, float $time): float
{
    $result = $initialVelocity * $time;
    $result += 0.5 * $acceleration * $time * $time;

    return $result;
}
```

**After:**
```php
function getDistance(float $initialVelocity, float $acceleration, float $time): float
{
    $uniformMotionDistance = $initialVelocity * $time;
    $acceleratedMotionDistance = 0.5 * $acceleration * $time * $time;

    return $uniformMotionDistance + $acceleratedMotionDistance;
}
```

### Example 2: user processing

**Before:**
```php
public function processUser(array $data): array
{
    $temp = strtolower($data['name']);
    $temp = trim($temp);

    $temp = str_replace(' ', '_', $temp);
    $temp = preg_replace('/[^a-z0-9_]/', '', $temp);

    return ['username' => $temp];
}
```

**After:**
```php
public function processUser(array $data): array
{
    $normalizedName = strtolower($data['name']);
    $normalizedName = trim($normalizedName);

    $username = str_replace(' ', '_', $normalizedName);
    $username = preg_replace('/[^a-z0-9_]/', '', $username);

    return ['username' => $username];
}
```

### Example 3: complex calculation

**Before:**
```php
function calculatePrice(float $quantity, float $unitPrice, float $taxRate, float $discount): float
{
    $amount = $quantity * $unitPrice;
    $amount = $amount - ($amount * $discount);
    $amount = $amount + ($amount * $taxRate);

    return $amount;
}
```

**After:**
```php
function calculatePrice(
    float $quantity,
    float $unitPrice,
    float $taxRate,
    float $discount
): float {
    $subtotal = $quantity * $unitPrice;
    $discountedSubtotal = $subtotal - ($subtotal * $discount);
    $total = $discountedSubtotal + ($discountedSubtotal * $taxRate);

    return $total;
}
```

## Benefits

- **Readability**: variable names express their purpose, so the code documents itself.
- **Maintainability**: developers can quickly see what each variable represents.
- **Debugging**: variable values are easier to trace and unexpected assignments are easier to catch.
- **Easier extraction**: a clearer structure makes it easier to extract methods.
- **Less confusion**: overloaded temporary variables no longer blur meaning.
- **Typing**: each variable can have a type hint that fits its specific purpose.

## When not to use

- **Loop counters**: do not split standard loop counters like `$i`, `$j`, `$k`. They have a single, understood purpose.
- **Accumulators**: variables that accumulate values (e.g., sum, count) should not be split if they serve one purpose.
- **Performance critical code**: in rare performance-critical sections, creating multiple variables might have minor overhead.
- **Legacy code without tests**: refactoring without test coverage is risky; write the tests first.
- **Already clear code**: if the variable's purpose is obvious from context and naming, the refactoring adds nothing.

## Related refactorings

- **Extract Method**: often used after splitting variables to separate concerns.
- **Rename Variable**: gives the split variables meaningful names.
- **Introduce Parameter Object**: when many variables emerge, consider grouping related parameters.
- **Replace Temp with Query**: turns temporary variables into method calls for better encapsulation.

## Examples in other languages

### Java

**Before:**
```java
double temp = 2 * (height + width);
System.out.println(temp);
temp = height * width;
System.out.println(temp);
```

**After:**
```java
final double perimeter = 2 * (height + width);
System.out.println(perimeter);
final double area = height * width;
System.out.println(area);
```

### C#

**Before:**
```csharp
double temp = 2 * (height + width);
Console.WriteLine(temp);
temp = height * width;
Console.WriteLine(temp);
```

**After:**
```csharp
readonly double perimeter = 2 * (height + width);
Console.WriteLine(perimeter);
readonly double area = height * width;
Console.WriteLine(area);
```

### Python

**Before:**
```python
temp = 2 * (height + width)
print(temp)
temp = height * width
print(temp)
```

**After:**
```python
perimeter = 2 * (height + width)
print(perimeter)
area = height * width
print(area)
```

### TypeScript

**Before:**
```typescript
let temp = 2 * (height + width);
console.log(temp);
temp = height * width;
console.log(temp);
```

**After:**
```typescript
const perimeter = 2 * (height + width);
console.log(perimeter);
const area = height * width;
console.log(area);
```

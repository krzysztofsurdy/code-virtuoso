## Overview

The Split Temporary Variable refactoring technique addresses the problem of temporary variables that are reused for different purposes throughout a method or function. When a single temporary variable holds different values at different points in the code, it becomes confusing about what the variable actually represents. This refactoring extracts each distinct usage into its own variable with a meaningful name.

## Motivation

Temporary variables often become problematic when they serve multiple purposes within a method. Common issues include:

- **Ambiguous Intent**: A variable named `temp` or `result` reused for different calculations obscures what the code is doing
- **Difficult Debugging**: It's hard to understand what a variable should contain at any given point
- **Reduced Readability**: Future developers must trace the variable's assignments to understand its purpose
- **Increased Error Risk**: Misusing a variable becomes easier when its purpose isn't clear
- **Harder Refactoring**: Extracting methods becomes difficult when variables have unclear responsibilities

By splitting temporary variables, each one has a single, well-defined purpose captured in its name.

## Mechanics

1. **Identify Variables**: Find temporary variables that are assigned multiple times with different purposes
2. **Analyze Each Assignment**: Determine what each assignment represents and what value is being calculated
3. **Create New Variables**: Introduce new variables with descriptive names for each distinct purpose
4. **Replace References**: Update code to use the appropriate new variable
5. **Remove Original Variable**: Delete the original temporary variable
6. **Test**: Ensure the refactored code behaves identically

## Before/After Examples

### Example 1: Distance Calculation

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

### Example 2: User Processing

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

### Example 3: Complex Calculation

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

- **Increased Readability**: Variable names clearly express their purpose, making code self-documenting
- **Improved Maintainability**: Developers can quickly understand what each variable represents
- **Better Debugging**: Easier to trace variable values and catch unexpected assignments
- **Facilitates Extraction**: Clearer code structure makes it easier to extract methods
- **Reduces Confusion**: Eliminates the ambiguity of overloaded temporary variables
- **Type Safety**: Each variable can have appropriate type hints based on its specific purpose

## When NOT to Use

- **Loop Counters**: Don't split standard loop counters like `$i`, `$j`, `$k` – they have a single, understood purpose
- **Accumulators**: Variables that genuinely accumulate values (e.g., sum, count) shouldn't be split if they truly serve one purpose
- **Performance Critical Code**: In rare performance-critical sections, creating multiple variables might have minor overhead implications
- **Legacy Code Without Tests**: Refactoring without test coverage is risky; ensure tests exist first
- **Already Clear Code**: If variable purpose is obvious from context and naming, the refactoring adds no value

## Related Refactorings

- **Extract Method**: Often used after splitting variables to separate concerns
- **Rename Variable**: Use meaningful names when introducing split variables
- **Introduce Parameter Object**: When many variables emerge, consider grouping related parameters
- **Replace Temp with Query**: Transform temporary variables into method calls for better encapsulation

## Examples in Other Languages

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

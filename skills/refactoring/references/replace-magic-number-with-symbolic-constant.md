## Overview

Replace Magic Number with Symbolic Constant is a refactoring technique that eliminates mysterious numeric literals (magic numbers) from code by replacing them with clearly named constants. Magic numbers are unexplained numeric values scattered throughout code that obscure intent and make maintenance difficult. By creating named constants, code becomes self-documenting and easier to maintain.

## Motivation

### When to Apply

- **Unexplained numbers**: Numeric literals appear without context or explanation
- **Repeated values**: The same magic number appears in multiple places
- **Domain significance**: Numbers represent business logic or domain concepts
- **Configuration values**: Numbers that might change based on requirements
- **Unclear purpose**: Readers must infer what a number represents
- **Maintenance burden**: Changing a value requires searching and updating multiple locations

### Why It Matters

Magic numbers create technical debt by hiding intent and making code fragile. If a value must change, developers must find and update every occurrence—risking inconsistency. Named constants make code self-documenting, reduce bugs, and simplify refactoring across the codebase.

## Mechanics: Step-by-Step

1. **Identify magic numbers**: Scan code for unexplained numeric literals
2. **Understand the meaning**: Determine what the number represents in the domain
3. **Choose a name**: Create a descriptive constant name that explains the value's purpose
4. **Define the constant**: Create a named constant (class constant, global constant, or enum)
5. **Replace occurrences**: Replace all instances of the magic number with the constant
6. **Verify behavior**: Ensure program behavior remains unchanged
7. **Consider scope**: Place constants at appropriate scope (local, class, global)

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class PricingCalculator
{
    public function calculateDiscount(float $purchaseAmount): float
    {
        if ($purchaseAmount >= 1000) {
            return $purchaseAmount * 0.15;
        }

        if ($purchaseAmount >= 500) {
            return $purchaseAmount * 0.10;
        }

        if ($purchaseAmount >= 100) {
            return $purchaseAmount * 0.05;
        }

        return 0;
    }

    public function calculateTax(float $amount, string $region): float
    {
        if ($region === 'US') {
            return $amount * 0.07;
        }

        if ($region === 'EU') {
            return $amount * 0.21;
        }

        return $amount * 0.05;
    }

    public function calculateShipping(float $weight): float
    {
        if ($weight > 50) {
            return 25;
        }

        return 10;
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class PricingCalculator
{
    private const PREMIUM_THRESHOLD = 1000;
    private const PREMIUM_DISCOUNT_RATE = 0.15;

    private const STANDARD_THRESHOLD = 500;
    private const STANDARD_DISCOUNT_RATE = 0.10;

    private const BASIC_THRESHOLD = 100;
    private const BASIC_DISCOUNT_RATE = 0.05;

    private const US_TAX_RATE = 0.07;
    private const EU_TAX_RATE = 0.21;
    private const DEFAULT_TAX_RATE = 0.05;

    private const HEAVY_WEIGHT_THRESHOLD = 50;
    private const HEAVY_SHIPPING_COST = 25;
    private const STANDARD_SHIPPING_COST = 10;

    public function calculateDiscount(float $purchaseAmount): float
    {
        if ($purchaseAmount >= self::PREMIUM_THRESHOLD) {
            return $purchaseAmount * self::PREMIUM_DISCOUNT_RATE;
        }

        if ($purchaseAmount >= self::STANDARD_THRESHOLD) {
            return $purchaseAmount * self::STANDARD_DISCOUNT_RATE;
        }

        if ($purchaseAmount >= self::BASIC_THRESHOLD) {
            return $purchaseAmount * self::BASIC_DISCOUNT_RATE;
        }

        return 0;
    }

    public function calculateTax(float $amount, string $region): float
    {
        return match ($region) {
            'US' => $amount * self::US_TAX_RATE,
            'EU' => $amount * self::EU_TAX_RATE,
            default => $amount * self::DEFAULT_TAX_RATE,
        };
    }

    public function calculateShipping(float $weight): float
    {
        return $weight > self::HEAVY_WEIGHT_THRESHOLD
            ? self::HEAVY_SHIPPING_COST
            : self::STANDARD_SHIPPING_COST;
    }
}
```

Alternatively, use enums for related constants in PHP 8.3+:

```php
<?php

declare(strict_types=1);

enum TaxRate: float
{
    case US = 0.07;
    case EU = 0.21;
    case DEFAULT = 0.05;
}

class PricingCalculator
{
    public function calculateTax(float $amount, TaxRate $region): float
    {
        return $amount * $region->value;
    }
}
```

## Benefits

- **Improved Clarity**: Named constants reveal intent and make code self-documenting
- **Reduced Errors**: Single definition prevents inconsistencies from multiple changes
- **Easier Maintenance**: Changing values requires updates in only one place
- **Domain Alignment**: Constants reflect business logic and terminology
- **Better Debugging**: Named values appear in stack traces and debugging output
- **Type Safety**: Constants in enums provide compile-time type checking
- **Code Reviewability**: Intent becomes clear without additional comments

## When NOT to Use

- **True magic numbers**: Some numbers (e.g., loop counters from 0-2) are obvious and don't need constants
- **Array indices**: Using constants for array indices often adds unnecessary abstraction
- **Version numbers**: Sometimes embedded version strings are intentionally unexplained
- **Widely understood values**: Industry-standard values (e.g., HTTP 200) may not need constants
- **Overabstraction**: Excessive constant names for simple calculations can obscure rather than clarify

## Related Refactorings

- **Extract Variable**: Similar refactoring for extracting complex expressions into named variables
- **Introduce Parameter Object**: Groups related constants into a single object
- **Extract Class**: When many related magic numbers deserve a dedicated class
- **Replace Type Code with Subclasses**: Alternative for representing different numeric categories
- **Replace Magic Number with Symbolic Constant (Enum)**: PHP 8.3+ idiomatic approach using enums

## Examples in Other Languages

### Java

**Before:**
```java
double potentialEnergy(double mass, double height) {
  return mass * height * 9.81;
}
```

**After:**
```java
static final double GRAVITATIONAL_CONSTANT = 9.81;

double potentialEnergy(double mass, double height) {
  return mass * height * GRAVITATIONAL_CONSTANT;
}
```

### C#

**Before:**
```csharp
double PotentialEnergy(double mass, double height)
{
  return mass * height * 9.81;
}
```

**After:**
```csharp
const double GRAVITATIONAL_CONSTANT = 9.81;

double PotentialEnergy(double mass, double height)
{
  return mass * height * GRAVITATIONAL_CONSTANT;
}
```

### Python

**Before:**
```python
def potentialEnergy(mass, height):
    return mass * height * 9.81
```

**After:**
```python
GRAVITATIONAL_CONSTANT = 9.81

def potentialEnergy(mass, height):
    return mass * height * GRAVITATIONAL_CONSTANT
```

### TypeScript

**Before:**
```typescript
potentialEnergy(mass: number, height: number): number {
  return mass * height * 9.81;
}
```

**After:**
```typescript
static const GRAVITATIONAL_CONSTANT = 9.81;

potentialEnergy(mass: number, height: number): number {
  return mass * height * GRAVITATIONAL_CONSTANT;
}
```

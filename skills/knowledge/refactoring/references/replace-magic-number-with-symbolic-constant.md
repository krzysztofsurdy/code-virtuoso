## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Magic Number with Symbolic Constant swaps opaque numeric literals for named constants. A magic number is a raw value in the code with no hint of what it means, so readers cannot tell the intent and cannot safely change it. Named constants document the code and keep each value defined in one place.

## Motivation

### When to apply

- **Opaque numerics**: A numeric literal has no surrounding context to explain it
- **Duplicated values**: The same number appears in several places
- **Domain meaning**: The number encodes a business rule or domain concept
- **Configurable thresholds**: The value may change as requirements change
- **Ambiguous purpose**: Readers must guess or trace what a number means
- **Scattered updates**: Changing a value means searching the codebase for every occurrence

### Why it matters

Magic numbers hide purpose and make code brittle. When a value changes, every occurrence must be found and updated by hand. That is error-prone and invites inconsistencies. A named constant states the intent and puts the change in one definition.

## Mechanics

1. **Locate magic numbers**: Scan the codebase for unexplained numeric literals
2. **Determine meaning**: Work out what each number represents in the domain
3. **Pick a descriptive name**: Choose a constant name that conveys the value's role
4. **Declare the constant**: Define it as a class constant, global constant, or enum member
5. **Swap in the constant**: Replace every occurrence of the raw number with the named constant
6. **Confirm correctness**: Verify that behavior has not changed
7. **Check scope**: Give the constant the right visibility (local, class, or global)

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

Related constants can also go in an enum:

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

- **Clear intent**: Named constants say what each value means
- **Fewer inconsistencies**: One definition prevents updating some occurrences and missing others
- **Simpler maintenance**: A value change is a one-line edit
- **Domain alignment**: Constant names mirror business terminology
- **Debugging aid**: Named values show up in stack traces and debugging tools instead of anonymous numbers
- **Type safety**: Enum-based constants provide type validation in PHP 8.1+
- **Easier review**: Reviewers see the purpose without extra comments

## When NOT to use

- **Self-evident numbers**: Some values (for example, loop counters starting at 0 or 1) are understood by everyone and need no constant
- **Array indices**: Wrapping simple indices in constants often adds noise without adding clarity
- **Version strings**: Version identifiers are sometimes left inline on purpose
- **Industry conventions**: Widely recognized values (for example, HTTP status 200) rarely benefit from a named constant
- **Over-abstraction**: Naming every piece of trivial arithmetic can hide the logic

## Related Refactorings

- **Extract Variable**: A similar technique that moves complex expressions into descriptively named variables
- **Introduce Parameter Object**: Bundles related constants into one object
- **Extract Class**: Useful when a group of related magic numbers deserves its own class
- **Replace Type Code with Subclasses**: An alternative when numeric categories stand for distinct behaviors
- Backed enums (PHP 8.1+) are an alternative to class constants when the values form a closed set

## Examples in other languages

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

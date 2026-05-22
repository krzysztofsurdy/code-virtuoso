## Overview

Replace Magic Number with Symbolic Constant removes opaque numeric literals from code by introducing well-named constants in their place. Magic numbers are raw numeric values embedded throughout the codebase with no explanation of what they represent, making it difficult to understand intent or safely change values. Named constants turn the code into its own documentation and centralize value definitions for easier maintenance.

## Motivation

### When to Apply

- **Opaque numerics**: Numeric literals appear with no surrounding context to explain their meaning
- **Duplicated values**: The same number surfaces in multiple locations across the codebase
- **Domain-specific meaning**: Numbers encode business rules or domain concepts
- **Configurable thresholds**: Values that may shift as requirements evolve
- **Ambiguous purpose**: Readers must guess or trace what a particular number signifies
- **Scattered updates**: Modifying a value means hunting through the codebase for every occurrence

### Why It Matters

Magic numbers accumulate technical debt by concealing purpose and making code brittle. When a value needs to change, every occurrence must be located and updated individually - an error-prone process that invites inconsistencies. Named constants make the intent self-evident, centralize changes to a single definition, and reduce the chance of introducing bugs during maintenance.

## Mechanics: Step-by-Step

1. **Locate magic numbers**: Scan the codebase for unexplained numeric literals
2. **Determine semantics**: Figure out what each number represents within the domain
3. **Pick a descriptive name**: Choose a constant name that conveys the value's role
4. **Declare the constant**: Define it as a class constant, global constant, or enum member
5. **Swap in the constant**: Replace every occurrence of the raw number with the named constant
6. **Confirm correctness**: Verify that program behavior has not changed
7. **Evaluate scope**: Place the constant at the appropriate visibility level (local, class, or global)

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

- **Clarity of intent**: Named constants reveal what each value means, making the code self-explanatory
- **Fewer inconsistencies**: A single definition prevents errors that arise from updating some occurrences but missing others
- **Simpler maintenance**: Value changes require editing only one line
- **Domain alignment**: Constant names mirror business terminology
- **Debugging aid**: Named values appear in stack traces and debugging tools rather than anonymous numbers
- **Type safety**: Enum-based constants provide compile-time validation in PHP 8.1+
- **Review-friendliness**: Reviewers can understand purpose without needing extra comments

## When NOT to Use

- **Self-evident numbers**: Some values (e.g., loop counters starting at 0 or 1) are universally understood and need no constant
- **Array indices**: Wrapping simple indices in constants often adds noise without improving clarity
- **Version strings**: Embedded version identifiers are sometimes intentionally left inline
- **Industry conventions**: Universally recognized values (e.g., HTTP status 200) rarely benefit from a named constant
- **Over-abstraction**: Excessive naming for trivial arithmetic can obscure rather than illuminate

## Related Refactorings

- **Extract Variable**: A parallel technique that extracts complex expressions into descriptively named variables
- **Introduce Parameter Object**: Bundles related constants into a cohesive object
- **Extract Class**: Useful when a cluster of related magic numbers deserves its own class
- **Replace Type Code with Subclasses**: An alternative when numeric categories represent distinct behavioral variants
- **Replace Magic Number with Symbolic Constant (Enum)**: The idiomatic PHP 8.1+ approach using backed enums

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

## Overview

Extract Variable assigns a complex or opaque expression to a named variable, making the code's intent explicit. By giving a meaningful name to a sub-expression, you turn cryptic inline logic into self-documenting code that is easier to read, debug, and maintain.

This technique is especially valuable for compound conditionals, chained property accesses, and mathematical formulas where the purpose is not obvious at a glance.

## Motivation

**Clarity**: A descriptive variable name communicates what a value represents far more effectively than a raw expression.

**Maintenance**: When the same expression appears in multiple places, extracting it into a variable eliminates duplication and provides a single point of change.

**Debugging**: Named variables appear in debugger watches and stack traces, making it straightforward to inspect intermediate values.

**Reuse**: Once extracted, the variable can be referenced elsewhere in the same scope without recalculating the expression.

**Intent**: A well-chosen name acts as embedded documentation, explaining the "what" without needing a comment.

## Mechanics

1. **Locate the expression**: Find a complex or repeated expression that would benefit from a name
2. **Declare a variable**: Insert a variable declaration before the expression is first used
3. **Assign the expression**: Set the variable to the identified expression
4. **Choose a revealing name**: Pick a name that describes the value's meaning, not its computation
5. **Replace the expression**: Swap the original expression with the variable name
6. **Run the tests**: Confirm identical behavior
7. **Expand scope if needed**: Place the variable at the appropriate scope level (method, block, or class)
8. **Eliminate duplicates**: Replace all identical expressions with the new variable

## Before and After Examples

### Example 1: Conditional Logic

**Before (PHP 8.3+)**:
```php
class Order
{
    public function __construct(
        private float $subtotal,
        private float $taxRate,
        private float $discountRate,
    ) {}

    public function calculateTotal(): float
    {
        if ($this->subtotal > 100 && $this->subtotal * $this->taxRate > 15) {
            return $this->subtotal * (1 + $this->taxRate) * (1 - $this->discountRate);
        }
        return $this->subtotal;
    }
}
```

**After (PHP 8.3+)**:
```php
class Order
{
    public function __construct(
        private float $subtotal,
        private float $taxRate,
        private float $discountRate,
    ) {}

    public function calculateTotal(): float
    {
        $isBelowTaxThreshold = $this->subtotal > 100 && $this->subtotal * $this->taxRate > 15;

        if ($isBelowTaxThreshold) {
            $totalWithTax = $this->subtotal * (1 + $this->taxRate);
            return $totalWithTax * (1 - $this->discountRate);
        }

        return $this->subtotal;
    }
}
```

### Example 2: Property Chain

**Before (PHP 8.3+)**:
```php
class UserReport
{
    public function generateReport(User $user): string
    {
        return sprintf(
            "User: %s, Email: %s, City: %s",
            $user->profile->personalInfo->firstName,
            $user->profile->personalInfo->email,
            $user->address->location->city
        );
    }
}
```

**After (PHP 8.3+)**:
```php
class UserReport
{
    public function generateReport(User $user): string
    {
        $firstName = $user->profile->personalInfo->firstName;
        $email = $user->profile->personalInfo->email;
        $city = $user->address->location->city;

        return sprintf(
            "User: %s, Email: %s, City: %s",
            $firstName,
            $email,
            $city
        );
    }
}
```

### Example 3: Calculation

**Before (PHP 8.3+)**:
```php
class PricingCalculator
{
    public function calculateDiscount(float $price, int $quantity): float
    {
        if ($quantity > 10) {
            return $price * $quantity * 0.90;
        }
        if ($quantity > 5) {
            return $price * $quantity * 0.95;
        }
        return $price * $quantity;
    }
}
```

**After (PHP 8.3+)**:
```php
class PricingCalculator
{
    public function calculateDiscount(float $price, int $quantity): float
    {
        $baseTotal = $price * $quantity;

        if ($quantity > 10) {
            $discountRate = 0.90;
            return $baseTotal * $discountRate;
        }
        if ($quantity > 5) {
            $discountRate = 0.95;
            return $baseTotal * $discountRate;
        }
        return $baseTotal;
    }
}
```

## Benefits

- **Self-Documenting Code**: Names convey meaning that raw expressions do not
- **Simpler Expressions**: Breaking a formula into labeled parts makes each step obvious
- **Targeted Testing**: Individual variables can be inspected and asserted on
- **Single Point of Change**: A duplicated expression becomes a single assignment
- **Debugging Support**: Named values are easy to watch and log
- **Reduced Duplication**: Multiple uses of the same expression collapse into one variable

## When NOT to Use

- **Already clear expressions**: `$age = $currentYear - $birthYear` needs no further naming
- **Single-use with obvious meaning**: Extracting a one-time expression that is already readable adds verbosity
- **Tight performance loops**: In rare micro-optimization scenarios, an extra variable could matter - measure first
- **Arrow functions and pipelines**: Modern PHP or functional patterns may be more expressive than intermediate variables
- **Well-named helper methods already exist**: If a method already encapsulates the expression, a variable on top of it is redundant

## Related Refactorings

- **Extract Method**: When the extracted variable and its context form a logical unit worth naming as a method
- **Replace Temp with Query**: Converts a temporary variable into a method call for stronger encapsulation
- **Introduce Explaining Variable**: A specialized form of Extract Variable aimed at clarifying complex expressions
- **Rename Variable**: Complements this refactoring by ensuring the chosen name is optimal
- **Decompose Conditional**: Applies Extract Variable specifically to boolean expressions in conditionals

## Examples in Other Languages

### Java

**Before:**
```java
void renderBanner() {
  if ((platform.toUpperCase().indexOf("MAC") > -1) &&
       (browser.toUpperCase().indexOf("IE") > -1) &&
        wasInitialized() && resize > 0 )
  {
    // do something
  }
}
```

**After:**
```java
void renderBanner() {
  final boolean isMacOs = platform.toUpperCase().indexOf("MAC") > -1;
  final boolean isIE = browser.toUpperCase().indexOf("IE") > -1;
  final boolean wasResized = resize > 0;

  if (isMacOs && isIE && wasInitialized() && wasResized) {
    // do something
  }
}
```

### C#

**Before:**
```csharp
void RenderBanner()
{
  if ((platform.ToUpper().IndexOf("MAC") > -1) &&
       (browser.ToUpper().IndexOf("IE") > -1) &&
        wasInitialized() && resize > 0 )
  {
    // do something
  }
}
```

**After:**
```csharp
void RenderBanner()
{
  readonly bool isMacOs = platform.ToUpper().IndexOf("MAC") > -1;
  readonly bool isIE = browser.ToUpper().IndexOf("IE") > -1;
  readonly bool wasResized = resize > 0;

  if (isMacOs && isIE && wasInitialized() && wasResized)
  {
    // do something
  }
}
```

### Python

**Before:**
```python
def renderBanner(self):
    if (self.platform.toUpperCase().indexOf("MAC") > -1) and \
       (self.browser.toUpperCase().indexOf("IE") > -1) and \
       self.wasInitialized() and (self.resize > 0):
        # do something
```

**After:**
```python
def renderBanner(self):
    isMacOs = self.platform.toUpperCase().indexOf("MAC") > -1
    isIE = self.browser.toUpperCase().indexOf("IE") > -1
    wasResized = self.resize > 0

    if isMacOs and isIE and self.wasInitialized() and wasResized:
        # do something
```

### TypeScript

**Before:**
```typescript
renderBanner(): void {
  if ((platform.toUpperCase().indexOf("MAC") > -1) &&
       (browser.toUpperCase().indexOf("IE") > -1) &&
        wasInitialized() && resize > 0 )
  {
    // do something
  }
}
```

**After:**
```typescript
renderBanner(): void {
  const isMacOs = platform.toUpperCase().indexOf("MAC") > -1;
  const isIE = browser.toUpperCase().indexOf("IE") > -1;
  const wasResized = resize > 0;

  if (isMacOs && isIE && wasInitialized() && wasResized) {
    // do something
  }
}
```

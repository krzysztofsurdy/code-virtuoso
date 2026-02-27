## Overview

Extract Variable is a refactoring technique that replaces expressions or sub-expressions with a variable that has a meaningful name. This improves code readability by breaking down complex expressions into smaller, understandable components with self-documenting names.

The technique is particularly useful when dealing with complex conditional logic, mathematical operations, or object property chains where the intent is not immediately obvious from the expression itself.

## Motivation

**Improved Readability**: Complex expressions can be difficult to understand at a glance. Extracting them into named variables makes the intent clearer.

**Better Maintainability**: When an expression is used multiple times, extracting it to a variable reduces duplication and makes future changes easier.

**Easier Debugging**: Named variables make it simpler to set breakpoints and inspect values during debugging.

**Reusability**: Extracted variables can be reused elsewhere in the code, reducing duplication.

**Semantic Clarity**: A well-named variable acts as inline documentation, explaining what the value represents.

## Mechanics

Follow these step-by-step instructions to apply the Extract Variable refactoring:

1. **Identify the Expression**: Locate the complex expression or sub-expression that would benefit from a more meaningful name.

2. **Create a New Variable**: Insert a new variable declaration before the expression is used.

3. **Assign the Expression**: Assign the identified expression to the new variable.

4. **Name Meaningfully**: Choose a name that clearly describes what the expression calculates or represents.

5. **Replace Expression**: Replace the original expression with the new variable name.

6. **Test**: Verify that the code behaves identically after the refactoring.

7. **Consider Scope**: Ensure the variable is declared in the appropriate scope (method, block, or class level).

8. **Remove Duplication**: Replace all identical expressions with the newly extracted variable.

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

- **Enhanced Readability**: Code becomes self-documenting with clear, intention-revealing names
- **Reduced Complexity**: Breaking down complex expressions makes logic easier to follow
- **Easier Testing**: Extracted variables can be tested independently
- **Improved Maintenance**: Changes to calculations need to happen in only one place
- **Better Debugging**: Named variables allow for easier inspection and breakpoint setting
- **Code Reusability**: Extracted variables eliminate duplication when expressions are used multiple times

## When NOT to Use

- **Simple Expressions**: If the expression is already clear and self-documenting (e.g., `$age = $currentYear - $birthYear`), extraction may add unnecessary verbosity
- **One-Time Use**: Extracting variables used only once may reduce readability unless the expression is complex
- **Performance-Critical Code**: In tight loops where micro-optimizations matter, introduce variables cautiously
- **Inline Functions**: With modern PHP, inline arrow functions might be more appropriate than variables for certain transformations
- **Already Refactored**: If the code is already using well-named helper methods, further variable extraction may be redundant

## Related Refactorings

- **Extract Method**: When extracted variables form a logical unit, consider extracting a method instead
- **Replace Temp with Query**: Convert temporary variables into method calls for better encapsulation
- **Introduce Explaining Variable**: A specialized form of Extract Variable focused on breaking down complex expressions
- **Rename Variable**: Complement this refactoring by ensuring variables have optimal names
- **Decompose Conditional**: Use this technique to simplify complex conditional statements

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

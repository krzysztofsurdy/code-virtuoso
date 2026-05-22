## Overview

Introduce Assertion replaces implicit assumptions and undocumented preconditions with explicit assertion statements. Rather than relying on comments or hoping developers will remember constraints, assertions turn assumptions into executable checks that fail fast when violated.

Assertions bridge the gap between documentation and code - they verify that conditions necessary for correct execution actually hold before the code proceeds.

## Motivation

Code frequently depends on conditions that are never stated outright. These assumptions may be:

- Buried in comments that fall out of date
- Implied by the logic, invisible to anyone reading the code for the first time
- Silently violated during maintenance or refactoring, leading to subtle bugs

Expressing these assumptions as assertions:

- Makes preconditions discoverable and verifiable
- Surfaces programmer errors during development and testing rather than in production
- Creates documentation that is always accurate because it runs with the code
- Strengthens confidence that the code operates within its expected boundaries

## Mechanics

1. Identify comments or implicit logic that describe conditions the code requires
2. Locate the code that depends on those conditions
3. Insert assertion statements that verify the conditions before they are relied upon
4. Confirm that assertions do not change program behavior when conditions are met
5. Optionally disable assertions in production if performance is a concern

## Before/After (PHP 8.3+ Code)

### Before

```php
class Invoice
{
    private float $discountPercentage;

    public function setDiscount(float $discount): void
    {
        // Discount must be between 0 and 100
        $this->discountPercentage = $discount;
    }

    public function calculateTotal(float $subtotal): float
    {
        // Assuming discount is valid here
        return $subtotal * (1 - $this->discountPercentage / 100);
    }
}

class User
{
    public function getAge(): int
    {
        // User must be 18 or older to access this resource
        return $this->age;
    }
}
```

### After

```php
class Invoice
{
    private float $discountPercentage;

    public function setDiscount(float $discount): void
    {
        assert($discount >= 0 && $discount <= 100, 'Discount must be between 0 and 100');
        $this->discountPercentage = $discount;
    }

    public function calculateTotal(float $subtotal): float
    {
        assert($this->discountPercentage >= 0 && $this->discountPercentage <= 100);
        return $subtotal * (1 - $this->discountPercentage / 100);
    }
}

class User
{
    public function getAge(): int
    {
        assert($this->age >= 18, 'Only users 18+ can access this resource');
        return $this->age;
    }

    public function processPayment(float $amount): void
    {
        assert($amount > 0, 'Payment amount must be positive');
        assert($this->isVerified, 'User must be verified before processing payment');

        // Process payment with confidence that preconditions are met
    }
}
```

### With PHP 8.3+ Attributes (Optional)

```php
#[Validate(min: 0, max: 100)]
public function setDiscount(float $discount): void
{
    assert($discount >= 0 && $discount <= 100);
    $this->discountPercentage = $discount;
}
```

## Benefits

- **Immediate Failure**: Violations surface at the point of origin rather than propagating through the system
- **Executable Documentation**: Assertions cannot become stale because they run alongside the code
- **Precise Diagnostics**: Assertion messages pinpoint exactly which assumption was violated and where
- **Developer Confidence**: Knowing that preconditions are enforced makes it safer to build on existing logic
- **Gap Identification**: Writing assertions reveals untested paths and overlooked edge cases
- **Less Defensive Clutter**: With preconditions guaranteed, downstream code can drop redundant null checks and type guards

## When NOT to Use

- **User input**: Assertions are for programmer errors, not user mistakes; validate user input with exceptions
- **Expected failures**: If a condition can legitimately fail at runtime, use proper error handling
- **Non-essential checks**: Do not assert conditions that are merely desirable but not required for correctness
- **Performance-sensitive paths**: Assertions may be disabled in production; do not use them for security-critical validation
- **Third-party boundaries**: At integration points with external systems, use validation and exceptions instead

## Related Refactorings

- **Extract Method**: Isolates assertion logic when precondition checks become complex
- **Guard Clauses**: Complement assertions by handling expected variations in input
- **Replace Error Code with Exception**: The appropriate pattern when failure stems from external sources
- **Introduce Parameter Object**: Consolidates parameters and makes their constraints easier to assert

## Examples in Other Languages

### Java

**Before:**
```java
double getExpenseLimit() {
  // Should have either expense limit or
  // a primary project.
  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit :
    primaryProject.getMemberExpenseLimit();
}
```

**After:**
```java
double getExpenseLimit() {
  Assert.isTrue(expenseLimit != NULL_EXPENSE || primaryProject != null);

  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit:
    primaryProject.getMemberExpenseLimit();
}
```

### C#

**Before:**
```csharp
double GetExpenseLimit()
{
  // Should have either expense limit or
  // a primary project.
  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit :
    primaryProject.GetMemberExpenseLimit();
}
```

**After:**
```csharp
double GetExpenseLimit()
{
  Assert.IsTrue(expenseLimit != NULL_EXPENSE || primaryProject != null);

  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit:
    primaryProject.GetMemberExpenseLimit();
}
```

### Python

**Before:**
```python
def getExpenseLimit(self):
    # Should have either expense limit or
    # a primary project.
    return self.expenseLimit if self.expenseLimit != NULL_EXPENSE else \
        self.primaryProject.getMemberExpenseLimit()
```

**After:**
```python
def getExpenseLimit(self):
    assert (self.expenseLimit != NULL_EXPENSE) or (self.primaryProject != None)

    return self.expenseLimit if (self.expenseLimit != NULL_EXPENSE) else \
        self.primaryProject.getMemberExpenseLimit()
```

### TypeScript

**Before:**
```typescript
getExpenseLimit(): number {
  // Should have either expense limit or
  // a primary project.
  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit:
    primaryProject.getMemberExpenseLimit();
}
```

**After:**
```typescript
getExpenseLimit(): number {
  if (!(expenseLimit != NULL_EXPENSE ||
       (typeof primaryProject !== 'undefined' && primaryProject))) {
      console.error("Assertion failed: getExpenseLimit()");
  }

  return (expenseLimit != NULL_EXPENSE) ?
    expenseLimit:
    primaryProject.getMemberExpenseLimit();
}
```

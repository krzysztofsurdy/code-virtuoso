## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+ code)](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Introduce Assertion replaces implicit assumptions and undocumented preconditions with explicit assertion statements. Instead of relying on comments or on developers remembering constraints, assertions turn assumptions into executable checks that fail fast when violated.

An assertion is documentation that runs. It verifies that the conditions required for correct execution hold before the code proceeds.

## Motivation

Code often depends on conditions that are never stated. These assumptions may be:

- Buried in comments that fall out of date
- Implied by the logic, invisible to anyone reading the code for the first time
- Violated during maintenance or refactoring without anyone noticing, which causes subtle bugs

Writing these assumptions as assertions:

- Makes preconditions easy to find and verify
- Surfaces programmer errors during development and testing, not in production
- Gives you documentation that stays accurate because it runs with the code
- Shows when the code leaves its expected boundaries

## Mechanics

1. Identify comments or implicit logic that describe conditions the code requires
2. Locate the code that depends on those conditions
3. Insert assertion statements that verify the conditions before they are relied upon
4. Confirm that assertions do not change program behavior when conditions are met
5. If performance is a concern, disable assertions in production

## Before and after (PHP 8.3+ code)

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

### With PHP 8.3+ attributes (optional)

```php
#[Validate(min: 0, max: 100)]
public function setDiscount(float $discount): void
{
    assert($discount >= 0 && $discount <= 100);
    $this->discountPercentage = $discount;
}
```

## Benefits

- **Immediate failure**: Violations surface where they start, not further down the system
- **Executable documentation**: Assertions cannot go stale because they run with the code
- **Precise diagnostics**: Assertion messages name the assumption that failed and where
- **Safer changes**: Enforced preconditions make it safer to build on existing logic
- **Gap finding**: Writing assertions reveals untested paths and overlooked edge cases
- **Less defensive clutter**: With preconditions guaranteed, downstream code can drop redundant null checks and type guards

## When not to use

- **User input**: Assertions are for programmer errors, not user mistakes; validate user input with exceptions
- **Expected failures**: If a condition can legitimately fail at runtime, use normal error handling
- **Non-essential checks**: Do not assert conditions that are desirable but not required for correctness
- **Performance-sensitive paths**: Assertions may be disabled in production, so do not use them for security-critical validation
- **Third-party boundaries**: At integration points with external systems, use validation and exceptions instead

## Related refactorings

- **Extract Method**: Isolates assertion logic when precondition checks become complex
- **Guard Clauses**: Handle expected variations in input and complement assertions
- **Replace Error Code with Exception**: The right choice when failure comes from external sources
- **Introduce Parameter Object**: Groups parameters so their constraints are easier to assert

## Examples in other languages

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

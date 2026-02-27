## Overview

The Introduce Assertion refactoring replaces implicit assumptions and undocumented preconditions with explicit assertion statements. Rather than relying on comments or hoping developers remember requirements, assertions make assumptions visible, testable, and executable.

Assertions serve as a bridge between documentation and code—they verify that conditions necessary for correct execution are actually met before proceeding.

## Motivation

Code often depends on specific conditions being true for correct execution. These assumptions may be:

- Only documented in comments that can become outdated
- Implicit in the logic, making them invisible to future developers
- Vulnerable to being violated during maintenance or refactoring

By introducing assertions, you:

- Make assumptions explicit and verifiable
- Catch programmer errors early in development and testing
- Create executable documentation that cannot become stale
- Improve code reliability and maintainability

## Mechanics

1. Identify comments describing conditions necessary for the code to work correctly
2. Locate the code that depends on these conditions
3. Add assertion statements that verify these conditions before they're relied upon
4. Ensure assertions don't alter program behavior when conditions are met
5. Consider removing assertions in production code if performance is critical

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

- **Early Failure Detection**: Assertions catch violations immediately rather than allowing corrupt data to propagate
- **Live Documentation**: Assertions serve as executable specifications that cannot become outdated
- **Improved Debugging**: Clear assertion messages pinpoint exactly what assumption was violated
- **Code Confidence**: Developers can rely on preconditions being met throughout method execution
- **Test Coverage**: Assertions help identify untested code paths and edge cases
- **Reduced Defensive Programming**: Less need for excessive null checks and type guards when preconditions are guaranteed

## When NOT to Use

- **User Input Validation**: Use exceptions and validation instead—users can trigger assertion failures through bad input
- **Expected Error Conditions**: If an exception can be caused by system actions, use proper exception handling
- **Non-Critical Conditions**: Don't assert conditions that are nice-to-have but not essential for correctness
- **Performance-Critical Code**: Assertions can be disabled in production; rely on them only for development/testing
- **External API Contracts**: For third-party integrations, use validation and exceptions instead of assertions

## Related Refactorings

- **Extract Method**: Often used alongside Introduce Assertion to isolate assumptions in separate methods
- **Guard Clauses**: Complement assertions by handling valid variations of preconditions
- **Replace Error Code with Exception**: Alternative when failure is expected from external sources
- **Introduce Parameter Object**: Reduces parameter count and makes preconditions clearer

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

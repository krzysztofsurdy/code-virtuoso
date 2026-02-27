## Overview

Consolidate Conditional Expression is a refactoring technique that combines multiple conditional statements that lead to the same action or result into a single, unified conditional expression. This eliminates code duplication and makes the logic more transparent and easier to understand at a glance.

## Motivation

Multiple conditional statements checking different conditions but performing the same action suggest that the underlying logic can be simplified. This pattern emerges when:

- Several `if` statements have the same action but different conditions
- Multiple conditions are combined with `||` (OR) operators vertically
- The code becomes harder to understand because the intent is obscured by repetition
- Maintenance becomes error-prone as changes must be applied to multiple similar conditions

Consolidating these expressions:
- Reduces cognitive load by presenting the intent clearly
- Decreases the chance of inconsistencies when modifying the logic
- Makes the code more maintainable and testable
- Improves readability by grouping related conditions

## Mechanics

### Step 1: Identify Candidates
Look for multiple conditional statements with identical bodies (actions/results). The conditions may differ, but they must execute the same code.

### Step 2: Extract Conditions
Combine the conditions using logical operators (`&&`, `||`, `and`, `or`). Ensure the combined expression is logically equivalent to the original separate conditions.

### Step 3: Replace with Single Statement
Replace all original conditional statements with a single consolidated conditional that combines the conditions appropriately.

### Step 4: Test
Verify that all test cases pass and the behavior remains identical to the original implementation.

## Before/After Examples

### Example 1: Multiple OR Conditions

**Before:**
```php
<?php

class UserValidator
{
    public function isDisqualified(User $user): bool
    {
        if ($user->isSuspended()) {
            return true;
        }
        if ($user->isBanned()) {
            return true;
        }
        if ($user->isInactive()) {
            return true;
        }

        return false;
    }
}
```

**After (PHP 8.3+):**
```php
<?php

class UserValidator
{
    public function isDisqualified(User $user): bool
    {
        return $user->isSuspended() ||
               $user->isBanned() ||
               $user->isInactive();
    }
}
```

### Example 2: Complex Conditions

**Before:**
```php
<?php

class PriceCalculator
{
    public function getDiscount(Order $order): float
    {
        if ($order->getTotalAmount() > 1000 && $order->isVIP()) {
            return 0.20;
        }
        if ($order->getTotalAmount() > 5000) {
            return 0.20;
        }
        if ($order->isLoyaltyMember() && $order->getPreviousOrders() > 10) {
            return 0.20;
        }

        return 0.0;
    }
}
```

**After (PHP 8.3+):**
```php
<?php

class PriceCalculator
{
    public function getDiscount(Order $order): float
    {
        if ($this->qualifiesForPremiumDiscount($order)) {
            return 0.20;
        }

        return 0.0;
    }

    private function qualifiesForPremiumDiscount(Order $order): bool
    {
        return ($order->getTotalAmount() > 1000 && $order->isVIP()) ||
               $order->getTotalAmount() > 5000 ||
               ($order->isLoyaltyMember() && $order->getPreviousOrders() > 10);
    }
}
```

### Example 3: With Match Expression (PHP 8.0+)

**Before:**
```php
<?php

class StatusHandler
{
    public function handleRequest(Request $request): string
    {
        if ($request->isAdmin()) {
            return 'admin-dashboard';
        }
        if ($request->isModerator()) {
            return 'admin-dashboard';
        }
        if ($request->isEditorWithPermissions()) {
            return 'admin-dashboard';
        }

        return 'user-dashboard';
    }
}
```

**After (PHP 8.0+ with match):**
```php
<?php

class StatusHandler
{
    public function handleRequest(Request $request): string
    {
        return ($request->isAdmin() ||
                $request->isModerator() ||
                $request->isEditorWithPermissions())
            ? 'admin-dashboard'
            : 'user-dashboard';
    }
}
```

## Benefits

1. **Improved Readability**: The intent becomes immediately obvious - multiple conditions lead to one outcome
2. **Reduced Duplication**: Eliminates redundant code blocks
3. **Easier Maintenance**: Changes to the logic only need to be made in one place
4. **Better Testability**: Simpler expressions are easier to unit test
5. **Performance**: Potentially faster as the logic can be optimized more effectively
6. **Clearer Intent**: Makes it explicit which conditions are alternatives rather than sequential steps

## When NOT to Use

- **Sequential Dependencies**: When conditions must be evaluated in a specific order (one condition affects the next)
- **Side Effects**: When conditions have side effects (e.g., logging, state changes) that must occur in a specific order
- **Complex Logic**: When consolidation makes the expression too complex or difficult to understand
- **Performance Critical**: When short-circuit evaluation order matters for performance
- **Debugging**: When separating conditions aids in debugging and testing individual branches

## Related Refactorings

- **Extract Method**: Extract consolidated condition into a named method for better readability
- **Consolidate Duplicate Conditional Fragments**: Similar concept but applied to code blocks after conditions
- **Replace Nested Conditionals with Guard Clauses**: Simplify deeply nested conditions
- **Decompose Conditional**: Break complex conditions into easier-to-understand parts
- **Replace Conditional with Polymorphism**: For complex conditional logic based on type

## Examples in Other Languages

### Java

**Before:**
```java
double disabilityAmount() {
  if (seniority < 2) {
    return 0;
  }
  if (monthsDisabled > 12) {
    return 0;
  }
  if (isPartTime) {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

**After:**
```java
double disabilityAmount() {
  if (isNotEligibleForDisability()) {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

### C#

**Before:**
```csharp
double DisabilityAmount()
{
  if (seniority < 2)
  {
    return 0;
  }
  if (monthsDisabled > 12)
  {
    return 0;
  }
  if (isPartTime)
  {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

**After:**
```csharp
double DisabilityAmount()
{
  if (IsNotEligibleForDisability())
  {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

### Python

**Before:**
```python
def disabilityAmount():
    if seniority < 2:
        return 0
    if monthsDisabled > 12:
        return 0
    if isPartTime:
        return 0
    # Compute the disability amount.
    # ...
```

**After:**
```python
def disabilityAmount():
    if isNotEligibleForDisability():
        return 0
    # Compute the disability amount.
    # ...
```

### TypeScript

**Before:**
```typescript
disabilityAmount(): number {
  if (seniority < 2) {
    return 0;
  }
  if (monthsDisabled > 12) {
    return 0;
  }
  if (isPartTime) {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

**After:**
```typescript
disabilityAmount(): number {
  if (isNotEligibleForDisability()) {
    return 0;
  }
  // Compute the disability amount.
  // ...
}
```

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after](#before-and-after)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Consolidate Conditional Expression merges several conditional checks that produce the same outcome into one expression. This removes repetition and shows the shared intent behind the checks.

## Motivation

When several `if` statements guard the same return value or action, the conditions are related: they all represent the same decision. Leaving them separate:

- Hides the fact that they share a single purpose
- Risks inconsistent updates when the action changes
- Adds visual noise that makes the method harder to scan
- Complicates testing with extra branches that lead to identical outcomes

Putting the conditions into one expression, or one well-named method, joins both the logic and the intent.

## Mechanics

### Step 1: Identify candidates
Find conditional statements whose bodies perform the same action or return the same value.

### Step 2: Combine conditions
Join the individual conditions with logical operators (`&&`, `||`). Verify the combined expression is logically equivalent to the originals.

### Step 3: Replace with a single statement
Replace the separate conditionals with one check. If the combined expression is complex, extract it into a named method.

### Step 4: Test
Run the test suite to confirm behavior is unchanged.

## Before and after

### Example 1: Multiple OR conditions

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

### Example 2: Complex conditions

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

### Example 3: Match expression (PHP 8.0+)

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

1. **Clearer intent**: A single expression shows that several conditions share one purpose
2. **Less duplication**: The repeated action or return value appears once
3. **Focused maintenance**: Changing the outcome means editing one place
4. **Simpler testing**: Fewer branches mean fewer test paths
5. **Room for naming**: Extracting the combined condition into a method gives it a meaningful name
6. **Obvious alternatives**: The conditions are visibly interchangeable paths to the same result

## When NOT to use

- **Order-dependent evaluation**: When conditions must run in sequence because earlier checks affect later ones
- **Side effects**: When individual conditions trigger logging, state changes, or other effects that need to happen independently
- **Unreadable result**: Combining the conditions makes the expression harder to read than separate checks
- **Performance-sensitive short-circuiting**: Evaluation order matters for performance
- **Debugging needs**: Separate conditions help pinpoint which path was taken

## Related refactorings

- **Extract Method**: Move the consolidated condition into a named method for readability
- **Consolidate Duplicate Conditional Fragments**: A sibling technique that removes duplicated code inside conditional branches
- **Replace Nested Conditionals with Guard Clauses**: Flatten deeply nested conditions
- **Decompose Conditional**: Break a complex condition into smaller, named pieces
- **Replace Conditional with Polymorphism**: Use objects instead of conditionals for type-based logic

## Examples in other languages

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

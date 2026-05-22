## Overview

Consolidate Conditional Expression merges multiple conditional checks that all produce the same outcome into a single, unified expression. This removes repetition and makes the shared intent behind those checks immediately visible.

## Motivation

When several `if` statements guard the same return value or action, the code is telling you that these conditions are conceptually related - they all represent the same decision. Leaving them separate:

- Obscures the fact that they share a single purpose
- Increases the risk of inconsistent updates when the action changes
- Adds visual noise that makes the method harder to scan
- Complicates testing by multiplying branches that lead to identical outcomes

Bringing the conditions together into one expression (or one well-named method) consolidates both the logic and the intent.

## Mechanics

### Step 1: Identify Candidates
Find multiple conditional statements whose bodies perform the same action or return the same value.

### Step 2: Extract Conditions
Combine the individual conditions using logical operators (`&&`, `||`). Verify the combined expression is logically equivalent to the originals.

### Step 3: Replace with Single Statement
Swap out the separate conditionals for one consolidated check. If the combined expression is complex, extract it into a named method.

### Step 4: Test
Run the full test suite to confirm behavior is unchanged.

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

1. **Clearer Intent**: A single expression communicates that multiple conditions share one purpose
2. **Less Duplication**: The repeated action or return value appears only once
3. **Focused Maintenance**: Changing the outcome requires editing a single location
4. **Simpler Testing**: Fewer branches means fewer test paths to cover
5. **Potential for Naming**: Extracting the combined condition into a method gives it a meaningful name
6. **Obvious Alternatives**: It becomes clear that the conditions are interchangeable paths to the same result

## When NOT to Use

- **Order-dependent evaluation**: When conditions must run in sequence because earlier checks affect later ones
- **Side effects**: When individual conditions trigger logging, state changes, or other effects that need to happen independently
- **Resulting expression is unreadable**: If combining conditions makes the expression harder to understand than separate checks
- **Performance-sensitive short-circuiting**: When evaluation order matters for performance reasons
- **Debugging needs**: When separate conditions help pinpoint which specific path was taken during troubleshooting

## Related Refactorings

- **Extract Method**: Pull the consolidated condition into a named method for readability
- **Consolidate Duplicate Conditional Fragments**: A sibling technique for deduplicating code inside conditional branches
- **Replace Nested Conditionals with Guard Clauses**: Flatten deeply nested conditions
- **Decompose Conditional**: Break an overly complex condition into smaller, named pieces
- **Replace Conditional with Polymorphism**: Use objects instead of conditionals for type-based logic

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

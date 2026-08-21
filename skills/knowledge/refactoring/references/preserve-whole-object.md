# Preserve Whole Object

## Overview

Preserve Whole Object passes an entire object as a method argument instead of pulling values out of it first. A caller sometimes extracts several fields from an object only to hand them to another method. Passing the object itself simplifies the call site and keeps the extraction logic in one place.

Instead of:
```php
$low = $daysTempRange->getLow();
$high = $daysTempRange->getHigh();
$withinPlan = $plan->withinRange($low, $high);
```

Pass the whole object:
```php
$withinPlan = $plan->withinRange($daysTempRange);
```

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after: PHP 8.3+ code](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Extracting several values from an object at every call site is repetitive and fragile. If the receiving method later needs one more value, every caller must change to extract and pass it. When the method receives the whole object, it can read what it needs. Callers stay the same when requirements change.

- **Less boilerplate**: no repeated extraction of values before method calls
- **Easier maintenance**: a change in what data a method needs touches one place
- **Simpler call sites**: method calls are shorter and easier to read

## Mechanics

1. **Identify the pattern**: find methods that receive several values extracted from the same object.
2. **Add a new parameter**: add a parameter that accepts the whole object.
3. **Update the method body**: replace the value parameters with method calls on the object.
4. **Update call sites**: pass the whole object instead of the extracted values.
5. **Remove old parameters**: delete the individual value parameters that are no longer used.
6. **Test**: check that every call site works with the change.

## Before and after: PHP 8.3+ code

### Before
```php
class Account
{
    public function withinCreditLimit(int $minBalance, int $maxBalance): bool
    {
        return $this->balance >= $minBalance && $this->balance <= $maxBalance;
    }
}

class Client
{
    public function checkCredit(): void
    {
        $account = new Account();
        $limit = new CreditLimit(1000, 5000);

        // Extracting values before passing them
        $min = $limit->getMinimum();
        $max = $limit->getMaximum();

        if ($account->withinCreditLimit($min, $max)) {
            echo "Credit OK\n";
        }
    }
}
```

### After
```php
class CreditLimit
{
    public function __construct(
        private readonly int $minimum,
        private readonly int $maximum,
    ) {}

    public function getMinimum(): int
    {
        return $this->minimum;
    }

    public function getMaximum(): int
    {
        return $this->maximum;
    }
}

class Account
{
    public function __construct(
        private readonly int $balance = 2500,
    ) {}

    // Pass the whole object instead of individual values
    public function withinCreditLimit(CreditLimit $limit): bool
    {
        return $this->balance >= $limit->getMinimum()
            && $this->balance <= $limit->getMaximum();
    }
}

class Client
{
    public function checkCredit(): void
    {
        $account = new Account();
        $limit = new CreditLimit(1000, 5000);

        // Cleaner call site - pass whole object
        if ($account->withinCreditLimit($limit)) {
            echo "Credit OK\n";
        }
    }
}
```

## Benefits

- **Shorter parameter lists**: method signatures are short and self-explanatory.
- **Resilient to change**: the receiving method can use more data without changing callers.
- **Less duplication**: extraction logic lives inside the method, not at every call site.
- **Stronger abstractions**: parameters express domain concepts instead of raw primitives.
- **Simpler call sites**: callers pass one object instead of several extracted values.

## When not to use

- **Crossing a domain boundary**: when data crosses an architectural boundary (e.g., API responses), passing the whole object may expose internal structure.
- **Multiple source objects**: if the values come from different objects, combining them into one artificial object may violate single responsibility.
- **Primitive-only methods**: a method that expects only simple types may become too coupled to a specific object structure.
- **Primitive Obsession anti-pattern**: do not create wrapper objects just to avoid primitive parameters.
- **Data Transfer Objects**: for DTOs or value objects passed across services, individual properties may be a better fit.

## Related refactorings

- **Introduce Parameter Object**: creates a new object to group related parameters. Often used before Preserve Whole Object.
- **Extract Class**: helps identify cohesive data that should be passed together.
- **Encapsulate Query**: hides data access logic inside objects.
- **Replace Parameter with Query**: removes parameters by querying for values inside the method.

## Examples in other languages

### Java

**Before:**
```java
int low = daysTempRange.getLow();
int high = daysTempRange.getHigh();
boolean withinPlan = plan.withinRange(low, high);
```

**After:**
```java
boolean withinPlan = plan.withinRange(daysTempRange);
```

### C#

**Before:**
```csharp
int low = daysTempRange.GetLow();
int high = daysTempRange.GetHigh();
bool withinPlan = plan.WithinRange(low, high);
```

**After:**
```csharp
bool withinPlan = plan.WithinRange(daysTempRange);
```

### Python

**Before:**
```python
low = daysTempRange.getLow()
high = daysTempRange.getHigh()
withinPlan = plan.withinRange(low, high)
```

**After:**
```python
withinPlan = plan.withinRange(daysTempRange)
```

### TypeScript

**Before:**
```typescript
let low = daysTempRange.getLow();
let high = daysTempRange.getHigh();
let withinPlan = plan.withinRange(low, high);
```

**After:**
```typescript
let withinPlan = plan.withinRange(daysTempRange);
```

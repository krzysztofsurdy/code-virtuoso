## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After: PHP 8.3+ code](#beforeafter-php-83-code)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Nested Conditional with Guard Clauses flattens deeply nested if-else trees into a linear sequence of guard clauses. A guard clause is an early return or throw that handles a special case before the main logic runs. This removes the "pyramid of doom", where each nesting level pushes the code further right and makes it harder to read.

## Motivation

Deeply nested conditionals cause several problems:

- **Hidden intent**: The core logic is buried under layers of indentation, and readers must track several branches at once
- **Look of ad-hoc growth**: Heavy nesting often means conditions were added as needed instead of designed
- **Mental load**: Each nesting level adds context the reader must hold, which slows reading
- **Harder testing**: Deeply branching paths multiply the scenarios that need coverage
- **More defects**: Complex conditional structures breed off-by-one errors and missed edge cases

Guard clauses handle all boundary conditions at the top of the method. The main ("happy") path then runs unindented and uninterrupted.

## Mechanics

1. **Spot guard conditions**: Identify branches that end in early returns, throws, or other exits
2. **Hoist to the top**: Move these guard clauses to the start of the method
3. **Flatten the structure**: Turn nested if-else trees into a sequence of independent if statements
4. **Drop the else blocks**: Let the guard clause returns make the else branches unnecessary
5. **Merge where possible**: Combine related guard conditions with logical operators when that improves clarity

## Before/After: PHP 8.3+ code

### Before (nested conditionals)

```php
public function calculateSalary(Employee $employee): float
{
    if ($employee->isActive()) {
        if ($employee->getYearsOfService() > 5) {
            if ($employee->getDepartment() === 'Executive') {
                return $employee->getBaseSalary() * 1.2;
            } else {
                return $employee->getBaseSalary() * 1.1;
            }
        } else {
            return $employee->getBaseSalary();
        }
    } else {
        return 0;
    }
}
```

### After (guard clauses)

```php
public function calculateSalary(Employee $employee): float
{
    if (!$employee->isActive()) {
        return 0;
    }

    if ($employee->getYearsOfService() <= 5) {
        return $employee->getBaseSalary();
    }

    if ($employee->getDepartment() === 'Executive') {
        return $employee->getBaseSalary() * 1.2;
    }

    return $employee->getBaseSalary() * 1.1;
}
```

### Complex example with early exits

```php
// Before
public function processOrder(Order $order, Customer $customer): void
{
    if ($order->isValid()) {
        if ($customer->hasValidPayment()) {
            if ($this->inventoryService->hasStock($order->getItems())) {
                $this->executePayment($order, $customer);
                $this->updateInventory($order->getItems());
                $this->sendConfirmation($customer);
            } else {
                throw new OutOfStockException();
            }
        } else {
            throw new PaymentException();
        }
    } else {
        throw new InvalidOrderException();
    }
}

// After
public function processOrder(Order $order, Customer $customer): void
{
    if (!$order->isValid()) {
        throw new InvalidOrderException();
    }

    if (!$customer->hasValidPayment()) {
        throw new PaymentException();
    }

    if (!$this->inventoryService->hasStock($order->getItems())) {
        throw new OutOfStockException();
    }

    $this->executePayment($order, $customer);
    $this->updateInventory($order->getItems());
    $this->sendConfirmation($customer);
}
```

## Benefits

- **Linear reading**: Code runs top to bottom with little indentation
- **Visible preconditions**: Guard clauses show boundary handling at the start
- **Isolated test paths**: Each guard and the main path can be tested independently
- **Lower maintenance cost**: Future developers grasp the method's logic quickly
- **Less mental load**: No need to track which else belongs to which if
- **Fewer temporary variables**: No result variables used only to route through conditionals

## When NOT to use

This refactoring may not fit when:

- **Tightly coupled conditions**: If conditions depend on each other's results, polymorphism may be more appropriate
- **Rich domain logic**: For substantial business rules, consider **Replace Conditional with Polymorphism** instead
- **Binary success or failure**: With exactly one success path and one failure path, a plain if-else is already clear
- **Performance-sensitive loops**: Early exits through exceptions have a cost; use them sparingly in tight iterations

## Related Refactorings

- **Decompose Conditional**: Extract complex boolean expressions into named methods
- **Replace Conditional with Polymorphism**: Use inheritance or interfaces when decision trees encode type-based behavior
- **Extract Method**: Move guard clause logic into helper methods
- **Consolidate Duplicate Conditional Fragments**: Merge guard clauses that lead to the same outcome

## Examples in other languages

### Java

**Before:**
```java
public double getPayAmount() {
  double result;
  if (isDead){
    result = deadAmount();
  }
  else {
    if (isSeparated){
      result = separatedAmount();
    }
    else {
      if (isRetired){
        result = retiredAmount();
      }
      else{
        result = normalPayAmount();
      }
    }
  }
  return result;
}
```

**After:**
```java
public double getPayAmount() {
  if (isDead){
    return deadAmount();
  }
  if (isSeparated){
    return separatedAmount();
  }
  if (isRetired){
    return retiredAmount();
  }
  return normalPayAmount();
}
```

### C#

**Before:**
```csharp
public double GetPayAmount()
{
  double result;

  if (isDead)
  {
    result = DeadAmount();
  }
  else
  {
    if (isSeparated)
    {
      result = SeparatedAmount();
    }
    else
    {
      if (isRetired)
      {
        result = RetiredAmount();
      }
      else
      {
        result = NormalPayAmount();
      }
    }
  }

  return result;
}
```

**After:**
```csharp
public double GetPayAmount()
{
  if (isDead)
  {
    return DeadAmount();
  }
  if (isSeparated)
  {
    return SeparatedAmount();
  }
  if (isRetired)
  {
    return RetiredAmount();
  }
  return NormalPayAmount();
}
```

### Python

**Before:**
```python
def getPayAmount(self):
    if self.isDead:
        result = deadAmount()
    else:
        if self.isSeparated:
            result = separatedAmount()
        else:
            if self.isRetired:
                result = retiredAmount()
            else:
                result = normalPayAmount()
    return result
```

**After:**
```python
def getPayAmount(self):
    if self.isDead:
        return deadAmount()
    if self.isSeparated:
        return separatedAmount()
    if self.isRetired:
        return retiredAmount()
    return normalPayAmount()
```

### TypeScript

**Before:**
```typescript
getPayAmount(): number {
  let result: number;
  if (isDead){
    result = deadAmount();
  }
  else {
    if (isSeparated){
      result = separatedAmount();
    }
    else {
      if (isRetired){
        result = retiredAmount();
      }
      else{
        result = normalPayAmount();
      }
    }
  }
  return result;
}
```

**After:**
```typescript
getPayAmount(): number {
  if (isDead){
    return deadAmount();
  }
  if (isSeparated){
    return separatedAmount();
  }
  if (isRetired){
    return retiredAmount();
  }
  return normalPayAmount();
}
```

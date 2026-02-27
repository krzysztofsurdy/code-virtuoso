## Overview

The "Replace Nested Conditional with Guard Clauses" refactoring technique transforms deeply nested if-else structures into a flat, sequential flow using guard clauses. Guard clauses are early returns or exits that handle special cases and exceptions before the main logic executes. This pattern eliminates the "rightward drift" problem where each nested level adds indentation, making code increasingly difficult to follow.

## Motivation

Deeply nested conditionals create several problems:

- **Reduced Clarity**: The intended logic flow becomes obscured by multiple indentation levels
- **Ad-hoc Appearance**: Deeply nested conditions suggest hasty, unplanned development rather than deliberate design
- **Cognitive Overload**: Each nesting level requires mental context switching, reducing maintainability
- **Testing Complexity**: Multiple branching paths make comprehensive testing more difficult
- **Higher Bug Risk**: Complex conditional logic is more prone to mistakes and edge cases

Guard clauses address these issues by placing all exception handling at the method's beginning, allowing the "happy path" to flow naturally without unnecessary indentation.

## Mechanics

The refactoring process follows these steps:

1. **Identify Guard Conditions**: Look for conditions that trigger early returns, throws, or exits
2. **Reorder Conditions**: Move guard clauses to the beginning of the method
3. **Replace Nesting**: Convert nested if-else structures to sequential if-statements
4. **Eliminate Nesting**: Remove else blocks by using guard clause returns
5. **Consolidate Logic**: Combine guard conditions where appropriate using logical operators

## Before/After: PHP 8.3+ Code

### Before (Nested Conditionals)

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

### After (Guard Clauses)

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

### Complex Example with Early Exits

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

- **Improved Readability**: Code flows naturally from top to bottom without excessive indentation
- **Clearer Intent**: Guard clauses make exception handling explicit and visible
- **Easier Testing**: Each condition and code path is independently testable
- **Better Maintenance**: Future developers can quickly understand the method's logic
- **Reduced Cognitive Load**: Eliminates mental context switching from nested structures
- **Fewer Variables**: Reduces unnecessary variable assignments used only for conditional logic

## When NOT to Use

This refactoring may not be appropriate when:

- **Complex Interdependent Conditions**: If conditions heavily depend on each other's results, polymorphism might be better
- **Business Logic Objects**: For substantial domain-specific logic, consider **Replace Conditional with Polymorphism**
- **Single Critical Path**: If there's only one success path and one failure path, simple if-else may be clearer
- **Performance-Critical Code**: Early exits via exceptions have overhead; use cautiously in tight loops

## Related Refactorings

- **Decompose Conditional**: Extract complex conditions into named methods for clarity
- **Replace Conditional with Polymorphism**: Use inheritance or interfaces for complex decision trees
- **Extract Method**: Extract guard clause logic into separate methods for better readability
- **Consolidate Duplicate Conditional Fragments**: Combine similar guard clauses that share outcomes

## Examples in Other Languages

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

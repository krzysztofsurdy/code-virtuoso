## Overview

Replace Exception with Test moves validation out of try/catch blocks and into upfront conditional checks. When a situation is entirely foreseeable - an index might be out of bounds, a divisor might be zero - testing for it before the operation is both cheaper and more honest than catching an exception after the fact. Exceptions should be reserved for genuinely unexpected failures, not for conditions that can be anticipated and handled as part of normal flow.

## Motivation

Exception handling machinery is designed for truly unforeseen failures, not for conditions that are straightforward to check in advance. Using try/catch for predictable edge cases misleads readers about the severity of the situation, incurs the runtime cost of constructing and unwinding exception objects, and blurs the line between genuine errors and routine branching. This refactoring draws that line clearly by moving preventable checks into standard conditional logic.

## Mechanics

1. Locate try/catch blocks that handle foreseeable conditions
2. Write a conditional test that checks for the edge case before the try block
3. Transfer the catch block's recovery logic into the new conditional branch
4. Replace the catch clause with code that raises a standard exception for truly unexpected cases
5. Execute the test suite to verify consistent behavior
6. Strip away the try/catch structure once all tests pass

## Before/After: PHP 8.3+ Code

### Before: Using Exceptions for Expected Conditions

```php
function getUserAge(int $userId): int
{
    try {
        $user = $this->userRepository->find($userId);
        return $user->getAge();
    } catch (UserNotFoundException $e) {
        return 0;
    }
}

function divideNumbers(float $dividend, float $divisor): float
{
    try {
        return $dividend / $divisor;
    } catch (DivisionByZeroException $e) {
        throw new InvalidArgumentException('Divisor cannot be zero');
    }
}
```

### After: Using Conditional Tests

```php
function getUserAge(int $userId): int
{
    $user = $this->userRepository->find($userId);

    if ($user === null) {
        return 0;
    }

    return $user->getAge();
}

function divideNumbers(float $dividend, float $divisor): float
{
    if ($divisor === 0.0) {
        throw new InvalidArgumentException('Divisor cannot be zero');
    }

    return $dividend / $divisor;
}
```

## Benefits

- **Honest intent**: Conditionals declare that the situation is expected; exceptions signal that something went genuinely wrong
- **Better performance**: Avoids the overhead of exception object construction and stack unwinding
- **Clearer separation**: Predictable edge cases stay in normal control flow; exceptional failures stay in catch blocks
- **Straightforward reading**: Top-to-bottom conditionals are easier to follow than try/catch scaffolding
- **Right tool for the job**: Exceptions remain reserved for situations that truly cannot be anticipated

## When NOT to Use

- Truly exceptional failures that need stack unwinding and propagation
- Errors originating from external systems or unpredictable infrastructure
- Cases where it is impossible to anticipate every edge case in advance
- Error handling around third-party libraries whose internal behavior you cannot predict
- Rare, legitimately error-level conditions that cannot be checked proactively

## Related Refactorings

- **Replace Magic with Constants**: Assign descriptive constant names to values used in predictable condition checks
- **Extract Method**: Pull validation logic into its own dedicated method
- **Introduce Guard Clauses**: Use early returns paired with conditional tests
- **Consolidate Duplicate Conditional Fragments**: Merge overlapping validation checks
- **Replace Nested Conditionals with Guard Clauses**: Flatten complex validation hierarchies

## Examples in Other Languages

### Java

**Before:**
```java
double getValueForPeriod(int periodNumber) {
  try {
    return values[periodNumber];
  } catch (ArrayIndexOutOfBoundsException e) {
    return 0;
  }
}
```

**After:**
```java
double getValueForPeriod(int periodNumber) {
  if (periodNumber >= values.length) {
    return 0;
  }
  return values[periodNumber];
}
```

### C#

**Before:**
```csharp
double GetValueForPeriod(int periodNumber)
{
  try
  {
    return values[periodNumber];
  }
  catch (IndexOutOfRangeException e)
  {
    return 0;
  }
}
```

**After:**
```csharp
double GetValueForPeriod(int periodNumber)
{
  if (periodNumber >= values.Length)
  {
    return 0;
  }
  return values[periodNumber];
}
```

### Python

**Before:**
```python
def getValueForPeriod(periodNumber):
    try:
        return values[periodNumber]
    except IndexError:
        return 0
```

**After:**
```python
def getValueForPeriod(self, periodNumber):
    if periodNumber >= len(self.values):
        return 0
    return self.values[periodNumber]
```

### TypeScript

**Before:**
```typescript
getValueForPeriod(periodNumber: number): number {
  try {
    return values[periodNumber];
  } catch (ArrayIndexOutOfBoundsException e) {
    return 0;
  }
}
```

**After:**
```typescript
getValueForPeriod(periodNumber: number): number {
  if (periodNumber >= values.length) {
    return 0;
  }
  return values[periodNumber];
}
```

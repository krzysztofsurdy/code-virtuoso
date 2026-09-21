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

Replace Exception with Test moves validation out of try/catch blocks and into conditional checks that run first. Some situations are easy to foresee: an index may be out of bounds, or a divisor may be zero. Testing for them before the operation is cheaper and more honest than catching an exception afterward. Keep exceptions for unexpected failures. Handle conditions you can anticipate as normal flow.

## Motivation

Exception handling is built for failures you cannot foresee. It is a poor fit for conditions you can check in advance. Using try/catch for predictable edge cases misleads readers about how serious the situation is. It also costs time at runtime, because exception objects must be built and unwound. And it blurs the line between real errors and routine branching. This refactoring restores that line by moving preventable checks into ordinary conditionals.

## Mechanics

1. Locate try/catch blocks that handle foreseeable conditions
2. Write a conditional test that checks for the edge case before the try block
3. Move the catch block's recovery logic into the new conditional branch
4. Replace the catch clause with code that raises a standard exception for unexpected cases
5. Run the test suite to confirm behavior is unchanged
6. Remove the try/catch structure once all tests pass

## Before/After: PHP 8.3+ code

### Before: exceptions for expected conditions

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

### After: conditional tests

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

- **Honest intent**: A conditional says the situation is expected; an exception says something went wrong
- **Better performance**: No exception object to build and no stack to unwind
- **Clear separation**: Predictable edge cases stay in normal control flow; unexpected failures stay in catch blocks
- **Easier reading**: Top-to-bottom conditionals are easier to follow than try/catch structure
- **Right tool for the job**: Exceptions stay reserved for situations that cannot be anticipated

## When NOT to use

- Exceptional failures that need stack unwinding and propagation
- Errors from external systems or unpredictable infrastructure
- Cases where you cannot anticipate every edge case in advance
- Error handling around third-party libraries whose internal behavior you cannot predict
- Rare, error-level conditions that cannot be checked beforehand

## Related Refactorings

- **Replace Magic Number with Symbolic Constant**: Assign descriptive constant names to values used in predictable condition checks
- **Extract Method**: Pull validation logic into its own method
- **Consolidate Duplicate Conditional Fragments**: Merge overlapping validation checks
- **Replace Nested Conditional with Guard Clauses**: Flatten complex validation hierarchies

## Examples in other languages

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

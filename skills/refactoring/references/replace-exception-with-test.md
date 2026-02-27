## Overview

Replace exception handling with conditional tests refactoring moves validation logic before try/catch blocks. This technique treats edge cases as normal program flow rather than exceptional circumstances, making code intent clearer and more performant.

## Motivation

Exceptions are meant for irregular behavior related to unexpected errors, not for testing predictable conditions. Using exceptions for foreseeable scenarios obscures code intent and introduces unnecessary performance overhead from exception instantiation and handling. This refactoring distinguishes between truly exceptional errors and expected variations in program flow.

## Mechanics

1. Identify try/catch blocks handling predictable conditions
2. Create a conditional statement testing for the edge case before the try block
3. Move the catch block logic into this new conditional
4. Replace the catch section with code that throws a standard exception
5. Run tests to confirm behavior
6. Remove try/catch structure once tests pass

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

- **Clarity**: Conditional statements more directly express intent than exception handling
- **Performance**: Avoids overhead of exception instantiation and stack unwinding
- **Correctness**: Distinguishes between truly exceptional errors and expected variations
- **Readability**: Makes code flow easier to follow for maintainers
- **Efficiency**: Uses exceptions only for genuinely exceptional circumstances

## When NOT to Use

- Genuinely exceptional conditions requiring stack unwinding
- External system failures or unpredictable errors
- Situations where you cannot reliably predict all edge cases beforehand
- When handling errors from third-party code you don't control
- Rare, truly error-oriented conditions that cannot be verified upfront

## Related Refactorings

- **Replace Magic with Constants**: Define clear constant values for predictable conditions
- **Extract Method**: Isolate validation logic into dedicated methods
- **Introduce Guard Clauses**: Use early returns with conditional tests
- **Consolidate Duplicate Conditional Fragments**: Combine similar validation checks
- **Replace Nested Conditionals with Guard Clauses**: Simplify complex validation hierarchies

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

# Replace Error Code with Exception

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

Replace Error Code with Exception changes methods that signal errors through return codes or special values so that they throw exceptions instead. Callers no longer check return values like `-1`, `0`, or custom error constants. The exception type states the error, and the language enforces handling.

## Motivation

Error codes cause several problems:

- **Conditional clutter**: Code fills up with `if` statements that check for error codes, which hurts readability
- **Easy to ignore**: Callers can skip the check by accident, which leads to silent failures
- **Limited context**: A numeric code says little about what went wrong
- **Constructor limits**: Constructors cannot return error codes, but they can throw exceptions
- **Mixed concerns**: Error codes share the return value with normal data, so data flow and error handling blur together

Exceptions separate error handling from normal flow and force callers to deal with errors through try/catch blocks.

## Mechanics

1. Create exception classes for the error scenarios
2. Change the method to throw exceptions instead of returning error codes
3. Update the method's PHPDoc to document the thrown exceptions
4. Locate all call sites of the method
5. Wrap calls in try/catch blocks to handle the exceptions
6. Remove the error code checks
7. Run the tests and confirm every error path is covered

## Before/After: PHP 8.3+ code

### Before: error codes

```php
class BankAccount
{
    private float $balance = 1000.0;

    // Returns 0 on success, -1 on insufficient funds
    public function withdraw(float $amount): int
    {
        if ($amount > $this->balance) {
            return -1; // Error code for insufficient funds
        }

        if ($amount <= 0) {
            return -2; // Error code for invalid amount
        }

        $this->balance -= $amount;
        return 0; // Success
    }
}

// Usage with error code checking
$account = new BankAccount();
$result = $account->withdraw(500);

if ($result === -1) {
    echo "Insufficient funds";
} elseif ($result === -2) {
    echo "Invalid amount";
} else {
    echo "Withdrawal successful";
}
```

### After: exceptions

```php
class InsufficientFundsException extends Exception {}
class InvalidAmountException extends Exception {}

class BankAccount
{
    private float $balance = 1000.0;

    /**
     * @throws InsufficientFundsException
     * @throws InvalidAmountException
     */
    public function withdraw(float $amount): void
    {
        if ($amount <= 0) {
            throw new InvalidAmountException(
                "Withdrawal amount must be positive, got: {$amount}"
            );
        }

        if ($amount > $this->balance) {
            throw new InsufficientFundsException(
                "Insufficient funds. Available: {$this->balance}, Requested: {$amount}"
            );
        }

        $this->balance -= $amount;
    }
}

// Usage with exception handling
$account = new BankAccount();

try {
    $account->withdraw(500);
    echo "Withdrawal successful";
} catch (InvalidAmountException $e) {
    echo "Error: " . $e->getMessage();
} catch (InsufficientFundsException $e) {
    echo "Error: " . $e->getMessage();
}
```

## Benefits

- **Explicit error handling**: Exceptions force callers to acknowledge and handle errors
- **Rich information**: Custom exceptions can carry context data and helper methods
- **Cleaner code**: No more nested error code conditionals
- **Type safety**: IDEs and type checkers can validate exception handling
- **Constructor compatibility**: Constructors can throw exceptions
- **Fail-fast behavior**: Unhandled exceptions surface problems immediately
- **Symfony integration**: Works with Symfony's exception handling and event subscribers

## When NOT to use

- **Normal flow control**: Do not throw exceptions for expected, non-error conditions (for example, "user not found" in optional lookups)
- **Performance-critical loops**: Exceptions are costly; avoid throwing in tight loops over many items
- **External APIs**: When wrapping third-party code, keep its error patterns if they are well established
- **Legacy systems**: If the codebase relies heavily on error codes, refactor in small steps to avoid breaking changes

## Related Refactorings

- **Extract Method**: Often combined to isolate error-throwing logic
- **Replace Parameter with Method Call**: Can help reduce error-prone parameter passing
- **Replace Magic Number with Symbolic Constant**: Name any numeric error codes that remain while callers migrate to exceptions

## Examples in other languages

### Java

**Before:**
```java
int withdraw(int amount) {
  if (amount > _balance) {
    return -1;
  }
  else {
    balance -= amount;
    return 0;
  }
}
```

**After:**
```java
void withdraw(int amount) throws BalanceException {
  if (amount > _balance) {
    throw new BalanceException();
  }
  balance -= amount;
}
```

### C#

**Before:**
```csharp
int Withdraw(int amount)
{
  if (amount > _balance)
  {
    return -1;
  }
  else
  {
    balance -= amount;
    return 0;
  }
}
```

**After:**
```csharp
///<exception cref="BalanceException">Thrown when amount > _balance</exception>
void Withdraw(int amount)
{
  if (amount > _balance)
  {
    throw new BalanceException();
  }
  balance -= amount;
}
```

### Python

**Before:**
```python
def withdraw(self, amount):
    if amount > self.balance:
        return -1
    else:
        self.balance -= amount
    return 0
```

**After:**
```python
def withdraw(self, amount):
    if amount > self.balance:
        raise BalanceException()
    self.balance -= amount
```

### TypeScript

**Before:**
```typescript
withdraw(amount: number): number {
  if (amount > _balance) {
    return -1;
  }
  else {
    balance -= amount;
    return 0;
  }
}
```

**After:**
```typescript
withdraw(amount: number): void {
  if (amount > _balance) {
    throw new Error();
  }
  balance -= amount;
}
```

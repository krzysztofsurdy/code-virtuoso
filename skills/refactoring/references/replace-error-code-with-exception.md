# Replace Error Code with Exception

## Overview

This refactoring technique transforms methods that return error codes or special values to indicate errors into methods that throw appropriate exceptions instead. Rather than checking return values like `-1`, `0`, or custom error constants, exceptions provide a more explicit, type-safe way to signal and handle error conditions.

## Motivation

Error codes introduce several problems:

- **Conditional Clutter**: Code becomes filled with `if` statements checking for error codes, reducing readability
- **Easy to Ignore**: Callers can accidentally ignore error codes, leading to silent failures
- **Limited Context**: Numeric codes provide minimal information about what went wrong
- **Constructor Limitations**: Error codes can't be returned from constructors; exceptions handle this elegantly
- **Flow Control Ambiguity**: Mixing error codes with normal return values conflates data flow with error handling

Exceptions provide a cleaner separation of concerns and force explicit error handling through try/catch blocks.

## Mechanics

1. Create appropriate exception class(es) for the error scenarios
2. Update the method to throw exceptions instead of returning error codes
3. Update the method's PHPDoc to document thrown exceptions
4. Locate all call sites of the method
5. Wrap calls in try/catch blocks to handle exceptions
6. Remove error code checking logic
7. Test thoroughly to ensure all error paths are covered

## Before/After: PHP 8.3+ Code

### Before: Error Code Pattern

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

### After: Exception Pattern

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

- **Explicit Error Handling**: Exceptions force callers to acknowledge and handle errors
- **Rich Information**: Custom exceptions can contain contextual data and helper methods
- **Cleaner Code**: No more nested error code checking conditionals
- **Type Safety**: IDEs and type checkers can validate exception handling
- **Constructor Compatibility**: Exceptions work seamlessly with constructors
- **Fail-Fast Behavior**: Unhandled exceptions immediately surface problems
- **Symfony Integration**: Works naturally with Symfony's exception handling and event subscribers

## When NOT to Use

- **Normal Flow Control**: Don't throw exceptions for expected, non-error conditions (e.g., "user not found" in optional lookups)
- **Performance-Critical Loops**: Exception overhead is high; avoid throwing in tight loops checking many items
- **External APIs**: When wrapping third-party code, preserve original error patterns if they're well-established
- **Legacy Systems**: If the codebase heavily relies on error codes, refactor incrementally to avoid breaking changes

## Related Refactorings

- **Extract Method**: Often combined to isolate error-throwing logic
- **Replace Parameter with Method**: Can help reduce error-prone parameter passing
- **Introduce Custom Exception**: Create domain-specific exceptions for better semantics
- **Replace Magic Number**: Use exception types instead of numeric error codes

## Examples in Other Languages

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

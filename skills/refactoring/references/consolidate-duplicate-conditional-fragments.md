## Overview

The **Consolidate Duplicate Conditional Fragments** refactoring addresses a common code smell where identical code appears across all branches of a conditional statement (if/else, switch, etc.). The solution is straightforward: move the duplicate code outside of the conditional structure.

This refactoring technique helps maintain cleaner, more maintainable code by eliminating redundancy and making the conditional logic's actual differences more apparent.

## Motivation

Duplicate code fragments frequently emerge in conditional branches through natural code evolution, particularly when:

- Different developers work on separate branches without coordinating changes
- Copy-paste logic is used as a quick fix that never gets refactored
- Conditional structures grow over time and common patterns aren't consolidated
- Refactoring opportunities are overlooked during code reviews

The presence of identical code in conditional branches increases maintenance burden, increases the risk of bugs when updates are needed, and obscures the actual logic differences between branches.

## Mechanics

The refactoring process depends on where the duplicate code appears within the branches:

1. **Duplicates at the Beginning**: Move the common code before the conditional statement
2. **Duplicates at the End**: Move the common code after the conditional statement
3. **Scattered Duplicates**: If duplicates appear in multiple locations within branches, consolidate to the beginning or end based on logic flow
4. **Verify Logic**: Ensure moving code doesn't alter the program's behavior or logic flow

## Before Code (PHP 8.3+)

```php
class OrderProcessor {
    public function calculateTotal(bool $isSpecialDeal, float $price): void {
        if ($isSpecialDeal) {
            $total = $price * 0.95;
            $this->send();
            $this->logTransaction('special');
        } else {
            $total = $price * 0.98;
            $this->send();
            $this->logTransaction('standard');
        }
    }
}
```

In this example, `$this->send()` is duplicated in both branches.

## After Code (PHP 8.3+)

```php
class OrderProcessor {
    public function calculateTotal(bool $isSpecialDeal, float $price): void {
        if ($isSpecialDeal) {
            $total = $price * 0.95;
            $this->logTransaction('special');
        } else {
            $total = $price * 0.98;
            $this->logTransaction('standard');
        }

        $this->send();
    }
}
```

The `$this->send()` call is moved after the conditional, eliminating duplication and clarifying that sending happens regardless of the deal type.

### Extended Example with Multiple Conditions

**Before:**
```php
class PaymentHandler {
    public function processPayment(string $paymentMethod): void {
        $this->log('Processing payment');

        match ($paymentMethod) {
            'credit_card' => $this->processCreditCard(),
            'paypal' => $this->processPayPal(),
            'bank_transfer' => $this->processBankTransfer(),
        };

        $this->log('Payment completed');
        $this->notifyUser();
    }
}
```

**After:**
```php
class PaymentHandler {
    public function processPayment(string $paymentMethod): void {
        $this->log('Processing payment');

        match ($paymentMethod) {
            'credit_card' => $this->processCreditCard(),
            'paypal' => $this->processPayPal(),
            'bank_transfer' => $this->processBankTransfer(),
        };

        $this->log('Payment completed');
        $this->notifyUser();
    }
}
```

In match expressions, duplicates at the end can be consolidated after the entire match block.

## Benefits

- **Code Deduplication**: Reduces redundancy and maintenance burden significantly
- **Improved Clarity**: Makes conditional logic clearer by isolating the actual differences between branches
- **Reduced Maintenance Risk**: Changes to common behavior only need to be made in one place
- **Better Readability**: Developers can focus on what differs between branches rather than finding duplicates
- **Easier Testing**: Shared logic is tested once, conditional branches test only differences

## When NOT to Use

- **Side Effects Matter**: If moving code outside the conditional could affect performance or side effects in unwanted ways
- **Error Handling**: When duplicate code handles errors differently in each branch
- **Scope-Dependent Code**: When the duplicate code relies on variables only available in specific conditional branches
- **Complex Conditionals**: When consolidation would make the code harder to understand than leaving duplicates
- **Partial Duplicates**: When only portions of statements are duplicated and extracting them would require additional refactoring

## Related Refactorings

- **Extract Method**: Use when duplicate fragments are lengthy; extract them into a dedicated method first
- **Consolidate Conditional Expression**: Similar pattern for simplifying complex conditionals
- **Replace Conditional with Polymorphism**: For object-oriented alternatives to large conditional blocks
- **Duplicate Code Smell**: This refactoring directly eliminates the duplicate code code smell

## Examples in Other Languages

### Java

**Before:**
```java
if (isSpecialDeal()) {
  total = price * 0.95;
  send();
}
else {
  total = price * 0.98;
  send();
}
```

**After:**
```java
if (isSpecialDeal()) {
  total = price * 0.95;
}
else {
  total = price * 0.98;
}
send();
```

### C#

**Before:**
```csharp
if (IsSpecialDeal())
{
  total = price * 0.95;
  Send();
}
else
{
  total = price * 0.98;
  Send();
}
```

**After:**
```csharp
if (IsSpecialDeal())
{
  total = price * 0.95;
}
else
{
  total = price * 0.98;
}
Send();
```

### Python

**Before:**
```python
if isSpecialDeal():
    total = price * 0.95
    send()
else:
    total = price * 0.98
    send()
```

**After:**
```python
if isSpecialDeal():
    total = price * 0.95
else:
    total = price * 0.98
send()
```

### TypeScript

**Before:**
```typescript
if (isSpecialDeal()) {
  total = price * 0.95;
  send();
}
else {
  total = price * 0.98;
  send();
}
```

**After:**
```typescript
if (isSpecialDeal()) {
  total = price * 0.95;
}
else {
  total = price * 0.98;
}
send();
```

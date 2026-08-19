## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before (PHP 8.3+)](#before-php-83)
- [After (PHP 8.3+)](#after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

**Consolidate Duplicate Conditional Fragments** applies when the same code appears inside every branch of a conditional. The code runs whichever branch is taken, so it belongs outside the conditional. Moving it out removes the duplication and shows how the branches differ.

## Motivation

Identical code builds up in conditional branches over time. Different developers add the same call to each branch, copy-paste shortcuts stay in, or new branches inherit boilerplate from existing ones. The result is:

- Maintenance overhead: every change to the shared logic must be repeated in all branches
- Unclear intent: readers cannot tell which parts of the branches differ
- Bug risk: forgetting to update one branch after changing the others causes subtle inconsistencies

## Mechanics

Where the extracted code goes depends on its position in the branches:

1. **Common code at the start of all branches**: Move it before the conditional
2. **Common code at the end of all branches**: Move it after the conditional
3. **Common code scattered within branches**: Reorder so it sits at the beginning or end, then extract it
4. **Verify correctness**: Confirm that moving the code does not change behavior or evaluation order

## Before (PHP 8.3+)

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

## After (PHP 8.3+)

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

The `$this->send()` call now sits after the conditional. Sending happens unconditionally, and only the pricing and logging differ between branches.

### Extended example with multiple conditions

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

In match expressions, duplicates at the end can move after the whole match block.

## Benefits

- **No redundancy**: Shared logic exists in one place
- **Visible branch differences**: With the common code removed, what varies between branches stands out
- **Safer updates**: Changes to the shared behavior happen once instead of in every branch
- **Readability**: The structure of the decision is visible without repeated code
- **Focused tests**: Shared behavior is tested once, and branch-specific behavior is tested per branch

## When NOT to use

- **Side-effect ordering matters**: Moving the code would change the timing or order of side effects in harmful ways
- **Branch-specific error handling**: Identical-looking code handles errors differently in each branch
- **Variable scoping issues**: The duplicated code depends on variables defined only inside one branch
- **Reduced clarity**: Extracting the code makes the overall flow harder to follow
- **Partial overlap**: Branches share only part of a statement, and splitting it needs more restructuring

## Related refactorings

- **Extract Method**: When the duplicated fragment is long, move it into its own method first
- **Consolidate Conditional Expression**: A related technique that simplifies the conditions themselves
- **Replace Conditional with Polymorphism**: An object-oriented alternative for large conditional blocks
- **Duplicate Code Smell**: This refactoring removes the duplicate code smell directly

## Examples in other languages

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

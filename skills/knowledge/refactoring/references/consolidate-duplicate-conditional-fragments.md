## Overview

**Consolidate Duplicate Conditional Fragments** targets a situation where the same code appears inside every branch of a conditional. Since the code runs regardless of which branch is taken, it belongs outside the conditional entirely. Moving it out removes the duplication and highlights the genuine differences between branches.

## Motivation

Identical code inside conditional branches tends to accumulate through organic growth: different developers add the same call to each branch, copy-paste shortcuts go uncleaned, or new branches inherit boilerplate from existing ones. The result is:

- Maintenance overhead - every change to the shared logic must be replicated across all branches
- Obscured intent - readers cannot immediately tell which parts of the branches actually differ
- Increased bug risk - forgetting to update one branch after changing the others introduces subtle inconsistencies

## Mechanics

Where you place the extracted code depends on its position within the branches:

1. **Common code at the start of all branches**: Move it before the conditional
2. **Common code at the end of all branches**: Move it after the conditional
3. **Common code scattered within branches**: Reorganize to consolidate at the beginning or end, then extract
4. **Verify correctness**: Confirm that relocating the code does not alter program behavior or evaluation order

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

The `$this->send()` call now lives after the conditional, making it clear that sending happens unconditionally while only the pricing and logging differ between branches.

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

- **Eliminates Redundancy**: Shared logic exists in exactly one place
- **Highlights Branch Differences**: With the common code removed, what actually varies between branches stands out
- **Safer Updates**: Changes to the shared behavior happen once instead of in every branch
- **Improved Readability**: Developers see the structure of the decision without wading through repeated code
- **Focused Tests**: Shared behavior is tested once; branch-specific behavior is tested per branch

## When NOT to Use

- **Side-effect ordering matters**: If relocating the code would change the timing or order of side effects in harmful ways
- **Branch-specific error handling**: When identical-looking code actually handles errors differently in each branch
- **Variable scoping issues**: When the duplicated code depends on variables defined only within a particular branch
- **Reduced clarity**: If extracting the code makes the overall flow harder to follow
- **Partial overlap**: When branches share only part of a statement and splitting it would require further restructuring

## Related Refactorings

- **Extract Method**: When the duplicated fragment is lengthy, pull it into its own method first
- **Consolidate Conditional Expression**: A related technique for simplifying the conditions themselves
- **Replace Conditional with Polymorphism**: An object-oriented alternative for large conditional blocks
- **Duplicate Code Smell**: This refactoring directly addresses the duplicate code smell

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

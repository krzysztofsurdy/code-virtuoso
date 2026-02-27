## Overview

The Inline Method refactoring technique is used to eliminate simple methods that add little value. When a method is straightforward and its name doesn't reveal something important about the intent of the code, inlining the method body directly into the caller can simplify the codebase. This refactoring is the reverse operation of "Extract Method."

## Motivation

Methods are created for various reasons:
- **Excessive indirection**: Sometimes you create a method to add an indirection layer that no longer serves a purpose
- **Simple calculations**: A method that merely wraps a single expression may not justify its existence
- **Convenience methods**: Methods added "just in case" often end up being called only once
- **Poor naming**: When a method's name doesn't clarify intent, it creates confusion rather than clarity
- **Easy refactoring path**: Sometimes inlining is a stepping stone to better refactoring

Inlining can reduce the overhead of method calls and make the code flow more apparent, especially when the method body is trivial.

## Mechanics

### Step-by-Step Process

1. **Check for overrides**: Verify the method is not overridden in subclasses. If it is, skip inlining.
2. **Find all callers**: Locate every place where the method is called.
3. **Replace calls with body**: For each call, replace the method invocation with the method's body.
4. **Handle parameters**: Substitute method parameters with actual arguments passed in the call.
5. **Handle return values**: Replace the method call with the returned expression (if any).
6. **Remove the method**: Delete the original method definition.
7. **Test**: Run tests to ensure behavior is preserved.

## Before/After Examples

### Example 1: Simple Getter Inlining

**Before:**
```php
<?php

declare(strict_types=1);

class Order
{
    private int $basePrice;
    private float $taxRate;

    public function __construct(int $basePrice, float $taxRate)
    {
        $this->basePrice = $basePrice;
        $this->taxRate = $taxRate;
    }

    public function getPrice(): float
    {
        return $this->basePrice * (1 + $this->taxRate);
    }
}

// Usage
$order = new Order(100, 0.1);
$total = $order->getPrice();
```

**After:**
```php
<?php

declare(strict_types=1);

class Order
{
    private int $basePrice;
    private float $taxRate;

    public function __construct(int $basePrice, float $taxRate)
    {
        $this->basePrice = $basePrice;
        $this->taxRate = $taxRate;
    }
}

// Usage
$order = new Order(100, 0.1);
$total = $order->basePrice * (1 + $order->taxRate);
```

### Example 2: Conditional Logic Inlining

**Before:**
```php
<?php

declare(strict_types=1);

class UserValidator
{
    public function validateUser(string $username, string $email): bool
    {
        return $this->isValidUsername($username) && $this->isValidEmail($email);
    }

    private function isValidUsername(string $username): bool
    {
        return strlen($username) >= 3 && strlen($username) <= 50;
    }

    private function isValidEmail(string $email): bool
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
}

// Usage
$validator = new UserValidator();
if ($validator->validateUser('john_doe', 'john@example.com')) {
    // Process user
}
```

**After:**
```php
<?php

declare(strict_types=1);

class UserValidator
{
    public function validateUser(string $username, string $email): bool
    {
        return (strlen($username) >= 3 && strlen($username) <= 50)
            && filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
}

// Usage
$validator = new UserValidator();
if ($validator->validateUser('john_doe', 'john@example.com')) {
    // Process user
}
```

### Example 3: Method Call Inlining

**Before:**
```php
<?php

declare(strict_types=1);

class Invoice
{
    private int $subtotal;
    private int $taxAmount;
    private int $discount;

    public function __construct(int $subtotal, int $taxAmount, int $discount)
    {
        $this->subtotal = $subtotal;
        $this->taxAmount = $taxAmount;
        $this->discount = $discount;
    }

    public function getTotal(): int
    {
        return $this->calculateNetTotal();
    }

    private function calculateNetTotal(): int
    {
        return $this->subtotal + $this->taxAmount - $this->discount;
    }
}

// Usage
$invoice = new Invoice(1000, 100, 50);
echo $invoice->getTotal();
```

**After:**
```php
<?php

declare(strict_types=1);

class Invoice
{
    private int $subtotal;
    private int $taxAmount;
    private int $discount;

    public function __construct(int $subtotal, int $taxAmount, int $discount)
    {
        $this->subtotal = $subtotal;
        $this->taxAmount = $taxAmount;
        $this->discount = $discount;
    }

    public function getTotal(): int
    {
        return $this->subtotal + $this->taxAmount - $this->discount;
    }
}

// Usage
$invoice = new Invoice(1000, 100, 50);
echo $invoice->getTotal();
```

## Benefits

- **Reduced complexity**: Eliminates unnecessary layers of indirection
- **Improved readability**: When method names don't add clarity, their removal can make code clearer
- **Better performance**: Removes method call overhead (minor in most cases)
- **Easier comprehension**: Direct code makes it obvious what's happening without context switching
- **Prepares for refactoring**: Often used as a step before applying other refactorings

## When NOT to Use

- **Polymorphism**: Never inline methods that are overridden in subclasses
- **Public API**: Don't inline public methods that are part of a stable interface used by external code
- **Complex logic**: If a method contains intricate logic, keep it separate for clarity and testability
- **Reused extensively**: If a method is called from many places, inlining creates duplication
- **Important business logic**: Methods with significant business meaning should remain for intent documentation
- **Recursive methods**: Methods that call themselves cannot be easily inlined
- **Test dependencies**: Methods specifically designed for testing should be preserved

## Related Refactorings

- **Extract Method**: The reverse operation; use when code is too complex or needs reuse
- **Replace Method with Method Object**: When inlining would create overly complex expressions
- **Simplify Method**: Complement to inlining; use to reduce method complexity before inlining
- **Remove Dead Code**: Often applied after identifying methods that are only called in one place
- **Introduce Parameter Object**: When methods have too many parameters to inline effectively

## Examples in Other Languages

### Java

**Before:**
```java
class PizzaDelivery {
  // ...
  int getRating() {
    return moreThanFiveLateDeliveries() ? 2 : 1;
  }
  boolean moreThanFiveLateDeliveries() {
    return numberOfLateDeliveries > 5;
  }
}
```

**After:**
```java
class PizzaDelivery {
  // ...
  int getRating() {
    return numberOfLateDeliveries > 5 ? 2 : 1;
  }
}
```

### C#

**Before:**
```csharp
class PizzaDelivery
{
  // ...
  int GetRating()
  {
    return MoreThanFiveLateDeliveries() ? 2 : 1;
  }
  bool MoreThanFiveLateDeliveries()
  {
    return numberOfLateDeliveries > 5;
  }
}
```

**After:**
```csharp
class PizzaDelivery
{
  // ...
  int GetRating()
  {
    return numberOfLateDeliveries > 5 ? 2 : 1;
  }
}
```

### Python

**Before:**
```python
class PizzaDelivery:
    # ...
    def getRating(self):
        return 2 if self.moreThanFiveLateDeliveries() else 1

    def moreThanFiveLateDeliveries(self):
        return self.numberOfLateDeliveries > 5
```

**After:**
```python
class PizzaDelivery:
    # ...
    def getRating(self):
        return 2 if self.numberOfLateDeliveries > 5 else 1
```

### TypeScript

**Before:**
```typescript
class PizzaDelivery {
  // ...
  getRating(): number {
    return moreThanFiveLateDeliveries() ? 2 : 1;
  }
  moreThanFiveLateDeliveries(): boolean {
    return numberOfLateDeliveries > 5;
  }
}
```

**After:**
```typescript
class PizzaDelivery {
  // ...
  getRating(): number {
    return numberOfLateDeliveries > 5 ? 2 : 1;
  }
}
```

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after examples](#before-and-after-examples)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Inline Method removes a method whose body is as clear as its name and replaces every call with the method's contents. It is the reverse of Extract Method. Use it when a level of indirection adds no value.

## Motivation

Methods name operations and allow reuse. Not every method earns its keep:

- **Pointless indirection**: A method that wraps a single trivial expression does not improve readability
- **Name adds no insight**: The method name says nothing more than the body does
- **Single-call convenience methods**: A method created "just in case" that ended up with only one caller
- **Misleading names**: The method name is less clear than the code it contains
- **Stepping stone**: Inlining is often a preparatory step before a different refactoring

Removing such methods makes the code flow more direct.

## Mechanics

1. **Check for overrides**: If the method is overridden in subclasses, do not inline it
2. **Locate all call sites**: Find every place the method is invoked
3. **Substitute the body**: Replace each call with the method's implementation
4. **Map parameters to arguments**: Substitute formal parameters with the actual values passed at each call site
5. **Handle return values**: Replace the method call with the returned expression
6. **Delete the method**: Remove the now-unused method definition
7. **Run the tests**: Confirm identical behavior

## Before and after examples

### Example 1: simple getter inlining

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

### Example 2: conditional logic inlining

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

### Example 3: method call inlining

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

- **Less indirection**: Readers follow the logic without jumping to another method
- **Clearer flow**: When a method name adds no meaning, removing it makes the code plainer
- **Smaller class surface**: Fewer methods to scan
- **Visible computation**: The logic is where it runs
- **Enables further refactoring**: Inlining often comes before other changes such as Extract Class or Move Method

## When not to use

- **Polymorphic methods**: Never inline methods that subclasses override
- **Published APIs**: Public methods used by external consumers must stay stable
- **Meaningful abstractions**: If the method encapsulates non-trivial logic, keep it for readability and testability
- **Multiple call sites**: Inlining a method that is called from many places creates duplication
- **Business-significant names**: Methods whose names carry domain meaning should stay
- **Recursive methods**: Self-referencing methods cannot be inlined
- **Test hooks**: Methods that exist for testing should stay

## Related refactorings

- **Extract Method**: The opposite operation, used when code is too complex or needs to be reused
- **Replace Method with Method Object**: An alternative when inlining would produce unwieldy expressions
- **Remove Dead Code**: Related cleanup that removes methods that have no callers
- **Introduce Parameter Object**: Shortens parameter lists that grow unwieldy after inlining

## Examples in other languages

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

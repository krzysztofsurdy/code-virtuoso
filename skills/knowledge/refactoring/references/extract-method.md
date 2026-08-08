## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ Example](#before-php-83-example)
- [After: PHP 8.3+ Example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Extract Method is one of the most commonly applied refactorings. It takes a block of code buried inside a larger method and moves it into its own method with a descriptive name. The result is shorter methods, clearer intent, and logic that can be reused and tested independently.

## Motivation

### When to apply

- **Long methods**: Methods beyond 15-20 lines become harder to follow and test
- **Repeated logic**: The same code block appears in multiple places
- **Opaque intent**: A section of code requires careful reading to understand its purpose
- **Tangled responsibilities**: A single method handles validation, calculation, formatting, and persistence
- **Difficult testing**: Thorough unit testing is impractical because the method does too much
- **Complex branching**: Long if/else or switch structures hide the high-level flow

### Why it matters

Smaller methods with meaningful names turn code into a narrative. Readers can see the flow at a glance and read the details only when needed. Each extracted method can be tested, reused, and modified in isolation.

## Mechanics

1. **Select the fragment**: Identify a cohesive block of code that performs a distinct task
2. **Check dependencies**: Note which local variables the fragment reads or writes
3. **Design the signature**: Decide which values to pass as parameters and what to return
4. **Create the method**: Write the new method with a name that describes what it accomplishes
5. **Replace the original code**: Substitute the block with a call to the new method
6. **Run the tests**: Confirm the behavior is identical

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class OrderProcessor
{
    public function processOrder(Order $order): void
    {
        // Validate order
        if ($order->getItems()->isEmpty()) {
            throw new InvalidArgumentException('Order must have at least one item');
        }

        foreach ($order->getItems() as $item) {
            if ($item->getQuantity() < 1) {
                throw new InvalidArgumentException('Item quantity must be positive');
            }
        }

        // Calculate totals
        $subtotal = 0.0;
        foreach ($order->getItems() as $item) {
            $subtotal += $item->getPrice() * $item->getQuantity();
        }

        $taxRate = 0.1;
        $tax = $subtotal * $taxRate;
        $total = $subtotal + $tax;

        // Apply discount
        if ($order->getCustomer()->isVIP()) {
            $total *= 0.9; // 10% VIP discount
        }

        // Send confirmation
        $message = "Order #{$order->getId()} confirmed. Total: \$" . number_format($total, 2);
        $this->emailService->send($order->getCustomer()->getEmail(), $message);

        // Update inventory
        foreach ($order->getItems() as $item) {
            $item->getProduct()->decreaseStock($item->getQuantity());
        }

        $order->setStatus('completed');
        $order->setTotal($total);
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class OrderProcessor
{
    public function processOrder(Order $order): void
    {
        $this->validateOrder($order);
        $total = $this->calculateOrderTotal($order);
        $this->sendConfirmation($order, $total);
        $this->updateInventory($order);

        $order->setStatus('completed');
        $order->setTotal($total);
    }

    private function validateOrder(Order $order): void
    {
        if ($order->getItems()->isEmpty()) {
            throw new InvalidArgumentException('Order must have at least one item');
        }

        foreach ($order->getItems() as $item) {
            if ($item->getQuantity() < 1) {
                throw new InvalidArgumentException('Item quantity must be positive');
            }
        }
    }

    private function calculateOrderTotal(Order $order): float
    {
        $subtotal = $this->calculateSubtotal($order);
        $tax = $subtotal * 0.1;
        $total = $subtotal + $tax;

        if ($order->getCustomer()->isVIP()) {
            $total *= 0.9; // 10% VIP discount
        }

        return $total;
    }

    private function calculateSubtotal(Order $order): float
    {
        $subtotal = 0.0;
        foreach ($order->getItems() as $item) {
            $subtotal += $item->getPrice() * $item->getQuantity();
        }
        return $subtotal;
    }

    private function sendConfirmation(Order $order, float $total): void
    {
        $message = sprintf(
            'Order #%s confirmed. Total: $%s',
            $order->getId(),
            number_format($total, 2)
        );
        $this->emailService->send($order->getCustomer()->getEmail(), $message);
    }

    private function updateInventory(Order $order): void
    {
        foreach ($order->getItems() as $item) {
            $item->getProduct()->decreaseStock($item->getQuantity());
        }
    }
}
```

## Benefits

- **Readable flow**: The calling method reads like a summary; details live in named sub-methods
- **Targeted testing**: Each extracted method can be tested with focused inputs and assertions
- **Reuse**: Extracted logic can be called from other methods or classes
- **Less to hold in your head**: Developers process smaller chunks of logic at a time
- **Faster debugging**: When something breaks, the stack trace points to a narrow, specific method
- **Polymorphism**: Extracted methods are easy to override in subclasses

## When not to use

- **One-liner code**: Wrapping a single obvious statement in a method adds noise
- **One-off utilities**: A calculation used once and already clear may not need its own method
- **Parameter explosion**: If the extracted method requires many parameters, consider Introduce Parameter Object or Extract Class instead
- **Too many tiny methods**: Over-extraction can scatter logic so widely that following the flow is harder than reading it inline
- **Performance-critical inner loops**: Method call overhead is rarely a concern. Measure before ruling it out

## Related refactorings

- **Extract Class**: When extracted logic deserves its own class rather than just a method
- **Replace Method with Method Object**: For methods with so many local variables that extraction is impractical
- **Introduce Parameter Object**: Simplifies the parameter list of an extracted method
- **Replace Temp with Query**: Removes temporary variables that complicate extraction
- **Remove Duplication**: Often precedes Extract Method to consolidate repeated code first

## Examples in other languages

### Java

**Before:**
```java
void printOwing() {
  printBanner();

  // Print details.
  System.out.println("name: " + name);
  System.out.println("amount: " + getOutstanding());
}
```

**After:**
```java
void printOwing() {
  printBanner();
  printDetails(getOutstanding());
}

void printDetails(double outstanding) {
  System.out.println("name: " + name);
  System.out.println("amount: " + outstanding);
}
```

### C#

**Before:**
```csharp
void PrintOwing()
{
  this.PrintBanner();

  // Print details.
  Console.WriteLine("name: " + this.name);
  Console.WriteLine("amount: " + this.GetOutstanding());
}
```

**After:**
```csharp
void PrintOwing()
{
  this.PrintBanner();
  this.PrintDetails();
}

void PrintDetails()
{
  Console.WriteLine("name: " + this.name);
  Console.WriteLine("amount: " + this.GetOutstanding());
}
```

### Python

**Before:**
```python
def printOwing(self):
    self.printBanner()

    # print details
    print("name:", self.name)
    print("amount:", self.getOutstanding())
```

**After:**
```python
def printOwing(self):
    self.printBanner()
    self.printDetails(self.getOutstanding())

def printDetails(self, outstanding):
    print("name:", self.name)
    print("amount:", outstanding)
```

### TypeScript

**Before:**
```typescript
printOwing(): void {
  printBanner();

  // Print details.
  console.log("name: " + name);
  console.log("amount: " + getOutstanding());
}
```

**After:**
```typescript
printOwing(): void {
  printBanner();
  printDetails(getOutstanding());
}

printDetails(outstanding: number): void {
  console.log("name: " + name);
  console.log("amount: " + outstanding);
}
```

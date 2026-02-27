## Overview

Extract Method is a fundamental refactoring technique that breaks down a large or complex method into smaller, focused methods. This improves code readability, reusability, and testability by decomposing complex logic into manageable pieces with single responsibilities.

## Motivation

### When to Apply

- **Methods are too long**: Methods exceeding 15-20 lines become harder to understand and test
- **Code duplication**: Same logic appears in multiple places
- **Unclear intent**: A code block's purpose isn't immediately obvious
- **Mixed concerns**: A method handles multiple responsibilities
- **Difficult to test**: Large methods are challenging to unit test comprehensively
- **Complex conditional logic**: Long if/else chains obscure intent

### Why It Matters

Extract Method promotes code clarity, reduces cognitive load, enables reuse, and facilitates testing. It's one of the most frequently used refactorings because it directly improves code maintainability.

## Mechanics: Step-by-Step

1. **Identify the fragment**: Select a cohesive block of code to extract
2. **Verify independence**: Check if extracted code depends only on local variables
3. **Handle variables**: Plan how to pass needed values as parameters
4. **Determine return value**: Identify what the extracted method should return
5. **Create the method**: Write the new method with appropriate signature
6. **Replace original code**: Call the new method from the original location
7. **Test thoroughly**: Verify behavior remains identical

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

- **Improved Readability**: Code intent becomes self-documenting through meaningful method names
- **Enhanced Testability**: Smaller methods are easier to unit test with focused assertions
- **Code Reusability**: Extracted methods can be called from multiple locations
- **Reduced Complexity**: Cognitive load decreases significantly for maintainers
- **Easier Debugging**: Isolating issues becomes simpler with focused methods
- **Better Composition**: Enables straightforward method composition and chaining
- **Facilitates Polymorphism**: Extracted methods are easier to override in subclasses

## When NOT to Use

- **Already simple code**: Don't extract single-line statements into methods
- **Private utility methods**: One-off calculations may clutter class design
- **Performance-critical paths**: Excessive method calls might impact performance (rare in practice)
- **Very brief methods exist**: Too many tiny methods reduce code comprehension
- **Complex parameter passing**: When extracted method needs many parameters, consider alternative refactorings (Introduce Parameter Object, Extract Class)

## Related Refactorings

- **Extract Class**: When extracted logic belongs in a separate class
- **Replace Method with Method Object**: For methods with many local variables
- **Introduce Parameter Object**: To simplify complex parameter lists
- **Replace Temp with Query**: Eliminates local variables before extraction
- **Remove Duplication**: Often precedes Extract Method to consolidate duplicated code

## Examples in Other Languages

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

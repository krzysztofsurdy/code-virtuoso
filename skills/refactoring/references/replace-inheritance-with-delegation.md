# Replace Inheritance with Delegation

## Overview

Replace Inheritance with Delegation is a refactoring technique that transforms an inheritance relationship into a composition-based approach. When a subclass doesn't properly extend a superclass or only uses a subset of its methods, delegation provides a cleaner alternative that better represents the actual relationship.

The technique involves creating a field in the subclass to hold an instance of the former superclass, delegating method calls to that instance, and removing the inheritance declaration.

## Motivation

### When to Consider This Refactoring

**Liskov Substitution Principle Violation**: Inheritance exists primarily to share code implementation rather than because the subclass authentically extends the superclass's concept. The derived class cannot properly substitute for its parent.

**Partial Method Inheritance**: The subclass only needs a small subset of superclass methods. This exposes unnecessary methods in the class interface, creating confusion for clients about which methods are truly part of the class's contract.

**Design Clarity**: Delegation better represents the actual relationship when the subclass is a "wrapper" or "adapter" that enhances another class without truly being a specialized version of it.

## Mechanics

1. **Add a delegate field** in the subclass to hold an instance of the former superclass
2. **Create delegating methods** for each inherited method needed by clients
3. **Update internal logic** to work with the delegate instance instead of inherited properties
4. **Remove the inheritance declaration** from the class signature
5. **Initialize the delegate** in the constructor

## Before/After Examples

### Before: Inheritance Misuse

```php
<?php
declare(strict_types=1);

abstract readonly class Stack
{
    private array $items = [];

    public function push(mixed $item): void
    {
        $this->items[] = $item;
    }

    public function pop(): mixed
    {
        return array_pop($this->items);
    }

    public function peek(): mixed
    {
        return end($this->items);
    }
}

final readonly class InstrumentedStack extends Stack
{
    private int $accessCount = 0;

    public function incrementAccessCount(): void
    {
        $this->accessCount++;
    }

    public function getAccessCount(): int
    {
        return $this->accessCount;
    }
}
```

### After: Delegation Pattern

```php
<?php
declare(strict_types=1);

final readonly class Stack
{
    public function __construct(private array $items = []) {}

    public function push(mixed $item): void
    {
        $this->items[] = $item;
    }

    public function pop(): mixed
    {
        return array_pop($this->items);
    }

    public function peek(): mixed
    {
        return end($this->items);
    }
}

final class InstrumentedStack
{
    private int $accessCount = 0;

    public function __construct(private readonly Stack $stack = new Stack()) {}

    public function push(mixed $item): void
    {
        $this->accessCount++;
        $this->stack->push($item);
    }

    public function pop(): mixed
    {
        $this->accessCount++;
        return $this->stack->pop();
    }

    public function peek(): mixed
    {
        $this->accessCount++;
        return $this->stack->peek();
    }

    public function getAccessCount(): int
    {
        return $this->accessCount;
    }
}
```

## Benefits

- **Cleaner Interface**: Only exposes the methods the class actually needs, eliminating confusion
- **Flexibility**: Can easily swap different delegate implementations without changing the wrapper's contract
- **Strategy Pattern**: Naturally enables the Strategy design pattern for runtime behavior changes
- **Composition Over Inheritance**: Follows the principle that composition is more flexible than inheritance
- **Reduced Coupling**: The wrapper class is decoupled from the delegate's complete interface

## When NOT to Use

- **True Specialization**: When the subclass is genuinely a specialized version of the superclass (e.g., `Dog extends Animal`)
- **Polymorphic Collections**: When you need the subclass to be substitutable in collections expecting the superclass type
- **Interface Contracts**: When clients expect the subclass to honor the superclass contract through inheritance
- **Simple Code Reuse**: For small, simple inheritance hierarchies without design violations

## Related Refactorings

- **Extract Superclass**: The inverse operation; create a superclass from common code
- **Strategy Pattern**: A design pattern often naturally emerges when using delegation
- **Adapter Pattern**: Similar structure used when adapting one interface to another
- **Decorator Pattern**: Another composition-based alternative for extending behavior

## Examples in Other Languages

### Java

**Before:**

```java
class MyStack extends Vector {
    public void push(Object element) {
        insertElementAt(element, 0);
    }

    public Object pop() {
        Object result = firstElement();
        removeElementAt(0);
        return result;
    }
}
```

**After:**

```java
class MyStack {
    private Vector vector = new Vector();

    public void push(Object element) {
        vector.insertElementAt(element, 0);
    }

    public Object pop() {
        Object result = vector.firstElement();
        vector.removeElementAt(0);
        return result;
    }

    public int size() {
        return vector.size();
    }
}
```

### C#

**Before:**

```csharp
class MyStack : List<object>
{
    public void Push(object element)
    {
        Insert(0, element);
    }

    public object Pop()
    {
        object result = this[0];
        RemoveAt(0);
        return result;
    }
}
```

**After:**

```csharp
class MyStack
{
    private List<object> list = new List<object>();

    public void Push(object element)
    {
        list.Insert(0, element);
    }

    public object Pop()
    {
        object result = list[0];
        list.RemoveAt(0);
        return result;
    }

    public int Size => list.Count;
}
```

### Python

**Before:**

```python
class MyStack(list):
    def push(self, element):
        self.insert(0, element)

    def pop_first(self):
        return self.pop(0)
```

**After:**

```python
class MyStack:
    def __init__(self):
        self._items: list = []

    def push(self, element):
        self._items.insert(0, element)

    def pop_first(self):
        return self._items.pop(0)

    def size(self) -> int:
        return len(self._items)
```

### TypeScript

**Before:**

```typescript
class MyStack extends Array {
    push(element: unknown): number {
        this.unshift(element);
        return this.length;
    }

    pop(): unknown {
        return this.shift();
    }
}
```

**After:**

```typescript
class MyStack {
    private items: unknown[] = [];

    push(element: unknown): void {
        this.items.unshift(element);
    }

    pop(): unknown {
        return this.items.shift();
    }

    size(): number {
        return this.items.length;
    }
}
```

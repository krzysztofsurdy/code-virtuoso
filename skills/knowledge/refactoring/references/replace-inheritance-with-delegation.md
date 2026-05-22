# Replace Inheritance with Delegation

## Overview

Replace Inheritance with Delegation swaps an "extends" relationship for a composition-based approach where the former subclass holds a reference to the former superclass and forwards only the calls it genuinely needs. When a class inherits from another solely to reuse implementation - not because it represents a genuine specialization - delegation models the actual dependency more accurately.

## Motivation

### When to Consider This Refactoring

**Liskov Substitution Principle Violation**: The inheritance exists solely to reuse implementation details, not because the derived class is a legitimate specialization of its parent. Instances of the subclass cannot faithfully stand in for the superclass.

**Partial Method Inheritance**: Only a handful of methods from the parent are relevant to the child. The remaining inherited methods leak into the public surface, confusing callers about which operations are part of the class's true contract.

**Design Clarity**: When the subclass functions as a wrapper or adapter around another class rather than being a genuine subtype, composition expresses that relationship far more honestly.

## Mechanics

1. **Introduce a delegate field** in the subclass to store a reference to the former superclass
2. **Write forwarding methods** for every inherited method that clients still need
3. **Rewire internal logic** so that it operates through the delegate rather than through inherited state
4. **Drop the inheritance declaration** from the class definition
5. **Set up the delegate** inside the constructor

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

- **Controlled surface area**: The class exposes only the methods it explicitly forwards, hiding irrelevant parent operations
- **Interchangeable delegates**: Different implementations can be injected without changing the wrapper's contract
- **Natural strategy fit**: Delegation naturally supports runtime algorithm swapping via the Strategy pattern
- **Honest modeling**: The code reflects a "uses" relationship rather than a misleading "is-a" relationship
- **Reduced coupling**: The wrapper is not bound to the full interface of the delegate's class hierarchy

## When NOT to Use

- **Authentic Specialization**: The subclass truly is a more specific variant of the superclass (e.g., `Dog extends Animal`)
- **Polymorphic Collections**: Code depends on treating instances of the subclass as the superclass type
- **Interface Contracts**: Consumers expect the subclass to satisfy the superclass contract via inheritance
- **Minimal Hierarchies**: Small, straightforward inheritance trees that have no design violations

## Related Refactorings

- **Extract Superclass**: The reverse operation - factor shared code upward into a new parent class
- **Strategy Pattern**: A pattern that frequently emerges naturally once delegation is in place
- **Adapter Pattern**: A structurally similar composition technique for bridging mismatched interfaces
- **Decorator Pattern**: Another composition-based approach for layering additional behavior

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

# Replace Inheritance with Delegation

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples](#beforeafter-examples)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Inheritance with Delegation swaps an "extends" relationship for composition. The former subclass holds a reference to the former superclass and forwards only the calls it needs. When a class inherits from another only to reuse its implementation, and is not a real specialization of it, delegation models the dependency more accurately.

## Motivation

### When to consider this refactoring

**Liskov Substitution Principle violation**: The inheritance exists only to reuse implementation, and the derived class is not a real specialization of its parent. Instances of the subclass cannot stand in for the superclass.

**Partial method inheritance**: Only a few of the parent's methods are relevant to the child. The rest leak into the public surface and confuse callers about which operations belong to the class's contract.

**Design clarity**: The subclass acts as a wrapper or adapter around another class and is not a real subtype. Composition states that relationship honestly.

## Mechanics

1. **Introduce a delegate field** in the subclass to hold a reference to the former superclass
2. **Write forwarding methods** for every inherited method that clients still need
3. **Rewire internal logic** to work through the delegate instead of inherited state
4. **Drop the inheritance declaration** from the class definition
5. **Set up the delegate** in the constructor

## Before/After Examples

### Before: inheritance misuse

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

### After: delegation

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

- **Controlled surface area**: The class exposes only the methods it forwards and hides irrelevant parent operations
- **Interchangeable delegates**: Different implementations can be injected without changing the wrapper's contract
- **Strategy fit**: Delegation supports swapping algorithms at runtime through the Strategy pattern
- **Honest modeling**: The code shows a "uses" relationship instead of a misleading "is-a"
- **Lower coupling**: The wrapper is not bound to the full interface of the delegate's class hierarchy

## When NOT to use

- **Real specialization**: The subclass is a more specific variant of the superclass (for example, `Dog extends Animal`)
- **Polymorphic collections**: Code treats instances of the subclass as the superclass type
- **Interface contracts**: Consumers expect the subclass to satisfy the superclass contract through inheritance
- **Small hierarchies**: Small inheritance trees with no design violations

## Related Refactorings

- **Extract Superclass**: The reverse operation. Move shared code up into a new parent class
- **Strategy Pattern**: Often appears once delegation is in place
- **Adapter Pattern**: A structurally similar composition technique for bridging mismatched interfaces
- **Decorator Pattern**: Another composition-based approach, used to layer on extra behavior

## Examples in other languages

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

# Liskov Substitution Principle (LSP)

## Definition

Objects of a supertype should be replaceable with objects of a subtype without altering the correctness of the program. If class `B` extends class `A`, then anywhere `A` is expected, `B` should work without surprises.

Barbara Liskov introduced this concept in 1987. In practical terms: if your code works with a base type, it must still work correctly when given any derived type — no exceptions thrown, no contracts violated, no unexpected side effects.

## Why It Matters

LSP is the guardrail for inheritance and polymorphism. When violated, code that relies on a base type breaks unpredictably when handed a subtype. This creates:

- **Runtime surprises** — methods throw exceptions or return unexpected values
- **Fragile polymorphism** — generic code needs type checks to work around broken subtypes
- **Misleading hierarchies** — inheritance suggests "is-a" but behavior says otherwise
- **Cascading failures** — one bad subtype forces defensive code throughout the system

## Detecting Violations

Watch for these patterns:

- **Subclass methods that throw "not supported" exceptions** — a clear sign the subtype can't fulfill the parent's contract
- **Type-checking in consumer code** — `if ($animal instanceof Dog)` means something can't be treated generically
- **Overridden methods that do nothing** — empty implementations break the expected behavior
- **Strengthened preconditions** — subtype demands stricter input than the parent promises
- **Weakened postconditions** — subtype returns less or different output than the parent guarantees

## The Classic Violation: Rectangle and Square

The most famous LSP violation demonstrates that mathematical "is-a" doesn't equal behavioral "is-a":

```php
<?php

declare(strict_types=1);

class Rectangle
{
    public function __construct(
        protected float $width,
        protected float $height,
    ) {}

    public function setWidth(float $width): void
    {
        $this->width = $width;
    }

    public function setHeight(float $height): void
    {
        $this->height = $height;
    }

    public function area(): float
    {
        return $this->width * $this->height;
    }
}

class Square extends Rectangle
{
    public function setWidth(float $width): void
    {
        $this->width = $width;
        $this->height = $width; // Surprise! Changes height too
    }

    public function setHeight(float $height): void
    {
        $this->width = $height; // Surprise! Changes width too
        $this->height = $height;
    }
}

// This function works with Rectangle but breaks with Square
function doubleWidth(Rectangle $rect): void
{
    $originalHeight = $rect->area() / $rect->area() * 10; // simplified
    $rect->setWidth(10);
    $rect->setHeight(5);

    // Expected: area = 50
    // With Square: area = 25 (height was overwritten by setWidth)
    assert($rect->area() === 50.0); // Fails with Square!
}
```

**Fix: Use composition or immutable value objects instead**

```php
<?php

declare(strict_types=1);

interface Shape
{
    public function area(): float;
}

final readonly class Rectangle implements Shape
{
    public function __construct(
        public float $width,
        public float $height,
    ) {}

    public function area(): float
    {
        return $this->width * $this->height;
    }
}

final readonly class Square implements Shape
{
    public function __construct(public float $side) {}

    public function area(): float
    {
        return $this->side ** 2;
    }
}
```

## Before/After — PHP 8.3+

### Before: Bird hierarchy where Penguin breaks the contract

```php
<?php

declare(strict_types=1);

class Bird
{
    public function fly(): string
    {
        return 'Flying through the sky';
    }

    public function eat(): string
    {
        return 'Eating food';
    }
}

class Sparrow extends Bird
{
    // Works fine — sparrows can fly
}

class Penguin extends Bird
{
    public function fly(): string
    {
        throw new RuntimeException('Penguins cannot fly!');
        // Violates LSP — code expecting Bird::fly() to return string gets an exception
    }
}

// This breaks when given a Penguin
function migrateBirds(array $birds): void
{
    foreach ($birds as $bird) {
        echo $bird->fly(); // RuntimeException with Penguin
    }
}
```

### After: Separate flying capability from bird identity

```php
<?php

declare(strict_types=1);

interface Bird
{
    public function eat(): string;
}

interface FlyingBird extends Bird
{
    public function fly(): string;
}

interface SwimmingBird extends Bird
{
    public function swim(): string;
}

final readonly class Sparrow implements FlyingBird
{
    public function fly(): string
    {
        return 'Sparrow soaring through the sky';
    }

    public function eat(): string
    {
        return 'Sparrow pecking seeds';
    }
}

final readonly class Penguin implements SwimmingBird
{
    public function swim(): string
    {
        return 'Penguin gliding through water';
    }

    public function eat(): string
    {
        return 'Penguin catching fish';
    }
}

// Type system now prevents passing Penguin where FlyingBird is expected
function migrateBirds(FlyingBird ...$birds): void
{
    foreach ($birds as $bird) {
        echo $bird->fly(); // Always safe — only FlyingBirds accepted
    }
}
```

## LSP Rules Summary

| Rule | Meaning | Violation Example |
|---|---|---|
| **No strengthened preconditions** | Subtype can't demand more than parent | Parent accepts `int`, subtype only accepts positive `int` |
| **No weakened postconditions** | Subtype must deliver at least what parent promises | Parent returns non-empty array, subtype returns `null` |
| **No new exceptions** | Subtype can't throw exceptions parent doesn't declare | `fly()` throwing `RuntimeException` |
| **Preserve invariants** | Subtype must maintain parent's state guarantees | Square breaking Rectangle's independent width/height |
| **History constraint** | Subtype can't modify state in ways parent can't | Subtype making an immutable field mutable |

## Examples in Other Languages

### Java

**Before:**

```java
public class Vehicle {
    public int fuelCapacity() { return 60; }
    public void refuel(int liters) { /* ... */ }
}

public class ElectricCar extends Vehicle {
    @Override
    public void refuel(int liters) {
        throw new UnsupportedOperationException("Electric cars don't use fuel");
        // Violates LSP — consumers expect refuel() to work
    }
}
```

**After:**

```java
public interface Vehicle {
    int range();
}

public interface FuelVehicle extends Vehicle {
    void refuel(int liters);
    int fuelCapacity();
}

public interface ElectricVehicle extends Vehicle {
    void recharge(int kilowattHours);
    int batteryCapacity();
}

public class GasCar implements FuelVehicle {
    @Override public int range() { return 500; }
    @Override public void refuel(int liters) { /* ... */ }
    @Override public int fuelCapacity() { return 60; }
}

public class Tesla implements ElectricVehicle {
    @Override public int range() { return 400; }
    @Override public void recharge(int kwh) { /* ... */ }
    @Override public int batteryCapacity() { return 100; }
}
```

### Python

**Before:**

```python
class FileStorage:
    def read(self, key: str) -> str:
        with open(f"/data/{key}.txt") as f:
            return f.read()

    def write(self, key: str, data: str) -> None:
        with open(f"/data/{key}.txt", "w") as f:
            f.write(data)

    def delete(self, key: str) -> None:
        import os
        os.remove(f"/data/{key}.txt")


class ReadOnlyStorage(FileStorage):
    def write(self, key: str, data: str) -> None:
        raise PermissionError("This storage is read-only")

    def delete(self, key: str) -> None:
        raise PermissionError("This storage is read-only")
    # Violates LSP — consumer expecting FileStorage can't write
```

**After:**

```python
from abc import ABC, abstractmethod


class ReadableStorage(ABC):
    @abstractmethod
    def read(self, key: str) -> str: ...


class WritableStorage(ReadableStorage):
    @abstractmethod
    def write(self, key: str, data: str) -> None: ...

    @abstractmethod
    def delete(self, key: str) -> None: ...


class FileStorage(WritableStorage):
    def read(self, key: str) -> str:
        with open(f"/data/{key}.txt") as f:
            return f.read()

    def write(self, key: str, data: str) -> None:
        with open(f"/data/{key}.txt", "w") as f:
            f.write(data)

    def delete(self, key: str) -> None:
        import os
        os.remove(f"/data/{key}.txt")


class CacheStorage(ReadableStorage):
    def read(self, key: str) -> str:
        return self._cache.get(key, "")
    # No write/delete — and no one expects them
```

### TypeScript

**Before:**

```typescript
class Stack<T> {
  protected items: T[] = [];

  push(item: T): void {
    this.items.push(item);
  }

  pop(): T | undefined {
    return this.items.pop();
  }

  size(): number {
    return this.items.length;
  }
}

class CappedStack<T> extends Stack<T> {
  constructor(private maxSize: number) {
    super();
  }

  push(item: T): void {
    if (this.items.length >= this.maxSize) {
      throw new Error("Stack is full");
      // Violates LSP — strengthened precondition
    }
    super.push(item);
  }
}
```

**After:**

```typescript
class Stack<T> {
  protected items: T[] = [];

  push(item: T): boolean {
    this.items.push(item);
    return true;
  }

  pop(): T | undefined {
    return this.items.pop();
  }

  size(): number {
    return this.items.length;
  }
}

class CappedStack<T> extends Stack<T> {
  constructor(private maxSize: number) {
    super();
  }

  push(item: T): boolean {
    if (this.items.length >= this.maxSize) {
      return false; // Communicates failure without violating contract
    }
    return super.push(item);
  }
}
```

### C++

**Before:**

```cpp
class Collection {
public:
    virtual void add(int item) = 0;
    virtual void remove(int item) = 0;
    virtual bool contains(int item) const = 0;
    virtual ~Collection() = default;
};

class MutableSet : public Collection {
    std::set<int> data;
public:
    void add(int item) override { data.insert(item); }
    void remove(int item) override { data.erase(item); }
    bool contains(int item) const override { return data.count(item) > 0; }
};

class FrozenSet : public Collection {
    std::set<int> data;
public:
    FrozenSet(std::initializer_list<int> items) : data(items) {}
    void add(int item) override { throw std::logic_error("Cannot modify"); }
    void remove(int item) override { throw std::logic_error("Cannot modify"); }
    bool contains(int item) const override { return data.count(item) > 0; }
};
```

**After:**

```cpp
class ReadableCollection {
public:
    virtual bool contains(int item) const = 0;
    virtual ~ReadableCollection() = default;
};

class MutableCollection : public ReadableCollection {
public:
    virtual void add(int item) = 0;
    virtual void remove(int item) = 0;
};

class MutableSet : public MutableCollection {
    std::set<int> data;
public:
    void add(int item) override { data.insert(item); }
    void remove(int item) override { data.erase(item); }
    bool contains(int item) const override { return data.count(item) > 0; }
};

class FrozenSet : public ReadableCollection {
    std::set<int> data;
public:
    FrozenSet(std::initializer_list<int> items) : data(items) {}
    bool contains(int item) const override { return data.count(item) > 0; }
};
```

## Common Pitfalls

- **Thinking "is-a" in the real world means "is-a" in code** — a Square is mathematically a Rectangle, but its behavior is incompatible with mutable Rectangle code
- **Empty method overrides** — overriding a method to do nothing is almost always a violation
- **Catching and swallowing exceptions** — wrapping violations in try-catch doesn't fix them, it hides them
- **Over-relying on inheritance** — prefer composition when subtypes can't fully honor the parent contract

## Related Principles

- **Open/Closed (OCP)** — LSP makes polymorphic extension possible. Without LSP, substituting subtypes breaks OCP
- **Interface Segregation (ISP)** — smaller interfaces make it easier to honor the full contract
- **Design by Contract** — Eiffel's pre/postcondition system formalizes what LSP demands

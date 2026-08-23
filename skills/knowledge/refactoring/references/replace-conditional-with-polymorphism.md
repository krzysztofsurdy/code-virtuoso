## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: conditional logic](#before-conditional-logic)
- [After: polymorphic implementation (PHP 8.3+)](#after-polymorphic-implementation-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Conditional with Polymorphism turns branching logic (switch statements, if-else ladders) into a class hierarchy where each variant implements its own version of the method. Instead of checking a type code or flag to pick a path, the object carries the right behavior. Method overriding dispatches to it.

## Motivation

Conditionals that select behavior by object type or category have several weaknesses:

- **Shotgun surgery**: Adding a new variant means hunting down and modifying every conditional that checks the type
- **Closed for extension**: New cases mean editing existing code instead of adding to it
- **Scattered knowledge**: The same branching logic is often duplicated across multiple methods
- **External interrogation**: Callers must ask "what kind are you?" instead of requesting an action
- **Hard-to-isolate tests**: All branches share one method, which makes focused unit tests awkward

## Mechanics

1. Create a class hierarchy with an abstract base class or interface
2. Create subclasses representing each conditional branch
3. Extract the method containing the conditional logic
4. Override this method in each subclass with branch-specific implementation
5. Remove conditional branches progressively
6. Replace conditional calls with polymorphic method invocations

## Before: conditional logic

```php
class Bird
{
    private string $type;
    private float $speed;
    private bool $isNailed;

    public function getSpeed(): float
    {
        return match ($this->type) {
            'european' => $this->speed,
            'african' => max(0, $this->speed - $this->getLoadFactor() * 9),
            'norwegian' => max(0, $this->speed - $this->getLoadFactor() * 3),
            default => 0
        };
    }

    private function getLoadFactor(): float
    {
        return $this->isNailed ? 2 : 1;
    }
}

// Usage
$bird = new Bird('african', 100, false);
echo $bird->getSpeed(); // Must know implementation details
```

## After: polymorphic implementation (PHP 8.3+)

```php
abstract class Bird
{
    protected float $speed;
    protected bool $isNailed;

    public function __construct(float $speed, bool $isNailed = false)
    {
        $this->speed = $speed;
        $this->isNailed = $isNailed;
    }

    abstract public function getSpeed(): float;

    protected function getLoadFactor(): float
    {
        return $this->isNailed ? 2 : 1;
    }
}

class EuropeanBird extends Bird
{
    public function getSpeed(): float
    {
        return $this->speed;
    }
}

class AfricanBird extends Bird
{
    public function getSpeed(): float
    {
        return max(0, $this->speed - $this->getLoadFactor() * 9);
    }
}

class NorwegianBlueBird extends Bird
{
    public function getSpeed(): float
    {
        return max(0, $this->speed - $this->getLoadFactor() * 3);
    }
}

// Usage - No type checking needed
$birds = [
    new EuropeanBird(100),
    new AfricanBird(100, false),
    new NorwegianBlueBird(100)
];

foreach ($birds as $bird) {
    echo $bird->getSpeed(); // The right implementation is called
}
```

## Benefits

- **Open for extension**: New variants require only a new subclass; existing code stays untouched
- **Compile-time guarantees**: The type system requires every subclass to provide the method
- **Focused testing**: Each subclass can be tested independently
- **Visible structure**: The hierarchy shows the set of variants at a glance
- **Encapsulated variation**: Each subclass owns its own logic
- **SOLID alignment**: Satisfies the Open/Closed, Single Responsibility, and Liskov Substitution principles

## When NOT to use

- **Simple conditionals**: If the logic is trivial and unlikely to change, leave it alone
- **Unrelated conditions**: The conditionals check unrelated properties rather than object type or state
- **Few variants**: With only 2 variants and no plans for more, polymorphism may be overkill
- **Feature flags**: Temporary toggles are better handled with decorators or strategies
- **Changing state**: If object state changes frequently, consider the State Pattern instead

## Related Refactorings

- **Strategy Pattern**: Use when you need to switch algorithms at runtime (similar mechanics, different intent)
- **State Pattern**: Use when object behavior changes with internal state transitions
- **Template Method Pattern**: Define the algorithm skeleton in the base class and let subclasses fill in the details
- **Decorator Pattern**: Add behavior dynamically without subclassing
- **Extract Method**: Often a prerequisite step before applying this refactoring

## Examples in other languages

### Java

**Before:**
```java
class Bird {
  // ...
  double getSpeed() {
    switch (type) {
      case EUROPEAN:
        return getBaseSpeed();
      case AFRICAN:
        return getBaseSpeed() - getLoadFactor() * numberOfCoconuts;
      case NORWEGIAN_BLUE:
        return (isNailed) ? 0 : getBaseSpeed(voltage);
    }
    throw new RuntimeException("Should be unreachable");
  }
}
```

**After:**
```java
abstract class Bird {
  // ...
  abstract double getSpeed();
}

class European extends Bird {
  double getSpeed() {
    return getBaseSpeed();
  }
}
class African extends Bird {
  double getSpeed() {
    return getBaseSpeed() - getLoadFactor() * numberOfCoconuts;
  }
}
class NorwegianBlue extends Bird {
  double getSpeed() {
    return (isNailed) ? 0 : getBaseSpeed(voltage);
  }
}

// Somewhere in client code
speed = bird.getSpeed();
```

### C#

**Before:**
```csharp
public class Bird
{
  // ...
  public double GetSpeed()
  {
    switch (type)
    {
      case EUROPEAN:
        return GetBaseSpeed();
      case AFRICAN:
        return GetBaseSpeed() - GetLoadFactor() * numberOfCoconuts;
      case NORWEGIAN_BLUE:
        return isNailed ? 0 : GetBaseSpeed(voltage);
      default:
        throw new Exception("Should be unreachable");
    }
  }
}
```

**After:**
```csharp
public abstract class Bird
{
  // ...
  public abstract double GetSpeed();
}

class European: Bird
{
  public override double GetSpeed()
  {
    return GetBaseSpeed();
  }
}
class African: Bird
{
  public override double GetSpeed()
  {
    return GetBaseSpeed() - GetLoadFactor() * numberOfCoconuts;
  }
}
class NorwegianBlue: Bird
{
  public override double GetSpeed()
  {
    return isNailed ? 0 : GetBaseSpeed(voltage);
  }
}

// Somewhere in client code
speed = bird.GetSpeed();
```

### Python

**Before:**
```python
class Bird:
    # ...
    def getSpeed(self):
        if self.type == EUROPEAN:
            return self.getBaseSpeed()
        elif self.type == AFRICAN:
            return self.getBaseSpeed() - self.getLoadFactor() * self.numberOfCoconuts
        elif self.type == NORWEGIAN_BLUE:
            return 0 if self.isNailed else self.getBaseSpeed(self.voltage)
        else:
            raise Exception("Should be unreachable")
```

**After:**
```python
class Bird:
    # ...
    def getSpeed(self):
        pass

class European(Bird):
    def getSpeed(self):
        return self.getBaseSpeed()

class African(Bird):
    def getSpeed(self):
        return self.getBaseSpeed() - self.getLoadFactor() * self.numberOfCoconuts

class NorwegianBlue(Bird):
    def getSpeed(self):
        return 0 if self.isNailed else self.getBaseSpeed(self.voltage)

# Somewhere in client code
speed = bird.getSpeed()
```

### TypeScript

**Before:**
```typescript
class Bird {
  // ...
  getSpeed(): number {
    switch (type) {
      case EUROPEAN:
        return getBaseSpeed();
      case AFRICAN:
        return getBaseSpeed() - getLoadFactor() * numberOfCoconuts;
      case NORWEGIAN_BLUE:
        return (isNailed) ? 0 : getBaseSpeed(voltage);
    }
    throw new Error("Should be unreachable");
  }
}
```

**After:**
```typescript
abstract class Bird {
  // ...
  abstract getSpeed(): number;
}

class European extends Bird {
  getSpeed(): number {
    return getBaseSpeed();
  }
}
class African extends Bird {
  getSpeed(): number {
    return getBaseSpeed() - getLoadFactor() * numberOfCoconuts;
  }
}
class NorwegianBlue extends Bird {
  getSpeed(): number {
    return (isNailed) ? 0 : getBaseSpeed(voltage);
  }
}

// Somewhere in client code
let speed = bird.getSpeed();
```

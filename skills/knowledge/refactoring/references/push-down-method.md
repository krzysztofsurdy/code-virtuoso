# Push Down Method

## Overview

Push Down Method moves a method from a superclass into the subclass or subclasses that call it. When a parent class carries behavior that only some of its children need, pushing the method down removes irrelevant operations from the parent. Each class stays focused on what it does.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Apply Push Down Method when:

- A method was designed for general use but only one or a few subclasses need it
- Changes to the hierarchy or removed features have left a method orphaned in the parent
- The parent exposes behavior that does not apply to all descendants
- Subclasses inherit methods they never call, which is the Refused Bequest smell

## Mechanics

1. **Declare the method in the target subclass**: add the signature and implementation to the subclass that needs it.
2. **Remove the method from the superclass**: delete the original from the parent class.
3. **Update all references**: make sure every call to the method goes through the subclass where it now lives.
4. **Verify type safety**: check that all usages occur within the intended subclass or after proper type narrowing.

## Before and after (PHP 8.3+)

### Before

```php
abstract class Vehicle
{
    protected string $model;
    protected float $price;

    public function __construct(string $model, float $price)
    {
        $this->model = $model;
        $this->price = $price;
    }

    /**
     * Only used by Car subclass, not by Motorcycle
     */
    public function getNumberOfDoors(): int
    {
        return 4;
    }

    abstract public function getMaxSpeed(): float;
}

final class Car extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 200.0;
    }
}

final class Motorcycle extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 220.0;
    }
}
```

### After

```php
abstract class Vehicle
{
    protected string $model;
    protected float $price;

    public function __construct(string $model, float $price)
    {
        $this->model = $model;
        $this->price = $price;
    }

    abstract public function getMaxSpeed(): float;
}

final class Car extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 200.0;
    }

    public function getNumberOfDoors(): int
    {
        return 4;
    }
}

final class Motorcycle extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 220.0;
    }
}
```

## Benefits

- **Focused parent class**: the superclass exposes only behavior common to all children.
- **Cleaner abstractions**: irrelevant methods no longer appear on unrelated subclasses.
- **Less confusion**: developers are not puzzled by inherited methods that mean nothing for some classes.
- **Precise encapsulation**: each class publishes the interface it supports.
- **Localized impact**: later changes to the method affect only the subclass that owns it.

## When not to use

- **Speculation**: do not push down methods based on guesses about future usage.
- **Duplication**: if several unrelated subclasses need the method, keep it in the parent.
- **Template Method pattern**: when a parent method defines a skeleton that subclasses customize, keep it in the parent.
- **Polymorphic behavior**: if the method is part of a polymorphic contract, pushing it down breaks the Liskov Substitution Principle.
- **Shared functionality**: when several subclasses share the method, duplicating it adds maintenance burden.

## Related refactorings

- **Pull Up Method**: the inverse operation. It moves methods from subclasses to the parent class.
- **Push Down Field**: the same idea applied to fields instead of methods.
- **Extract Subclass**: often paired with Push Down Method to create specialized subclasses.
- **Replace Type Code with Subclasses**: may involve pushing down methods to create type-specific behavior.

## Examples in other languages

### Java

**Before:**

```java
class Employee {
    int getQuota() {
        // ...
    }
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

**After:**

```java
class Employee {
}

class Salesman extends Employee {
    int getQuota() {
        // ...
    }
}

class Engineer extends Employee {
}
```

### C#

**Before:**

```csharp
class Employee
{
    int GetQuota()
    {
        // ...
    }
}

class Salesman : Employee
{
}

class Engineer : Employee
{
}
```

**After:**

```csharp
class Employee
{
}

class Salesman : Employee
{
    int GetQuota()
    {
        // ...
    }
}

class Engineer : Employee
{
}
```

### Python

**Before:**

```python
class Employee:
    def get_quota(self) -> int:
        # ...

class Salesman(Employee):
    pass

class Engineer(Employee):
    pass
```

**After:**

```python
class Employee:
    pass

class Salesman(Employee):
    def get_quota(self) -> int:
        # ...

class Engineer(Employee):
    pass
```

### TypeScript

**Before:**

```typescript
class Employee {
    getQuota(): number {
        // ...
    }
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

**After:**

```typescript
class Employee {
}

class Salesman extends Employee {
    getQuota(): number {
        // ...
    }
}

class Engineer extends Employee {
}
```

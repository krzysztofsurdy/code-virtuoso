# Push Down Field

## Overview

Push Down Field moves a field from a superclass into the subclasses that use it. When a field declared in the parent is relevant to only some children, moving it narrows the parent's scope. Each class then holds only the state it needs.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after example](#before-and-after-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Fields sometimes land in a parent class during early design or in anticipation of future needs. They stay there even after only some subclasses turn out to need them. A field that sits unused in most children clutters the parent interface, adds misleading state, and couples unrelated parts of the hierarchy. Moving it down to the subclasses that depend on it:

- Removes baggage from classes that never touch the field
- Makes each class's responsibilities visible from its declaration
- Limits the parent to the concerns that are shared

## Mechanics

1. Declare the field in all subclasses that use it.
2. Remove the field from the superclass.
3. Update any methods that reference the field.

## Before and after example

### Before (PHP 8.3+)

```php
abstract class Vehicle
{
    protected string $cargoCapacity;

    public function getCargoCapacity(): string
    {
        return $this->cargoCapacity;
    }
}

class Truck extends Vehicle
{
    public function loadCargo(string $cargo): void
    {
        // Uses cargoCapacity
    }
}

class Car extends Vehicle
{
    // Does not use cargoCapacity
}

class Bicycle extends Vehicle
{
    // Does not use cargoCapacity
}
```

### After (PHP 8.3+)

```php
abstract class Vehicle
{
    // cargoCapacity removed
}

class Truck extends Vehicle
{
    protected string $cargoCapacity;

    public function getCargoCapacity(): string
    {
        return $this->cargoCapacity;
    }

    public function loadCargo(string $cargo): void
    {
        // Uses cargoCapacity
    }
}

class Car extends Vehicle
{
    // No unnecessary cargoCapacity
}

class Bicycle extends Vehicle
{
    // No unnecessary cargoCapacity
}
```

## Benefits

- **Tighter cohesion**: each class holds only the state it works with, so its purpose is clear.
- **Lighter parent**: the superclass no longer carries fields that some children ignore.
- **Explicit dependencies**: it is clear which subclasses rely on a given field.
- **Independent evolution**: subclasses can change field types or access patterns without affecting siblings.
- **Focused contracts**: the parent's interface reflects only shared behavior.

## When not to use

- The field is used by all or most subclasses. It belongs in the parent.
- The field is core state that all subclasses need. Review the hierarchy design instead.
- You have not identified which subclasses use the field.
- Removing it from the parent would break existing client code that expects the field.

## Related refactorings

- **Pull Up Field** (opposite): move a field from subclasses to the parent class.
- **Push Down Method**: move methods that only specific subclasses use.
- **Extract Subclass**: create new subclasses to hold specific fields and methods.
- **Refused Bequest**: the code smell where subclasses do not use parent functionality.

## Examples in other languages

### Java

**Before:**

```java
class Employee {
    String quota;
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
    String quota;
}

class Engineer extends Employee {
}
```

### C#

**Before:**

```csharp
class Employee
{
    string quota;
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
    string quota;
}

class Engineer : Employee
{
}
```

### Python

**Before:**

```python
class Employee:
    def __init__(self):
        self.quota = None

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
    def __init__(self):
        super().__init__()
        self.quota = None

class Engineer(Employee):
    pass
```

### TypeScript

**Before:**

```typescript
class Employee {
    quota: string;
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
    quota: string;
}

class Engineer extends Employee {
}
```

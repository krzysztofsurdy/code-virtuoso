# Collapse Hierarchy

## Overview

Collapse Hierarchy is a refactoring technique that eliminates unnecessary class hierarchies by merging subclasses with their superclasses when they have become practically identical. This refactoring simplifies code structure and reduces cognitive overhead when class hierarchies no longer provide meaningful distinction between parent and child classes.

## Motivation

Over time, as a program evolves, subclasses may lose their distinct functionality through feature removals or method relocations. The superclass and subclass become nearly indistinguishable, making the hierarchy redundant and confusing. Collapsing the hierarchy removes this unnecessary complexity and makes the codebase easier to understand and maintain.

## Mechanics

1. Identify a superclass and subclass that have become practically identical
2. Use Pull Up (if removing the subclass) or Push Down (if removing the superclass) to consolidate members
3. Update all references to use the remaining class
4. Remove the empty class
5. Test thoroughly to ensure no behavioral changes

## Before/After Examples

### Before: Unnecessary Vehicle Hierarchy

```php
<?php

declare(strict_types=1);

abstract class Vehicle
{
    public function __construct(
        private readonly string $brand,
        private readonly string $model,
    ) {}

    public function getBrand(): string
    {
        return $this->brand;
    }

    public function getModel(): string
    {
        return $this->model;
    }

    abstract public function start(): void;
}

final class Car extends Vehicle
{
    public function start(): void
    {
        echo "Starting car engine...";
    }
}

final class Truck extends Vehicle
{
    public function start(): void
    {
        echo "Starting truck engine...";
    }
}
```

### After: Collapsed Into Single Class with Enum

```php
<?php

declare(strict_types=1);

enum VehicleType
{
    case Car;
    case Truck;
}

final readonly class Vehicle
{
    public function __construct(
        private string $brand,
        private string $model,
        private VehicleType $type,
    ) {}

    public function getBrand(): string
    {
        return $this->brand;
    }

    public function getModel(): string
    {
        return $this->model;
    }

    public function getType(): VehicleType
    {
        return $this->type;
    }

    public function start(): void
    {
        match ($this->type) {
            VehicleType::Car => echo "Starting car engine...",
            VehicleType::Truck => echo "Starting truck engine...",
        };
    }
}
```

## Benefits

- **Reduced Complexity**: Fewer classes mean less cognitive load and fewer potential points of failure
- **Improved Clarity**: Methods are centralized in a single location rather than scattered across a hierarchy
- **Easier Maintenance**: Changes to shared functionality occur in one place instead of multiple classes
- **Simplified Navigation**: Developers don't need to traverse inheritance chains to understand the code

## When NOT to Use

- **Multiple Subclasses**: If you have multiple subclasses, collapsing could force unrelated classes to share an inappropriate parent, violating the Liskov Substitution Principle
- **Distinct Behaviors**: If subclasses provide significantly different behavior or have different responsibilities, preserve the hierarchy
- **API Compatibility**: If the class hierarchy is part of a public API, collapsing may break downstream code

## Related Refactorings

- **Pull Up Field/Method**: Move members from subclass to superclass
- **Push Down Field/Method**: Move members from superclass to subclass
- **Extract Superclass**: Create a common superclass for related classes
- **Replace Type Code with Subclasses**: Opposite refactoring that creates subclasses for type variants
- **Replace Type Code with State/Strategy**: Alternative to introducing subclasses

## Examples in Other Languages

### Java

**Before:**

```java
class Employee {
    String getName() { /* ... */ }
    int getSalary() { /* ... */ }
}

class Salesman extends Employee {
    // No additional behavior - hierarchy is redundant
}
```

**After:**

```java
class Employee {
    String getName() { /* ... */ }
    int getSalary() { /* ... */ }
}
// Salesman class removed entirely
```

### C#

**Before:**

```csharp
class Employee
{
    string GetName() { /* ... */ }
    int GetSalary() { /* ... */ }
}

class Salesman : Employee
{
    // No additional behavior
}
```

**After:**

```csharp
class Employee
{
    string GetName() { /* ... */ }
    int GetSalary() { /* ... */ }
}
// Salesman class removed entirely
```

### Python

**Before:**

```python
class Employee:
    def get_name(self) -> str:
        # ...

    def get_salary(self) -> int:
        # ...

class Salesman(Employee):
    pass  # No additional behavior
```

**After:**

```python
class Employee:
    def get_name(self) -> str:
        # ...

    def get_salary(self) -> int:
        # ...

# Salesman class removed entirely
```

### TypeScript

**Before:**

```typescript
class Employee {
    getName(): string { /* ... */ }
    getSalary(): number { /* ... */ }
}

class Salesman extends Employee {
    // No additional behavior
}
```

**After:**

```typescript
class Employee {
    getName(): string { /* ... */ }
    getSalary(): number { /* ... */ }
}
// Salesman class removed entirely
```

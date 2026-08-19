# Collapse Hierarchy

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after](#before-and-after)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Collapse Hierarchy merges a subclass into its superclass (or the reverse) when the two have become so similar that separate classes add no value. It removes structure that no longer has a purpose.

## Motivation

Over time, subclasses can lose the behavior that justified them. Methods get moved and features get removed until parent and child are nearly identical. At that point the hierarchy is noise: readers jump between classes and learn nothing. Merging the two into one class makes the code simpler.

## Mechanics

1. Identify a parent-child pair where the subclass adds little or no distinct behavior
2. Pull members up into the superclass or push them down into the subclass, depending on which class you want to keep
3. Update all references throughout the codebase to use the surviving class
4. Delete the now-empty class
5. Run the tests to confirm behavior is unchanged

## Before and after

### Before: unnecessary Vehicle hierarchy

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

### After: collapsed into a single class with an enum

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

- **Less structure**: Fewer classes mean less indirection and fewer files to manage
- **Centralized logic**: All behavior lives in one place instead of across a hierarchy
- **Lower maintenance cost**: Changes happen in one class, with no coordination between parent and child
- **Faster reading**: Developers can follow the design without tracing inheritance chains

## When NOT to use

- **Multiple subclasses with real differences**: Merging would force unrelated behaviors into one class and violate the Liskov Substitution Principle
- **Meaningful behavioral variation**: If subclasses carry distinct responsibilities, the hierarchy is earning its keep
- **Public API stability**: Collapsing classes that are part of an external API can break consumers

## Related refactorings

- **Pull Up Field/Method**: Moves members from subclass to superclass
- **Push Down Field/Method**: Moves members from superclass to subclass
- **Extract Superclass**: The opposite direction: creates a hierarchy where none existed
- **Replace Type Code with Subclasses**: Adds subclasses to represent type variants
- **Replace Type Code with State/Strategy**: An alternative to subclassing for behavioral variation

## Examples in other languages

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

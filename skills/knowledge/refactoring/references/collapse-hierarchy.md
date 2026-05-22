# Collapse Hierarchy

## Overview

Collapse Hierarchy merges a subclass into its superclass (or vice versa) when the two have become so similar that maintaining separate classes provides no value. The goal is to remove structural overhead that no longer serves a purpose.

## Motivation

As a codebase evolves, subclasses sometimes lose the distinctive behavior that justified their existence. Methods get moved, features get removed, and eventually the parent and child become nearly identical. At that point the hierarchy is noise - it forces readers to navigate between classes without gaining any insight. Collapsing the two into one class restores simplicity.

## Mechanics

1. Identify a parent-child pair where the subclass adds little or no distinct behavior
2. Pull members up into the superclass or push them down into the subclass, depending on which class you want to keep
3. Update all references throughout the codebase to use the surviving class
4. Delete the now-empty class
5. Run your tests to confirm nothing has changed behaviorally

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

- **Less Structural Overhead**: Fewer classes means less indirection and fewer files to manage
- **Centralized Logic**: All behavior lives in one place instead of being scattered across a hierarchy
- **Lower Maintenance Cost**: Modifications happen in a single class rather than requiring coordination between parent and child
- **Faster Comprehension**: Developers understand the design without tracing through inheritance chains

## When NOT to Use

- **Multiple subclasses with real differences**: Merging would force unrelated behaviors into one class, violating the Liskov Substitution Principle
- **Meaningful behavioral variation**: If subclasses carry genuinely distinct responsibilities, the hierarchy is earning its keep
- **Public API stability**: Collapsing classes that are part of an external API may break consumers

## Related Refactorings

- **Pull Up Field/Method**: Moves members from subclass to superclass
- **Push Down Field/Method**: Moves members from superclass to subclass
- **Extract Superclass**: The opposite direction - creating a hierarchy where none existed
- **Replace Type Code with Subclasses**: Introduces subclasses to represent type variants
- **Replace Type Code with State/Strategy**: An alternative to subclassing for behavioral variation

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

# Push Down Field

## Overview

Push Down Field is a refactoring technique that relocates a field from a superclass to the specific subclasses that actually use it. When a field is declared at the parent level but utilized by only certain child classes, this refactoring ensures better code organization and clarity.

## Motivation

This situation arises when planned features don't materialize as expected or when functionality is extracted from a class hierarchy. A field in the parent class that serves only some subclasses creates unnecessary coupling and reduces coherency. By moving the field down to the subclasses that actually need it, you:

- Eliminate unnecessary dependencies between parent and child classes
- Make class relationships clearer and more explicit
- Reduce the interface of the parent class

## Mechanics

The refactoring process is straightforward:

1. Declare the field in all subclasses that use it
2. Remove the field from the superclass
3. Update any methods that reference the field

## Before/After Example

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

- **Enhanced Coherency**: Fields reside where they're genuinely needed, improving class organization and clarity
- **Reduced Coupling**: The parent class is no longer unnecessarily coupled to subclass-specific functionality
- **Clearer Intent**: Makes it explicit which subclasses depend on which fields
- **Independent Evolution**: Subclasses can independently evolve their field implementations and usage patterns
- **Simpler Contracts**: The parent class interface becomes smaller and more focused on truly shared behavior

## When NOT to Use

- When the field is actually used by all or most subclasses (it belongs in the parent)
- When the field represents core state that all subclasses need (consider the class hierarchy design)
- When you haven't identified which subclasses actually use the field
- When removing from parent would break existing client code that expects the field

## Related Refactorings

- **Pull Up Field** (opposite): Move a field from subclasses to the parent class
- **Push Down Method**: Move methods that are only used by specific subclasses
- **Extract Subclass**: Create new subclasses to hold specific fields and methods
- **Refused Bequest**: Addresses the code smell where subclasses don't use parent functionality

## Examples in Other Languages

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

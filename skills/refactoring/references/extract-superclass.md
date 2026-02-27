## Overview

Extract Superclass is a refactoring technique that consolidates duplicate code and shared functionality from multiple classes into a single parent class. When two or more classes share common fields and methods, creating a superclass allows you to move this duplicated code to one location, improving maintainability and reducing code duplication.

## Motivation

Code duplication often appears when classes perform similar tasks. Rather than allowing this duplication to persist and become harder to maintain, Extract Superclass provides a structured approach to consolidate shared functionality through inheritance. This is especially useful when you discover parallel development has created similar implementations across your codebase.

Benefits of recognizing and refactoring duplicate code early:
- Reduces maintenance burden by centralizing changes
- Makes relationships between classes explicit
- Improves code readability and understanding
- Establishes a foundation for future shared functionality

## Mechanics

The refactoring process follows these steps:

1. **Create a superclass** - Establish a new abstract parent class
2. **Move fields upward** - Use Pull Up Field to move common attributes to the superclass first
3. **Move methods upward** - Use Pull Up Method to migrate shared methods
4. **Move constructors** - Use Pull Up Constructor Body to consolidate initialization logic
5. **Update client code** - Replace direct subclass references with the superclass where appropriate

The order matters: move fields before methods since methods may depend on fields.

## Before and After

### Before: Duplicate Code in Two Classes

```php
<?php declare(strict_types=1);

class Employee
{
    public function __construct(
        private readonly string $name,
        private readonly string $email,
        private readonly float $salary
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function calculateTax(): float
    {
        return $this->salary * 0.2;
    }
}

class Contractor
{
    public function __construct(
        private readonly string $name,
        private readonly string $email,
        private readonly float $hourlyRate
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function calculateTax(): float
    {
        return $this->hourlyRate * 40 * 52 * 0.15;
    }
}
```

### After: Extracted Superclass

```php
<?php declare(strict_types=1);

abstract class Person
{
    public function __construct(
        protected readonly string $name,
        protected readonly string $email
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    abstract public function calculateTax(): float;
}

final class Employee extends Person
{
    public function __construct(
        string $name,
        string $email,
        private readonly float $salary
    ) {
        parent::__construct($name, $email);
    }

    public function calculateTax(): float
    {
        return $this->salary * 0.2;
    }
}

final class Contractor extends Person
{
    public function __construct(
        string $name,
        string $email,
        private readonly float $hourlyRate
    ) {
        parent::__construct($name, $email);
    }

    public function calculateTax(): float
    {
        return $this->hourlyRate * 40 * 52 * 0.15;
    }
}
```

## Benefits

- **Eliminates Duplication** - Common code exists in a single location, reducing maintenance overhead
- **Improves Maintainability** - Changes to shared behavior only need to be made once
- **Clarifies Relationships** - The inheritance hierarchy makes class relationships explicit
- **Supports Extension** - The abstract superclass provides a foundation for new subclasses
- **Enables Polymorphism** - Client code can work with the superclass, allowing flexible implementations

## When NOT to Use

- **Multiple Inheritance Conflicts** - If subclasses already inherit from different superclasses, multiple inheritance may not be the solution
- **Unrelated Classes** - Force-fitting unrelated classes into a hierarchy creates artificial relationships
- **Composition is Better** - Some shared functionality may be better handled through composition and dependency injection
- **Single Class** - If only one class uses the functionality, extraction isn't necessary
- **Conflicting Semantics** - If the shared code has different meanings in different contexts, a superclass may confuse intent

## Related Refactorings

- **Extract Interface** - Create an interface instead when defining a contract rather than sharing implementation
- **Extract Subclass** - The inverse operation; extract specialized behavior into subclasses
- **Pull Up Field/Method** - Individual steps in the Extract Superclass process
- **Move Method** - Move functionality between classes without creating a hierarchy

## Examples in Other Languages

### Java

**Before:**

```java
class Employee {
    private String name;
    private int annualCost;

    String getName() { return name; }
    int getAnnualCost() { return annualCost; }
}

class Department {
    private String name;
    private List<Employee> staff;

    String getName() { return name; }
    int getAnnualCost() {
        return staff.stream().mapToInt(Employee::getAnnualCost).sum();
    }
}
```

**After:**

```java
abstract class Party {
    protected String name;

    String getName() { return name; }
    abstract int getAnnualCost();
}

class Employee extends Party {
    private int annualCost;

    int getAnnualCost() { return annualCost; }
}

class Department extends Party {
    private List<Employee> staff;

    int getAnnualCost() {
        return staff.stream().mapToInt(Employee::getAnnualCost).sum();
    }
}
```

### C#

**Before:**

```csharp
class Employee
{
    private string name;
    private int annualCost;

    string GetName() => name;
    int GetAnnualCost() => annualCost;
}

class Department
{
    private string name;
    private List<Employee> staff;

    string GetName() => name;
    int GetAnnualCost() => staff.Sum(e => e.GetAnnualCost());
}
```

**After:**

```csharp
abstract class Party
{
    protected string name;

    string GetName() => name;
    abstract int GetAnnualCost();
}

class Employee : Party
{
    private int annualCost;

    override int GetAnnualCost() => annualCost;
}

class Department : Party
{
    private List<Employee> staff;

    override int GetAnnualCost() => staff.Sum(e => e.GetAnnualCost());
}
```

### Python

**Before:**

```python
class Employee:
    def __init__(self, name: str, annual_cost: int):
        self.name = name
        self.annual_cost = annual_cost

    def get_name(self) -> str:
        return self.name

    def get_annual_cost(self) -> int:
        return self.annual_cost

class Department:
    def __init__(self, name: str, staff: list):
        self.name = name
        self.staff = staff

    def get_name(self) -> str:
        return self.name

    def get_annual_cost(self) -> int:
        return sum(e.get_annual_cost() for e in self.staff)
```

**After:**

```python
from abc import ABC, abstractmethod

class Party(ABC):
    def __init__(self, name: str):
        self.name = name

    def get_name(self) -> str:
        return self.name

    @abstractmethod
    def get_annual_cost(self) -> int:
        pass

class Employee(Party):
    def __init__(self, name: str, annual_cost: int):
        super().__init__(name)
        self.annual_cost = annual_cost

    def get_annual_cost(self) -> int:
        return self.annual_cost

class Department(Party):
    def __init__(self, name: str, staff: list):
        super().__init__(name)
        self.staff = staff

    def get_annual_cost(self) -> int:
        return sum(e.get_annual_cost() for e in self.staff)
```

### TypeScript

**Before:**

```typescript
class Employee {
    constructor(
        private name: string,
        private annualCost: number,
    ) {}

    getName(): string { return this.name; }
    getAnnualCost(): number { return this.annualCost; }
}

class Department {
    constructor(
        private name: string,
        private staff: Employee[],
    ) {}

    getName(): string { return this.name; }
    getAnnualCost(): number {
        return this.staff.reduce((sum, e) => sum + e.getAnnualCost(), 0);
    }
}
```

**After:**

```typescript
abstract class Party {
    constructor(protected name: string) {}

    getName(): string { return this.name; }
    abstract getAnnualCost(): number;
}

class Employee extends Party {
    constructor(name: string, private annualCost: number) {
        super(name);
    }

    getAnnualCost(): number { return this.annualCost; }
}

class Department extends Party {
    constructor(name: string, private staff: Employee[]) {
        super(name);
    }

    getAnnualCost(): number {
        return this.staff.reduce((sum, e) => sum + e.getAnnualCost(), 0);
    }
}
```

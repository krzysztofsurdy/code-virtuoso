## Overview

Extract Superclass pulls shared fields and methods out of two or more classes and into a newly created parent class. When independent classes carry duplicate code that performs similar tasks, introducing a common superclass eliminates the repetition and makes the relationship between the classes explicit.

## Motivation

Duplicate code across classes is a maintenance liability. When the shared logic needs to change, every copy must be updated in lockstep, and missed updates lead to inconsistencies. Extract Superclass addresses this by:

- Centralizing shared behavior in a single location
- Making the structural relationship between the classes visible
- Providing a stable base for future shared functionality
- Reducing the total amount of code to read and maintain

## Mechanics

Follow this order to avoid breaking intermediate states:

1. **Create the superclass** - define an abstract parent class
2. **Pull up fields first** - move shared attributes into the superclass (methods may depend on them)
3. **Pull up methods** - migrate identical methods to the parent
4. **Pull up constructor logic** - consolidate shared initialization
5. **Update client code** - where appropriate, reference the superclass type instead of individual subclasses

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

- **Single Source of Truth** - shared logic lives in one place, not scattered across classes
- **Cheaper Maintenance** - changes to common behavior require a single edit
- **Visible Relationships** - the inheritance hierarchy documents how classes relate
- **Foundation for Growth** - new subclasses can extend the superclass without duplicating boilerplate
- **Polymorphic Flexibility** - client code can accept the superclass type, enabling substitution

## When NOT to Use

- **Existing inheritance conflicts** - if subclasses already extend a different parent, adding another is not possible in single-inheritance languages
- **Superficial similarity** - if the shared code looks the same but serves different purposes, a forced hierarchy will mislead readers
- **Composition is a better fit** - when the shared functionality is a capability rather than an identity, inject it via composition or traits
- **Only one class** - if the duplication has not yet appeared in a second class, the extraction is premature
- **Divergent semantics** - when the same method name means different things in different classes, a shared superclass obscures that difference

## Related Refactorings

- **Extract Interface** - use when you need a shared contract without shared implementation
- **Extract Subclass** - the reverse direction: pulling specialized behavior down into a child class
- **Pull Up Field/Method** - the individual steps that make up this refactoring
- **Move Method** - shifts behavior between classes without introducing a hierarchy

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

# Pull Up Field Refactoring

## Overview

Pull Up Field moves a field that appears in several subclasses into their common superclass. When two or more child classes declare the same field for the same purpose, one declaration in the parent removes the redundancy and gives the shared state a single home.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after PHP 8.3+ code](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Repeated field declarations across sibling classes have several downsides:

- **Scattered updates**: renaming the field or changing its type must be done in every subclass.
- **Silent divergence**: subclasses may handle the field differently over time, which causes subtle bugs.
- **Blocked consolidation**: methods that depend on the duplicated field cannot be pulled up until the field is consolidated.
- **Obscured intent**: no single class shows that the field is shared across the hierarchy.

Moving the field into the parent gives one definition that all subclasses inherit. It enables further refactorings and shows that the data is shared.

## Mechanics

1. **Analyze the fields**: verify that the fields in different subclasses serve the same purpose.
2. **Standardize naming**: if the fields have different names, choose one name.
3. **Declare in the superclass**: add the field to the parent class with suitable visibility (typically `protected`).
4. **Remove from subclasses**: delete the field declarations from all subclasses.
5. **Update references**: check that all code refers to the inherited field.
6. **Consider encapsulation**: apply Self Encapsulate Field to hide the field behind accessor methods.

## Before and after PHP 8.3+ code

### Before: duplicate fields in subclasses

```php
abstract class Employee
{
    protected string $name;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    abstract public function calculateSalary(): float;
}

class Developer extends Employee
{
    private string $department;
    private int $yearsExperience;
    private array $skills;

    public function __construct(string $name, string $department, int $yearsExperience, array $skills)
    {
        parent::__construct($name);
        $this->department = $department;
        $this->yearsExperience = $yearsExperience;
        $this->skills = $skills;
    }

    public function calculateSalary(): float
    {
        return 50000 + ($this->yearsExperience * 2000);
    }
}

class Designer extends Employee
{
    private string $department;
    private int $yearsExperience;
    private array $specializations;

    public function __construct(string $name, string $department, int $yearsExperience, array $specializations)
    {
        parent::__construct($name);
        $this->department = $department;
        $this->yearsExperience = $yearsExperience;
        $this->specializations = $specializations;
    }

    public function calculateSalary(): float
    {
        return 45000 + ($this->yearsExperience * 1500);
    }
}
```

### After: fields pulled up to the superclass

```php
abstract class Employee
{
    protected string $name;
    protected string $department;
    protected int $yearsExperience;

    public function __construct(
        string $name,
        string $department,
        int $yearsExperience
    ) {
        $this->name = $name;
        $this->department = $department;
        $this->yearsExperience = $yearsExperience;
    }

    abstract public function calculateSalary(): float;
}

class Developer extends Employee
{
    private array $skills;

    public function __construct(
        string $name,
        string $department,
        int $yearsExperience,
        array $skills
    ) {
        parent::__construct($name, $department, $yearsExperience);
        $this->skills = $skills;
    }

    public function calculateSalary(): float
    {
        return 50000 + ($this->yearsExperience * 2000);
    }
}

class Designer extends Employee
{
    private array $specializations;

    public function __construct(
        string $name,
        string $department,
        int $yearsExperience,
        array $specializations
    ) {
        parent::__construct($name, $department, $yearsExperience);
        $this->specializations = $specializations;
    }

    public function calculateSalary(): float
    {
        return 45000 + ($this->yearsExperience * 1500);
    }
}
```

## Benefits

- **Single definition**: one field declaration replaces several identical ones.
- **Uniform behavior**: all subclasses share the same storage and access rules.
- **Consistent types**: one declaration enforces one type across the hierarchy.
- **Unlocks further refactoring**: methods that use the field can be pulled up too.
- **Visible hierarchy design**: the parent class shows which state is shared.

## When not to use

- **Different purposes**: if subclasses use similarly named fields for different purposes, pulling up creates false cohesion.
- **Different initialization logic**: when subclasses initialize the same field differently, consolidation may add complexity.
- **Fields used by few subclasses**: do not pull up fields used by only one or two subclasses. Extract a new subclass instead.
- **Conditional usage**: if not every subclass needs the field, consider composition or an intermediate abstract class.

## Related refactorings

- **Pull Up Method**: consolidate duplicate methods the same way as fields.
- **Push Down Field**: the opposite operation, for fields that should move to subclasses.
- **Extract Superclass**: create a new superclass when the duplication spans unrelated classes.
- **Self Encapsulate Field**: hide the field behind getter and setter methods for more control.
- **Replace Data with Object**: convert primitive fields to dedicated objects with richer behavior.

## Examples in other languages

### Java

**Before:**

```java
class Employee {
    String name;
}

class Salesman extends Employee {
    String department;
}

class Engineer extends Employee {
    String department;
}
```

**After:**

```java
class Employee {
    String name;
    String department;
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

### C#

**Before:**

```csharp
class Employee
{
    string name;
}

class Salesman : Employee
{
    string department;
}

class Engineer : Employee
{
    string department;
}
```

**After:**

```csharp
class Employee
{
    string name;
    string department;
}

class Salesman : Employee
{
}

class Engineer : Employee
{
}
```

### Python

**Before:**

```python
class Employee:
    def __init__(self, name: str):
        self.name = name

class Salesman(Employee):
    def __init__(self, name: str, department: str):
        super().__init__(name)
        self.department = department

class Engineer(Employee):
    def __init__(self, name: str, department: str):
        super().__init__(name)
        self.department = department
```

**After:**

```python
class Employee:
    def __init__(self, name: str, department: str):
        self.name = name
        self.department = department

class Salesman(Employee):
    pass

class Engineer(Employee):
    pass
```

### TypeScript

**Before:**

```typescript
class Employee {
    name: string;
}

class Salesman extends Employee {
    department: string;
}

class Engineer extends Employee {
    department: string;
}
```

**After:**

```typescript
class Employee {
    name: string;
    department: string;
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

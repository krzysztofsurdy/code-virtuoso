# Pull Up Field Refactoring

## Overview

Pull Up Field is a refactoring technique that consolidates duplicate fields by moving them from multiple subclasses to their shared superclass. When two or more subclasses contain identical fields, this refactoring eliminates duplication by centralizing the field definition in the parent class.

## Motivation

Code duplication across class hierarchies creates several problems:

- **Maintenance burden**: Changes to a field must be applied in multiple locations
- **Inconsistency risk**: Subclasses may handle the same field differently over time
- **Reduced cohesion**: Related state is scattered across the hierarchy
- **Blocks further consolidation**: Other duplicate methods cannot be easily moved up without addressing field duplication first

By pulling fields up to the superclass, you create a single source of truth for shared state and enable further refactorings.

## Mechanics

1. **Analyze the fields**: Verify that the fields in different subclasses serve identical purposes
2. **Standardize naming**: If fields have different names, choose a consistent name
3. **Declare in superclass**: Add the field to the parent class with appropriate visibility (typically `protected`)
4. **Remove from subclasses**: Delete the field declarations from all subclasses
5. **Update references**: Ensure all code correctly references the inherited field
6. **Consider encapsulation**: Apply Self Encapsulate Field to hide the field behind accessor methods

## Before/After PHP 8.3+ Code

### Before: Duplicate Fields in Subclasses

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

### After: Fields Pulled Up to Superclass

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

- **Eliminates duplication**: Removes redundant field declarations across subclasses
- **Improves maintainability**: Changes to shared fields only need to be made once
- **Strengthens type safety**: All instances use the same field definition
- **Enables further refactoring**: Makes it easier to pull up methods that depend on these fields
- **Clarifies class hierarchy**: Expresses the intended shared state more explicitly

## When NOT to Use

- **Different purposes**: If subclasses use similarly-named fields for different purposes, pulling up creates false cohesion
- **Different initialization logic**: When subclasses initialize the same field differently, consolidation may add unnecessary complexity
- **Temporary fields**: Avoid pulling up fields used by only one or two subclasses; extract a new subclass instead
- **Conditional usage**: If not all subclasses actually need the field, consider using composition or creating intermediate abstract classes

## Related Refactorings

- **Pull Up Method**: Consolidate duplicate methods the same way as fields
- **Push Down Field**: The opposite operation when fields need to be moved to subclasses
- **Extract Superclass**: Create a new superclass when duplication spans unrelated classes
- **Self Encapsulate Field**: Hide the field behind getter/setter methods for better control
- **Replace Data with Object**: Convert primitive fields to dedicated objects for richer behavior

## Examples in Other Languages

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

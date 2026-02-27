# Extract Subclass Refactoring

## Overview

Extract Subclass is a refactoring technique that creates a new subclass when a parent class contains features used only in specific scenarios. It offloads special-case logic into a dedicated subclass while maintaining proper class hierarchy, reducing complexity in the parent class.

## Motivation

Classes often accumulate features that serve only specific use cases. Rather than cluttering a class with infrequently-used fields and methods, Extract Subclass allows you to:

- Remove special-case logic from the parent class
- Create dedicated subclasses for specific variations
- Improve code clarity and maintainability
- Enable multiple subclasses for different special cases

## Mechanics

1. Create a new subclass from the target class
2. Copy specialized fields and methods to the subclass
3. Remove specialized code from the parent class
4. Replace instances using the specialized features with the subclass
5. Verify all tests pass

## Before/After Examples

### Before: Employee Class with Manager-Specific Logic

```php
<?php
declare(strict_types=1);

class Employee
{
    public function __construct(
        private string $name,
        private float $salary,
        private ?string $managedDepartment = null,
        private float $responsibilityBonus = 0.0,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }

    public function getManagedDepartment(): ?string
    {
        return $this->managedDepartment;
    }

    public function getResponsibilityBonus(): float
    {
        return $this->responsibilityBonus;
    }

    public function setManagedDepartment(string $department): void
    {
        $this->managedDepartment = $department;
    }

    public function setResponsibilityBonus(float $bonus): void
    {
        $this->responsibilityBonus = $bonus;
    }
}
```

### After: Separate Manager Subclass

```php
<?php
declare(strict_types=1);

class Employee
{
    public function __construct(
        private readonly string $name,
        private readonly float $salary,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }
}

class Manager extends Employee
{
    public function __construct(
        string $name,
        float $salary,
        private readonly string $managedDepartment,
        private readonly float $responsibilityBonus = 0.0,
    ) {
        parent::__construct($name, $salary);
    }

    public function getManagedDepartment(): string
    {
        return $this->managedDepartment;
    }

    public function getResponsibilityBonus(): float
    {
        return $this->responsibilityBonus;
    }
}

// Usage
$employee = new Employee('Alice', 50000);
$manager = new Manager('Bob', 75000, 'Engineering', 5000);
```

## Benefits

- **Cleaner Parent Class**: Removes special-case fields and methods from the parent class
- **Clear Intent**: Manager as a separate class makes the code's intent explicit
- **Type Safety**: PHP 8.3 readonly properties provide immutability and clarity
- **Scalability**: Easy to add multiple subclasses for different variations
- **Single Responsibility**: Each class has one reason to change

## When NOT to Use

- **Multiple Independent Variations**: If your class needs to handle multiple dimensions (e.g., size AND fur type), composition with Strategy pattern is better
- **Better Solutions Exist**: When composition or inheritance through other patterns would be clearer
- **Deep Hierarchies**: Don't create extract-subclass if it creates problematic inheritance chains

## Related Refactorings

- **Pull Up Method**: Move common methods up to parent class
- **Pull Down Method**: Move specialized methods to subclass
- **Extract Superclass**: Create a superclass when multiple classes share common behavior
- **Replace Type Code with Subclasses**: Use subclasses instead of type fields
- **Replace Conditional with Polymorphism**: Use subclasses to handle different conditional branches

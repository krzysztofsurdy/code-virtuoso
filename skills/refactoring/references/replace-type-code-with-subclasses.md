## Overview

Replace Type Code with Subclasses is a refactoring technique that transforms type-checking logic using primitive type codes (integers, strings, enums) into a hierarchy of polymorphic subclasses. This eliminates switch statements and conditional logic while leveraging polymorphism to handle different behavior variations. The resulting code is more maintainable, extensible, and type-safe.

## Motivation

### When to Apply

- **Conditional logic based on type codes**: Switch statements or if-else chains selecting behavior based on a primitive type field
- **Type code scattered throughout codebase**: Same type code checked in multiple locations
- **Adding new types requires changes**: Each new type code necessitates modifying existing conditional logic
- **Poor type safety**: Type codes are strings or integers with no compile-time validation
- **Behavior varies by type**: Different operations depend on the type code value
- **Complex type relationships**: Type codes represent variations of a common concept

### Why It Matters

This refactoring replaces fragile type codes with inheritance, enabling polymorphic behavior and eliminating scattered conditional logic. It leverages object-oriented principles for cleaner, more maintainable, and extensible code.

## Mechanics: Step-by-Step

1. **Identify type codes**: Find fields containing type codes (constants, strings, integers)
2. **Create parent class**: Establish a parent class representing the abstraction
3. **Create subclasses**: For each type code value, create a corresponding subclass
4. **Move behavior**: Move type-dependent logic into appropriate subclass methods
5. **Replace conditionals**: Remove switch/if statements; call polymorphic methods
6. **Instantiate subclasses**: Adjust object creation logic to instantiate correct subclass
7. **Remove type field**: Delete the type code field from parent class
8. **Test thoroughly**: Verify all behavior remains identical

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Employee
{
    private const TYPE_ENGINEER = 1;
    private const TYPE_SALESMAN = 2;
    private const TYPE_MANAGER = 3;

    public function __construct(
        private string $name,
        private int $salary,
        private int $type
    ) {}

    public function calculateBonus(): float
    {
        return match ($this->type) {
            self::TYPE_ENGINEER => $this->salary * 0.1,
            self::TYPE_SALESMAN => $this->salary * 0.2 + 500.0,
            self::TYPE_MANAGER => $this->salary * 0.25 + 1000.0,
            default => throw new InvalidArgumentException("Unknown type: {$this->type}"),
        };
    }

    public function getTitle(): string
    {
        return match ($this->type) {
            self::TYPE_ENGINEER => 'Software Engineer',
            self::TYPE_SALESMAN => 'Sales Representative',
            self::TYPE_MANAGER => 'Engineering Manager',
            default => 'Unknown',
        };
    }

    public function getDepartment(): string
    {
        return match ($this->type) {
            self::TYPE_ENGINEER => 'Engineering',
            self::TYPE_SALESMAN => 'Sales',
            self::TYPE_MANAGER => 'Management',
            default => 'Unknown',
        };
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): int
    {
        return $this->salary;
    }
}

// Usage with conditionals
$employee = new Employee('John Doe', 100000, Employee::TYPE_ENGINEER);
echo $employee->getTitle(); // 'Software Engineer'
echo $employee->calculateBonus(); // 10000.0
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

abstract class Employee
{
    public function __construct(
        private string $name,
        private int $salary
    ) {}

    abstract public function calculateBonus(): float;
    abstract public function getTitle(): string;
    abstract public function getDepartment(): string;

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): int
    {
        return $this->salary;
    }
}

class Engineer extends Employee
{
    public function calculateBonus(): float
    {
        return $this->getSalary() * 0.1;
    }

    public function getTitle(): string
    {
        return 'Software Engineer';
    }

    public function getDepartment(): string
    {
        return 'Engineering';
    }
}

class Salesman extends Employee
{
    public function calculateBonus(): float
    {
        return $this->getSalary() * 0.2 + 500.0;
    }

    public function getTitle(): string
    {
        return 'Sales Representative';
    }

    public function getDepartment(): string
    {
        return 'Sales';
    }
}

class Manager extends Employee
{
    public function calculateBonus(): float
    {
        return $this->getSalary() * 0.25 + 1000.0;
    }

    public function getTitle(): string
    {
        return 'Engineering Manager';
    }

    public function getDepartment(): string
    {
        return 'Management';
    }
}

// Factory for object creation
class EmployeeFactory
{
    public static function create(
        string $type,
        string $name,
        int $salary
    ): Employee {
        return match ($type) {
            'engineer' => new Engineer($name, $salary),
            'salesman' => new Salesman($name, $salary),
            'manager' => new Manager($name, $salary),
            default => throw new InvalidArgumentException("Unknown type: {$type}"),
        };
    }
}

// Usage with polymorphism
$employee = EmployeeFactory::create('engineer', 'John Doe', 100000);
echo $employee->getTitle(); // 'Software Engineer'
echo $employee->calculateBonus(); // 10000.0
```

## Benefits

- **Eliminates conditional logic**: No more switch/if statements scattered throughout code
- **Type safety**: Compiler/IDE provides better type checking and autocomplete
- **Polymorphic behavior**: Leverage object-oriented principles naturally
- **Easier to extend**: Adding new types requires only new subclass, no modification to existing code
- **Single responsibility**: Each subclass handles one type's behavior
- **Improved testability**: Can test each subclass independently
- **Better readability**: Intent is clear from class names and structure
- **Reduced coupling**: Classes depend on abstraction, not concrete type codes

## When NOT to Use

- **Simple, rarely-changing types**: If type variations are truly minimal and stable, type codes may be acceptable
- **Type codes are immutable**: When type can never change after initialization; consider using sealed classes instead
- **Performance critical**: Polymorphism introduces minor overhead (usually negligible)
- **Integration with legacy systems**: When external systems mandate specific type code formats
- **Temporary workaround**: If planning refactoring to redesign the whole structure
- **Single type variation**: If only one type code currently exists, don't prematurely optimize

## Related Refactorings

- **Replace Type Code with State**: When type can change after object creation
- **Replace Type Code with Strategy**: For behavior variations without state differences
- **Replace Conditional with Polymorphism**: Complements this refactoring for complex logic
- **Extract Class**: To separate concerns before refactoring type codes
- **Extract Method**: To isolate type-dependent logic before creating subclasses
- **Introduce Parameter Object**: To simplify object creation when many parameters exist

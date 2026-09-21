## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Replace Type Code with Subclasses turns type-checking logic built on primitive type codes (integers, strings, enums) into a hierarchy of polymorphic subclasses. Switch statements and conditionals give way to polymorphic methods, and the type becomes visible to the type system.

## Motivation

### When to apply

- **Conditional logic based on type codes**: switch statements or if-else chains select behavior from a primitive type field.
- **Type code scattered through the codebase**: the same type code is checked in multiple locations.
- **New types force changes**: each new type code means modifying existing conditional logic.
- **Poor type safety**: type codes are strings or integers with no compile-time validation.
- **Behavior varies by type**: different operations depend on the type code value.
- **Variations of a common concept**: the type codes represent variants of one idea.

### Why it matters

Fragile type codes are replaced by inheritance, so behavior is dispatched polymorphically and the scattered conditional logic goes away.

## Mechanics

1. **Identify type codes**: find fields containing type codes (constants, strings, integers).
2. **Create a parent class**: establish a parent class representing the abstraction.
3. **Create subclasses**: add one subclass per type code value.
4. **Move behavior**: move type-dependent logic into the matching subclass methods.
5. **Replace conditionals**: remove the switch/if statements and call polymorphic methods.
6. **Instantiate subclasses**: adjust object creation to instantiate the correct subclass.
7. **Remove the type field**: delete the type code field from the parent class.
8. **Run the tests**: verify that behavior is unchanged.

## Before: PHP 8.3+ example

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

## After: PHP 8.3+ example

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

- **No scattered conditionals**: switch/if statements on the type code disappear.
- **Type safety**: the compiler and IDE can check types and autocomplete.
- **Polymorphic behavior**: dispatch is handled by the object model.
- **Easier to extend**: a new type needs a new subclass and no change to existing code.
- **Single responsibility**: each subclass handles one type's behavior.
- **Testability**: each subclass can be tested independently.
- **Readability**: intent is clear from class names and structure.
- **Reduced coupling**: classes depend on an abstraction, not on concrete type codes.

## When not to use

- **Simple, rarely changing types**: if the variations are minimal and stable, type codes may be acceptable.
- **Type codes change at runtime**: an object cannot change its class after creation, so when the type code can change during the object's life, use Replace Type Code with State or Strategy. Subclasses fit type codes that stay fixed.
- **Performance critical code**: polymorphism adds minor overhead (usually negligible).
- **Legacy integration**: external systems mandate specific type code formats.
- **Temporary workaround**: the whole structure is about to be redesigned.
- **Single type variation**: with only one type code, do not optimize prematurely.

## Related refactorings

- **Replace Type Code with State**: for types that can change after object creation.
- **Replace Type Code with Strategy**: for behavior variations without state differences.
- **Replace Conditional with Polymorphism**: complements this refactoring for complex logic.
- **Extract Class**: separates concerns before refactoring type codes.
- **Extract Method**: isolates type-dependent logic before creating subclasses.
- **Introduce Parameter Object**: simplifies object creation when there are many parameters.

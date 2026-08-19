## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before (PHP 8.3+)](#before-php-83)
- [After (PHP 8.3+)](#after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

This refactoring adds a reverse link between two classes that have only a one-way association. When both sides of a relationship need to reach the other, the missing direction removes awkward workarounds and makes the domain model clearer.

## Motivation

### When to apply

- **Both sides need navigation**: Client code regularly needs to traverse the relationship in both directions
- **Costly reverse lookups**: Finding the reverse relationship through searches or global scans is slow
- **Clearer domain modeling**: The real-world relationship is bidirectional
- **Workarounds**: The codebase has clumsy patterns that simulate the missing direction
- **Simpler client code**: Consumers of both classes gain direct access

### Why it matters

Requirements change, and a relationship that started as one-way often needs navigation in both directions. Without the reverse link, developers fall back on global searches, parameter threading, or other fragile approaches. A bidirectional association states the relationship directly, at the cost of tighter coupling between the two classes.

## Mechanics

1. **Add a reverse field**: Create a field in the non-owning class to hold a reference back to the owning class
2. **Decide on ownership**: Pick the class that manages the association
3. **Build helper methods**: Add methods on the non-owning side to set and clear the back-reference
4. **Wire up the owning side**: Change the owning class's add/remove methods to keep the back-reference in sync
5. **Centralize updates**: Change the association only through the controlling methods
6. **Remove workarounds**: Delete any global lookups or parameter threading that simulated the reverse link
7. **Verify consistency**: Test that both directions stay in sync under all operations

## Before (PHP 8.3+)

```php
<?php

declare(strict_types=1);

class Department
{
    private string $name;
    private array $employees = [];

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function addEmployee(Employee $employee): void
    {
        $this->employees[] = $employee;
        // Employee doesn't know about its department
    }

    public function getEmployees(): array
    {
        return $this->employees;
    }
}

class Employee
{
    private string $name;
    // No reference back to Department - unidirectional only

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getDepartmentName(): string
    {
        // Awkward workaround: must search all departments
        // This is inefficient and fragile
        foreach ($GLOBALS['allDepartments'] as $dept) {
            if (in_array($this, $dept->getEmployees())) {
                return $dept->getName();
            }
        }
        return 'Unknown';
    }
}
```

## After (PHP 8.3+)

```php
<?php

declare(strict_types=1);

class Department
{
    private string $name;
    private array $employees = [];

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function addEmployee(Employee $employee): void
    {
        if (!in_array($employee, $this->employees, true)) {
            $this->employees[] = $employee;
            $employee->setDepartment($this);
        }
    }

    public function removeEmployee(Employee $employee): void
    {
        $key = array_search($employee, $this->employees, true);
        if ($key !== false) {
            unset($this->employees[$key]);
            $employee->setDepartment(null);
        }
    }

    public function getEmployees(): array
    {
        return array_values($this->employees);
    }
}

class Employee
{
    private string $name;
    private ?Department $department = null;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setDepartment(?Department $department): void
    {
        $this->department = $department;
    }

    public function getDepartment(): ?Department
    {
        return $this->department;
    }

    public function getDepartmentName(): string
    {
        return $this->department?->getName() ?? 'Unassigned';
    }
}
```

## Benefits

- **No workarounds**: No global scans or parameter threading to find related objects
- **Faster navigation**: A direct reference is faster than searching or iterating collections
- **Explicit modeling**: The code matches the shape of the domain relationship
- **Easy traversal**: Both classes can reach the other without outside help
- **Consistent updates**: Synchronized add/remove methods keep both sides in agreement
- **Readable code**: The class structure shows the relationship

## When NOT to use

- **One direction is sufficient**: If only one side needs the reference, keep the association unidirectional
- **Infrequent reverse access**: Occasional reverse lookups may not justify the added coupling
- **Architectural boundaries**: Bidirectional links can violate layering constraints in modular architectures
- **Simple containment**: Basic one-to-many relationships where the child never needs to find its parent
- **Small but real overhead**: Keeping both sides in sync has a cost
- **Design clarity**: Some designs restrict navigation on purpose to keep data flow clean

## Related refactorings

- **Change Bidirectional Association to Unidirectional**: The inverse: removes unnecessary coupling
- **Extract Class**: Useful when association management grows complex enough to need its own class
- **Encapsulate Collection**: Often applied alongside to manage bidirectional collection updates safely
- **Hide Delegate**: Reduces the number of exposed associations
- **Move Field**: Moves association data when it belongs in a different class

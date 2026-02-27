## Overview

Change Unidirectional Association to Bidirectional is a refactoring technique applied when two classes need to access each other's features, but their association is currently one-directional. This refactoring adds the missing reverse association to enable bidirectional communication between the classes.

## Motivation

### When to Apply

- **Both classes need access**: Clients require functionality from both directions of the association
- **Complex reverse calculations**: Computing reverse associations through complex logic becomes cumbersome
- **Improved code clarity**: Explicit bidirectional relationships make dependencies transparent
- **Eliminating workarounds**: Code contains awkward patterns to simulate reverse relationships
- **Simplified domain logic**: Domain requirements naturally involve two-way communication

### Why It Matters

As applications evolve, initial one-way relationships often become insufficient. Adding bidirectional associations eliminates awkward workarounds and makes the code intention clearer. However, this comes with the tradeoff of increased coupling between classes.

## Mechanics: Step-by-Step

1. **Add reverse field**: Create a field in the non-dominant class to hold reference to the dominant class
2. **Identify dominant class**: Determine which class should control association changes
3. **Create utility methods**: Add methods in the non-dominant class to establish the reverse association
4. **Update dominant methods**: Modify dominant class methods to invoke utility methods from non-dominant class
5. **Migrate control**: Move association control logic from non-dominant to dominant class
6. **Remove direct field assignments**: Ensure associations are only modified through control methods
7. **Test thoroughly**: Verify bidirectional consistency is maintained

## Before: PHP 8.3+ Example

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

## After: PHP 8.3+ Example

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

- **Cleaner Code**: Eliminates workarounds and reverse lookup logic
- **Better Performance**: Direct access is faster than searching or iterating
- **Improved Clarity**: Bidirectional associations explicitly model the domain
- **Easier Navigation**: Both classes can navigate to each other naturally
- **Reduced Fragility**: Changes to one direction automatically affect the other
- **Self-Documenting**: Code intent is clearer with explicit relationships

## When NOT to Use

- **Single-direction suffices**: If only one direction truly needs access, keep it unidirectional
- **Rare reverse access**: If reverse access occurs only occasionally, consider computed properties instead
- **High coupling unacceptable**: In layered architectures, bidirectional associations may violate layer boundaries
- **Simple collections**: For basic one-to-many where reverse isn't genuinely needed
- **Performance-critical**: Maintaining bidirectionality adds overhead (usually negligible)
- **Unidirectional is cleaner**: Some designs are deliberately unidirectional for clarity

## Related Refactorings

- **Change Bidirectional Association to Unidirectional**: The inverse refactoring to remove unnecessary coupling
- **Extract Class**: When association logic becomes too complex, extract to a separate relationship class
- **Encapsulate Collection**: Often used alongside to manage bidirectional collection updates safely
- **Hide Delegate**: To reduce visibility of associations and simplify client code
- **Move Field**: When association management logic needs relocation

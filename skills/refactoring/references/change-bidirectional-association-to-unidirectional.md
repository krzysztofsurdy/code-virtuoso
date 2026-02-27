## Overview

Change Bidirectional Association to Unidirectional is a refactoring technique that removes unused associations between classes to simplify code structure. When one class in a bidirectional relationship doesn't utilize the other class's features, the association should be eliminated. This technique reduces code complexity while maintaining system functionality.

## Motivation

### When to Apply

- **Unused associations**: One class doesn't actually use the back-reference to the other
- **Alternative access patterns**: Objects can be retrieved through database queries or method parameters instead
- **Memory inefficiency**: Circular references prevent proper garbage collection
- **Tight coupling concerns**: Bidirectional associations force classes to know about each other
- **Simplified maintenance**: Code with fewer dependencies is easier to understand and modify

### Why It Matters

Bidirectional associations are inherently more difficult to maintain than unidirectional ones because they require extra code for object creation, deletion, and synchronization. Classes in bidirectional associations cannot function independently, creating tight coupling that makes systems brittle. Any changes in one component may affect the other, increasing the risk of bugs.

## Mechanics: Step-by-Step

1. **Verify necessity**: Confirm that one side of the association is truly unused or can access data through alternative means
2. **Check access patterns**: Ensure alternative methods exist (database queries, method parameters, service lookups)
3. **Replace field usage**: Substitute direct field access with method parameters or alternative retrieval methods
4. **Remove assignments**: Delete code that assigns the associated object to the back-reference field
5. **Delete unused field**: Remove the now-unused back-reference field from the class
6. **Test thoroughly**: Verify that all functionality remains intact

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Company
{
    private string $name;
    private array $employees = [];

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function addEmployee(Employee $employee): void
    {
        $this->employees[] = $employee;
        $employee->setCompany($this);
    }

    public function removeEmployee(Employee $employee): void
    {
        $key = array_search($employee, $this->employees, true);
        if ($key !== false) {
            unset($this->employees[$key]);
            $employee->setCompany(null);
        }
    }

    public function getEmployees(): array
    {
        return $this->employees;
    }

    public function getName(): string
    {
        return $this->name;
    }
}

class Employee
{
    private string $name;
    private ?Company $company = null;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function setCompany(?Company $company): void
    {
        $this->company = $company;
    }

    public function getCompany(): ?Company
    {
        return $this->company;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function reportWork(): void
    {
        // Company reference never used - only needs employee name
        echo "Employee {$this->name} is working";
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Company
{
    private string $name;
    private array $employees = [];

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function addEmployee(Employee $employee): void
    {
        $this->employees[] = $employee;
    }

    public function removeEmployee(Employee $employee): void
    {
        $key = array_search($employee, $this->employees, true);
        if ($key !== false) {
            unset($this->employees[$key]);
        }
    }

    public function getEmployees(): array
    {
        return $this->employees;
    }

    public function getName(): string
    {
        return $this->name;
    }
}

class Employee
{
    private string $name;

    public function __construct(string $name)
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function reportWork(): void
    {
        echo "Employee {$this->name} is working";
    }
}
```

## Benefits

- **Reduced Complexity**: Fewer bidirectional dependencies mean simpler class designs and easier maintenance
- **Improved Garbage Collection**: Removal of circular references prevents memory leaks in languages with manual memory management
- **Lower Coupling**: Classes become more independent and can be understood in isolation
- **Easier Testing**: Independent classes are simpler to unit test without complex setup
- **Simplified Object Lifecycle**: No need to manage back-references during object creation and deletion
- **Improved Encapsulation**: Each class exposes only the associations it actually uses

## When NOT to Use

- **Both directions are essential**: If both sides genuinely use the relationship, keep it bidirectional
- **Performance requirements**: If access from the reverse direction requires expensive database queries
- **True mutual dependencies**: When classes truly need tight coupling for domain logic
- **Existing API contracts**: If changing the association breaks public API contracts
- **Insufficient refactoring analysis**: When you're unsure if the association is truly unused

## Related Refactorings

- **Change Unidirectional Association to Bidirectional**: The opposite refactoring when you need to add a back-reference
- **Extract Class**: To reduce coupling by splitting responsibilities across more classes
- **Move Method**: To relocate methods closer to the data they operate on
- **Hide Delegate**: To encapsulate associations behind access methods
- **Remove Middle Man**: To eliminate intermediary objects managing relationships

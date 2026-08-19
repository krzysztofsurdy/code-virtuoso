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

This refactoring removes a superfluous back-reference from a bidirectional relationship between two classes. When one side of a two-way link never uses its connection to the other, that connection has no purpose and only adds complexity. Removing it leaves leaner classes with fewer responsibilities.

## Motivation

### When to apply

- **Dormant reference**: One class maintains a link to the other but never reads or writes through it
- **Indirect access suffices**: The referenced object can be retrieved via queries, method arguments, or services instead
- **Resource waste**: Circular references interfere with garbage collection and use memory for nothing
- **Unnecessary coupling**: Both classes know about each other although only one depends on the other
- **Simpler evolution**: Fewer interdependencies make the code easier to change

### Why it matters

Two-way associations carry an ongoing coordination cost: they need synchronization logic whenever objects are created, updated, or destroyed. Classes bound by bidirectional references cannot be understood or changed independently. When one direction of the link is unused, that coupling is pure waste.

## Mechanics

1. **Verify the link is unused**: Confirm that one class never reads, writes, or otherwise relies on the back-reference, or that the same data is reachable by other means
2. **Find alternative access paths**: Determine whether the needed information can arrive through method arguments, repository queries, or service lookups
3. **Reroute existing usage**: Replace any remaining direct field access with the alternative path
4. **Remove assignment code**: Remove statements that establish or update the back-reference during object lifecycle events
5. **Drop the field**: Delete the now-unused reference property from the class
6. **Run the test suite**: Confirm that behavior is unchanged

## Before (PHP 8.3+)

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

## After (PHP 8.3+)

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

- **Leaner classes**: Removing the unused link cuts down on code each class must carry
- **Memory management**: Breaking circular references lets the garbage collector reclaim memory sooner
- **Lower coupling**: Each class can change independently without ripple effects on the other
- **Easier testing**: Standalone classes need less scaffolding in unit tests
- **Simpler lifecycle**: The removed direction needs no synchronization logic
- **Tighter encapsulation**: Classes only expose associations they rely on

## When NOT to use

- **Both directions see active use**: If both classes read the reference, the bidirectional link is warranted
- **Reverse lookup performance**: Replacing the direct reference with a database query would add unacceptable latency
- **Inherently mutual relationships**: Some domain concepts are two-way by nature
- **Published API surface**: Removing the association may break external consumers who depend on it
- **Uncertain usage**: If you cannot confirm the back-reference is unused, investigate before deleting it

## Related refactorings

- **Change Unidirectional Association to Bidirectional**: The reverse operation, introducing a back-reference when needed
- **Extract Class**: Separates responsibilities to reduce coupling further
- **Move Method**: Moves behavior closer to the data it operates on
- **Hide Delegate**: Wraps associations behind accessor methods to limit exposure
- **Remove Middle Man**: Removes intermediary objects that manage relationships unnecessarily

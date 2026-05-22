## Overview

Hide Delegate shields client code from knowing about the internal objects a class delegates to. Instead of letting callers reach through one object to access another (`department->getManager()->getName()`), you add a method on the intermediate class that performs the delegation internally. Callers interact with a simpler, more stable interface.

## Motivation

### When to Apply

- **Chained method calls**: Client code navigates through multiple objects to reach the data it needs
- **Excessive coupling**: Callers depend on the internal structure of objects they should not know about
- **Law of Demeter violations**: Code talks to strangers instead of immediate neighbors
- **Leaking internals**: Implementation details surface in the public API
- **Fragile call sites**: Restructuring internal objects forces changes across many client locations
- **Feature envy**: A class spends more time accessing another object's data than its own

### Why It Matters

When clients reach through delegation chains, they become tightly coupled to the internal wiring of the objects involved. Any change to that wiring - renaming a method, replacing an internal object, reorganizing responsibilities - ripples out to every call site. Providing a facade method on the owning class absorbs that change in a single place.

## Mechanics: Step-by-Step

1. **Find delegation chains**: Locate places where client code accesses a delegated object's properties or methods
2. **Add a wrapper method**: Create a method on the owning class that performs the delegation internally
3. **Implement the delegation**: Have the new method call through to the internal object and return the result
4. **Redirect callers**: Replace all chained calls with calls to the new method
5. **Hide the accessor if possible**: Remove the public getter for the internal object if no caller still needs it
6. **Verify with tests**: Confirm that all client code continues to work correctly

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Department
{
    public function __construct(
        private Manager $manager
    ) {
    }

    public function getManager(): Manager
    {
        return $this->manager;
    }
}

class Manager
{
    public function __construct(
        private string $name
    ) {
    }

    public function getName(): string
    {
        return $this->name;
    }
}

// Client code - violates Law of Demeter
class Employee
{
    public function __construct(
        private Department $department
    ) {
    }

    public function getManagerName(): string
    {
        // Reaches through multiple layers to get manager name
        return $this->department->getManager()->getName();
    }

    public function reportToManager(): void
    {
        $managerName = $this->department->getManager()->getName();
        echo "Reporting to: {$managerName}\n";
    }
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Department
{
    public function __construct(
        private Manager $manager
    ) {
    }

    // Hide delegation - provide public interface
    public function getManagerName(): string
    {
        return $this->manager->getName();
    }

    public function managerReports(): void
    {
        // Other delegation methods can be added as needed
        echo "Manager: {$this->manager->getName()}\n";
    }

    // Optionally keep getManager() if external access is truly needed
    // public function getManager(): Manager
    // {
    //     return $this->manager;
    // }
}

class Manager
{
    public function __construct(
        private string $name
    ) {
    }

    public function getName(): string
    {
        return $this->name;
    }
}

// Client code - cleaner and more cohesive
class Employee
{
    public function __construct(
        private Department $department
    ) {
    }

    public function getManagerName(): string
    {
        // Direct call to Department's interface
        return $this->department->getManagerName();
    }

    public function reportToManager(): void
    {
        $managerName = $this->department->getManagerName();
        echo "Reporting to: {$managerName}\n";
    }
}

// Usage
$manager = new Manager('John Smith');
$department = new Department($manager);
$employee = new Employee($department);

echo $employee->getManagerName(); // Output: John Smith
$employee->reportToManager();     // Output: Reporting to: John Smith
```

## Benefits

- **Weaker Coupling**: Clients depend on a stable surface API rather than the internal object graph
- **Stronger Encapsulation**: Internal objects can be restructured without touching callers
- **Demeter Compliance**: Each class communicates only with its direct collaborators
- **Cleaner Public Interface**: The owning class presents a focused, intuitive set of methods
- **Localized Change**: Modifications to internal delegation affect a single method, not every call site
- **Clearer Boundaries**: Each class has a well-defined scope of responsibility
- **Easier Comprehension**: Fewer indirections make the code faster to read and understand

## When NOT to Use

- **Clients genuinely need the delegated object**: Sometimes the caller requires the full object, not just a single property
- **Excessive wrapping**: If hiding many different delegated objects bloats the owning class, the cure may be worse than the disease
- **Intentional transparency**: Patterns like Facade and Adapter deliberately expose delegation
- **Trivial pass-through**: A single, obvious delegation with no stability benefit may not be worth wrapping
- **Negligible coupling risk**: If the internal structure is unlikely to change, the indirection adds little value
- **External API dependency**: When third-party libraries expect access to the delegated object

## Related Refactorings

- **Remove Middle Man**: The inverse - exposing the delegated object when too many wrapper methods accumulate
- **Encapsulate Field**: Hides internal fields behind accessors, following the same encapsulation principle
- **Extract Class**: Pulls delegation-heavy logic into its own class when responsibility grows
- **Facade Pattern**: A broader application of the same idea, abstracting an entire subsystem
- **Introduce Parameter Object**: Bundles delegated data into a single parameter to simplify method signatures

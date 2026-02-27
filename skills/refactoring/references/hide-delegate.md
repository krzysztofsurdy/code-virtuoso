## Overview

Hide Delegate is a refactoring technique that removes unnecessary intermediate methods that delegate to other objects. Instead of exposing internal object delegation, you create methods on a class that handle delegation internally. This simplifies the client code, reduces coupling, and provides a cleaner, more cohesive public interface.

## Motivation

### When to Apply

- **Long chains of delegation**: Client code accesses `object->getDelegated()->getProperty()` instead of using a single method
- **Unnecessary coupling**: Clients depend on internal object structure rather than stable interfaces
- **Law of Demeter violations**: Code reaches through multiple layers to get needed data
- **API clarity**: Internal implementation details leak into public contracts
- **Object structure changes**: Refactoring internal objects breaks many client locations
- **Feature envy**: A class uses another object's methods more than its own

### Why It Matters

Hide Delegate reduces coupling between classes, improves encapsulation, and makes code more maintainable. When clients depend on internal delegation chains, changes to the internal structure require updating all clients. By providing dedicated methods, you create a stable interface that shields clients from internal complexity.

## Mechanics: Step-by-Step

1. **Identify delegation chains**: Find places where clients access delegated objects
2. **Create delegation method**: Add a new public method on the delegating class
3. **Implement delegation**: Method delegates to the internal object and returns the result
4. **Update clients**: Replace direct delegation calls with calls to the new method
5. **Remove accessor if possible**: Delete the public getter for the delegated object if no longer needed
6. **Test thoroughly**: Verify all client code still works correctly

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

- **Reduced Coupling**: Clients depend on stable public interfaces, not internal structure
- **Encapsulation**: Internal implementation details remain hidden and can be changed safely
- **Law of Demeter Compliance**: Clients only communicate with direct neighbors
- **Cleaner API**: Public interface becomes more intuitive and easier to use
- **Easier Refactoring**: Changing internal object relationships doesn't break client code
- **Single Responsibility**: Delegating class has clearer purpose and boundaries
- **Maintainability**: Centralized delegation logic is easier to modify and understand

## When NOT to Use

- **True accessors needed**: If clients genuinely need the delegated object itself (not just properties/methods)
- **Extensive delegation**: When hiding many different delegated objects becomes overly complex
- **Transparent proxies**: Some patterns (Facade, Adapter) intentionally expose internal delegation
- **Simple pass-through**: Single method delegations with obvious intent may not warrant hiding
- **Performance critical**: In rare cases where method call overhead matters (typically negligible)
- **Widespread external APIs**: When many external libraries depend on accessing the delegated object

## Related Refactorings

- **Remove Middle Man**: Reverse operation - expose the delegated object directly when hiding becomes excessive
- **Encapsulate Field**: Hide internal fields and provide controlled access methods
- **Extract Class**: Extract delegation to a new class when responsibility grows
- **Facade Pattern**: Similar structure but intentionally abstracts multiple subsystems
- **Law of Demeter**: General principle that guides when to apply Hide Delegate
- **Introduce Parameter Object**: Combine delegated data access into a single parameter object

# Remove Middle Man

## Overview

Remove Middle Man eliminates a class that only forwards requests to another object. When a class is mostly delegation methods, each calling the same method on an internal collaborator, the intermediary adds indirection and no value. Exposing the delegate lets clients talk to the real object and removes the pass-through layer.

This is the inverse of Hide Delegate. Apply it when the middle man has become needless complexity instead of a useful abstraction.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ code](#before-php-83-code)
- [After: PHP 8.3+ code](#after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

- **Cut indirection**: chains of forwarding methods hide which object does the work.
- **Show the real collaborator**: direct access makes the code's intent clear to readers.
- **Shrink the maintenance footprint**: a new method on the delegate no longer needs a matching wrapper.
- **Simplify the class tree**: removing hollow intermediaries keeps the design lean.
- **Speed up change**: clients can use new delegate capabilities at once, without waiting for wrapper methods.

## Mechanics

1. **Identify the middle man**: find classes that mostly delegate to another object.
2. **Check usage patterns**: find out which delegated methods clients use.
3. **For each delegated method**:
   - Create a getter that returns the delegated object
   - Update all clients to use the delegated object directly
   - Remove the delegating method from the middle man
4. **Remove unused delegation**: delete wrapper methods as clients move over.
5. **Clean up**: delete the middle man class if it ends up empty.

## Before: PHP 8.3+ code

```php
class Department
{
    private Manager $manager;

    public function __construct(Manager $manager)
    {
        $this->manager = $manager;
    }

    // Middle man methods - just delegating
    public function getManagerName(): string
    {
        return $this->manager->getName();
    }

    public function getManagerExperience(): int
    {
        return $this->manager->getExperience();
    }

    public function getManagerSalary(): float
    {
        return $this->manager->getSalary();
    }

    public function promoteManager(): void
    {
        $this->manager->promote();
    }
}

class Manager
{
    public function __construct(
        private string $name,
        private int $experience,
        private float $salary,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getExperience(): int
    {
        return $this->experience;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }

    public function promote(): void
    {
        $this->experience += 1;
        $this->salary *= 1.1;
    }
}

// Client code
$department = new Department(new Manager('Alice', 5, 80000));
echo $department->getManagerName();
echo $department->getManagerSalary();
```

## After: PHP 8.3+ code

```php
class Department
{
    public function __construct(
        private Manager $manager,
    ) {}

    // Direct access to the delegated object
    public function getManager(): Manager
    {
        return $this->manager;
    }
}

class Manager
{
    public function __construct(
        private string $name,
        private int $experience,
        private float $salary,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getExperience(): int
    {
        return $this->experience;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }

    public function promote(): void
    {
        $this->experience += 1;
        $this->salary *= 1.1;
    }
}

// Client code - cleaner and more direct
$department = new Department(new Manager('Alice', 5, 80000));
echo $department->getManager()->getName();
echo $department->getManager()->getSalary();
```

## Benefits

- **Clear relationships**: clients see which object they work with.
- **No wrapper upkeep**: new delegate methods are available at once, with no mirroring.
- **Leaner classes**: the former middle man loses its boilerplate, or disappears.
- **Direct mockability**: tests can inject or stub the delegate without going through an extra layer.
- **Honest design**: the structure reflects actual responsibilities, not ceremonial forwarding.

## When not to use

- **Abstraction layer**: if the middle man isolates clients from implementation details, keep it.
- **Encapsulation matters**: in tightly coupled systems, the wrapper may be needed for security or validation.
- **API stability**: the middle man shields clients from changes in the delegated object's interface.
- **Cross-cutting concerns**: the middle man implements logging, authorization, or caching.
- **Early in design**: wait until you are sure the abstraction is not needed for future change.

## Related refactorings

- **Hide Delegate**: the opposite refactoring. Introduce a middle man when you need to isolate clients from implementation changes.
- **Introduce Parameter Object**: combine several delegated methods into a single parameter.
- **Extract Method**: break complex delegating logic into smaller, focused methods.
- **Encapsulate Field**: protect direct access when needed by replacing it with controlled getters and setters.
- **Replace Delegation with Inheritance**: sometimes inherit from the delegated class instead of delegating.

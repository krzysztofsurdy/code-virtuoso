## Overview

Remove Middle Man eliminates a class that does nothing but forward requests to another object. When a class consists primarily of delegation methods - each one simply calling the same method on an internal collaborator - the intermediary adds indirection without adding value. Exposing the delegate directly lets clients talk to the real object and trims away the pass-through layer.

This technique is the inverse of Hide Delegate and is applied when the middle man has become unnecessary complexity rather than a useful abstraction.

## Motivation

- **Cut unnecessary indirection**: Chains of forwarding methods obscure which object actually performs the work
- **Surface the real collaborator**: Direct access makes the code's intent transparent to readers
- **Shrink the maintenance footprint**: Every new method on the delegate no longer requires a matching wrapper
- **Streamline the class tree**: Removing hollow intermediaries keeps the design lean
- **Speed up evolution**: Clients can adopt new delegate capabilities immediately, without waiting for wrapper methods to be added

## Mechanics

1. **Identify the middle man**: Find classes that primarily delegate to another object
2. **Check usage patterns**: Determine which delegated methods clients actually use
3. **For each delegated method**:
   - Create a getter method to access the delegated object
   - Update all clients to use the delegated object directly
   - Remove the delegating method from the middle man
4. **Remove unused delegation**: Eliminate wrapper methods as clients transition
5. **Clean up**: Delete the middle man class if it becomes empty

## Before: PHP 8.3+ Code

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

## After: PHP 8.3+ Code

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

- **Transparent relationships**: Clients see which object they are really working with
- **Zero wrapper overhead**: New delegate methods are available immediately without mirroring
- **Leaner classes**: The former middle man sheds boilerplate, or disappears entirely
- **Direct mockability**: Tests can inject or stub the delegate without navigating an extra layer
- **Honest design**: The architecture reflects actual responsibilities rather than ceremonial forwarding

## When NOT to Use

- **Building an abstraction layer**: If the middle man provides valuable isolation from implementation details, keep it
- **Encapsulation is critical**: In tightly coupled systems, the wrapper may be essential for security or validation
- **API stability**: When the middle man shields clients from changes in the delegated object's interface
- **Cross-cutting concerns**: When the middle man implements logging, authorization, or caching
- **Early in design**: Until you're certain the abstraction isn't needed for future evolution

## Related Refactorings

- **Hide Delegate**: The opposite refactoring; introduce a middle man when you need to isolate clients from implementation changes
- **Introduce Parameter Object**: Combine multiple delegated methods into a single parameter
- **Extract Method**: Break down complex delegating logic into smaller, focused methods
- **Encapsulate Field**: Protect direct access when needed, replacing it with controlled getter/setter methods
- **Replace Delegation with Inheritance**: Sometimes inherit from the delegated class instead of delegating

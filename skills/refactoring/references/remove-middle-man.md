## Overview

The "Remove Middle Man" refactoring eliminates intermediary wrapper methods that simply delegate to another object without adding value. When a class acts as a middle man purely forwarding requests to another object, it creates unnecessary indirection and complexity. This refactoring exposes the delegated object directly, simplifying the codebase and reducing coupling.

This technique is the inverse of "Hide Delegate" and is applied when the middle man has become unnecessary complexity rather than a useful abstraction.

## Motivation

- **Reduce unnecessary indirection**: Multiple levels of delegation obscure the actual object doing the work
- **Improve code clarity**: Direct access to the real object makes intent clearer to readers
- **Decrease maintenance burden**: Fewer wrapper methods to maintain when delegating repeatedly
- **Simplify class hierarchy**: Removes redundant classes or methods that serve no strategic purpose
- **Ease of evolution**: Direct access allows clients to adapt quickly without updating wrapper methods

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

- **Reduced coupling**: Clients depend on the actual object, not a wrapper
- **Better maintainability**: No need to add wrapper methods for each new feature
- **Clearer intent**: Code reveals the actual relationships between objects
- **Improved flexibility**: Clients can call any method on the delegated object
- **Easier testing**: Can inject mock objects directly without wrapper complications

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

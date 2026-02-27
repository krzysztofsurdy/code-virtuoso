## Overview

Replace Conditional with Polymorphism is a refactoring technique that transforms conditional logic (switch statements, if-else chains) into polymorphic method implementations across a class hierarchy. Instead of checking object types or properties to determine behavior, you create subclasses that override methods with their specific implementations.

## Motivation

Conditional logic scattered throughout your code creates several problems:

- **Maintainability issues**: Adding a new variant requires finding and modifying all conditional branches
- **Violation of Open/Closed Principle**: The code is open for modification but not closed for extension
- **Code duplication**: Similar conditional patterns appear in multiple methods
- **Poor encapsulation**: Violates the "Tell-Don't-Ask" principle by requiring external type checking
- **Difficult testing**: Conditional branches become harder to unit test in isolation

## Mechanics

1. Create a class hierarchy with an abstract base class or interface
2. Create subclasses representing each conditional branch
3. Extract the method containing the conditional logic
4. Override this method in each subclass with branch-specific implementation
5. Remove conditional branches progressively
6. Replace conditional calls with polymorphic method invocations

## Before: Conditional Logic

```php
class Bird
{
    private string $type;
    private float $speed;
    private bool $isNailed;

    public function getSpeed(): float
    {
        return match ($this->type) {
            'european' => $this->speed,
            'african' => max(0, $this->speed - $this->getLoadFactor() * 9),
            'norwegian' => max(0, $this->speed - $this->getLoadFactor() * 3),
            default => 0
        };
    }

    private function getLoadFactor(): float
    {
        return $this->isNailed ? 2 : 1;
    }
}

// Usage
$bird = new Bird('african', 100, false);
echo $bird->getSpeed(); // Must know implementation details
```

## After: Polymorphic Implementation (PHP 8.3+)

```php
abstract class Bird
{
    protected float $speed;
    protected bool $isNailed;

    public function __construct(float $speed, bool $isNailed = false)
    {
        $this->speed = $speed;
        $this->isNailed = $isNailed;
    }

    abstract public function getSpeed(): float;

    protected function getLoadFactor(): float
    {
        return $this->isNailed ? 2 : 1;
    }
}

class EuropeanBird extends Bird
{
    public function getSpeed(): float
    {
        return $this->speed;
    }
}

class AfricanBird extends Bird
{
    public function getSpeed(): float
    {
        return max(0, $this->speed - $this->getLoadFactor() * 9);
    }
}

class NorwegianBlueBird extends Bird
{
    public function getSpeed(): float
    {
        return max(0, $this->speed - $this->getLoadFactor() * 3);
    }
}

// Usage - No type checking needed
$birds = [
    new EuropeanBird(100),
    new AfricanBird(100, false),
    new NorwegianBlueBird(100)
];

foreach ($birds as $bird) {
    echo $bird->getSpeed(); // Correct implementation called automatically
}
```

## Benefits

- **Extensibility**: Adding new bird types requires only a new subclass, no modification to existing code
- **Type Safety**: PHP's type system catches errors at compile time rather than runtime
- **Testability**: Each subclass can be tested independently with focused unit tests
- **Readability**: Code intent is clear; behavior is explicit rather than implicit
- **Encapsulation**: Each subclass encapsulates its own behavior logic
- **Follows SOLID principles**: Open/Closed Principle, Single Responsibility Principle, Liskov Substitution Principle

## When NOT to Use

- **Simple conditionals**: If the conditional logic is trivial and unlikely to change, leave it as-is
- **Unrelated conditions**: When conditionals check unrelated properties rather than object type/state
- **Few variants**: If there are only 2 variants and no plans for extension, polymorphism may be overkill
- **Feature flags**: Temporary feature toggles are better handled with decorators or strategies
- **Mutually exclusive states**: Consider State Pattern instead if object state changes frequently

## Related Refactorings

- **Strategy Pattern**: Use when you need to switch algorithms at runtime (similar mechanics, different intent)
- **State Pattern**: Use when object behavior changes based on internal state transitions
- **Template Method Pattern**: Define algorithm skeleton in base class, let subclasses fill in details
- **Decorator Pattern**: Add behavior dynamically without subclassing
- **Extract Method**: Often a prerequisite step before applying this refactoring

# Push Down Method

## Overview

Push Down Method is a refactoring technique used when a method in a superclass is utilized by only one or a few of its subclasses. The solution involves relocating that method to the appropriate subclass(es) where it's actually needed, rather than keeping it in the parent class where it may not be relevant to all children.

This refactoring improves class coherence by ensuring methods reside in the classes that genuinely require them, making the codebase more intuitive and maintainable.

## Motivation

You should apply Push Down Method when:

- A method was intended to be universal for all classes but is used by only one or a few subclasses
- Feature extraction or removal from a class hierarchy has left methods unused by some subclasses
- A parent class contains behavior that doesn't apply to all children
- Class hierarchy has evolved and methods are no longer relevant to all descendants
- A refused bequest code smell is present (subclasses have unused inherited methods)

## Mechanics

The refactoring process follows these straightforward steps:

1. **Declare the method in the target subclass** - Add the method signature and implementation to the subclass that actually needs it
2. **Remove the method from the superclass** - Delete the original method from the parent class
3. **Update all references** - Ensure all calls to the method go through the subclass where it now resides
4. **Verify type safety** - Check that all usages occur within the intended subclass or through proper type narrowing

## Before/After (PHP 8.3+)

### Before

```php
abstract class Vehicle
{
    protected string $model;
    protected float $price;

    public function __construct(string $model, float $price)
    {
        $this->model = $model;
        $this->price = $price;
    }

    /**
     * Only used by Car subclass, not by Motorcycle
     */
    public function getNumberOfDoors(): int
    {
        return 4;
    }

    abstract public function getMaxSpeed(): float;
}

final class Car extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 200.0;
    }
}

final class Motorcycle extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 220.0;
    }
}
```

### After

```php
abstract class Vehicle
{
    protected string $model;
    protected float $price;

    public function __construct(string $model, float $price)
    {
        $this->model = $model;
        $this->price = $price;
    }

    abstract public function getMaxSpeed(): float;
}

final class Car extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 200.0;
    }

    public function getNumberOfDoors(): int
    {
        return 4;
    }
}

final class Motorcycle extends Vehicle
{
    public function getMaxSpeed(): float
    {
        return 220.0;
    }
}
```

## Benefits

- **Improved class coherence** - Methods reside where developers naturally expect to find them
- **Cleaner abstractions** - The superclass no longer exposes methods irrelevant to some subclasses
- **Reduced confusion** - Less likelihood of subclasses having unused inherited methods
- **Better encapsulation** - Each class only exposes the interface it actually needs
- **Easier maintenance** - Changes to a method only affect the subclass that uses it

## When NOT to Use

- **Avoid premature optimization** - Don't push down methods based on speculation about future usage
- **Don't create duplication** - If multiple unrelated subclasses need the method, consider keeping it in the parent class instead
- **Template Method pattern** - When a parent class method defines a skeleton that subclasses customize, keep it in the parent
- **Polymorphic behavior** - If the method is part of a polymorphic contract, pushing it down breaks the Liskov Substitution Principle
- **Shared functionality** - When several subclasses genuinely share the method, duplication introduces maintenance burden

## Related Refactorings

- **Pull Up Method** - The inverse operation; moves methods from subclasses to the parent class
- **Push Down Field** - Similar concept applied to fields instead of methods
- **Extract Subclass** - Often paired with Push Down Method to create specialized subclasses
- **Replace Type Code with Subclasses** - May involve pushing down methods to create type-specific behavior

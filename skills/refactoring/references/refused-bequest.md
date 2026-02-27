# Refused Bequest

## Overview

Refused Bequest occurs when a subclass inherits from a parent class but only uses some (or none) of the inherited methods and properties. The subclass refuses to fully embrace the parent's interface, either by ignoring inherited members or overriding them to throw exceptions. This indicates a fundamental problem with the inheritance hierarchy and violates the Liskov Substitution Principle.

## Why It's a Problem

- **Violates "is-a" relationship**: Inheritance should represent a genuine conceptual relationship, not just code reuse
- **Misleads developers**: Creates confusion about class responsibilities and relationships
- **Increases coupling**: Forced dependencies between unrelated concepts
- **Breaks polymorphism**: Subclasses that throw exceptions violate substitutability
- **Maintenance burden**: Changes to parent classes cascade unpredictably

## Signs and Symptoms

- A subclass overrides parent methods just to throw exceptions
- Most inherited methods/properties go unused in the subclass
- The parent and child classes represent fundamentally different concepts
- You find yourself with conditional logic checking the actual type instead of trusting polymorphism
- The inheritance feels forced or arbitrary in code reviews

## Before/After

### Problem: Bird Hierarchy (Before)

```php
<?php

declare(strict_types=1);

abstract class Bird
{
    abstract public function fly(): void;
    abstract public function layEgg(): void;
}

class Sparrow extends Bird
{
    public function fly(): void
    {
        echo "Sparrow flying";
    }

    public function layEgg(): void
    {
        echo "Laying egg";
    }
}

class Penguin extends Bird
{
    public function fly(): void
    {
        throw new RuntimeException('Penguins cannot fly');
    }

    public function layEgg(): void
    {
        echo "Laying egg";
    }
}
```

### Solution: Extract to Interface (After)

```php
<?php

declare(strict_types=1);

interface Swimmer
{
    public function swim(): void;
}

interface Flyer
{
    public function fly(): void;
}

interface EggLayer
{
    public function layEgg(): void;
}

class Sparrow implements Flyer, EggLayer
{
    public function fly(): void
    {
        echo "Sparrow flying";
    }

    public function layEgg(): void
    {
        echo "Laying egg";
    }
}

class Penguin implements Swimmer, EggLayer
{
    public function swim(): void
    {
        echo "Penguin swimming";
    }

    public function layEgg(): void
    {
        echo "Laying egg";
    }
}
```

## Recommended Refactorings

### 1. Replace Inheritance with Composition (Delegation)
Use composition when classes share behavior but lack a genuine "is-a" relationship. Move shared code into helper classes.

```php
<?php

declare(strict_types=1);

readonly class DatabaseLogger
{
    public function __construct(
        private LogRepository $repository
    ) {}

    public function log(string $message): void
    {
        $this->repository->save($message);
    }
}

readonly class FileLogger
{
    public function __construct(
        private LogRepository $repository
    ) {}

    public function log(string $message): void
    {
        $this->repository->save($message);
    }
}
```

### 2. Extract a Proper Base Class
Identify what's genuinely shared and create a minimal parent class with only essential members.

```php
<?php

declare(strict_types=1);

abstract readonly class Logger
{
    public function __construct(
        protected string $level = 'INFO'
    ) {}

    abstract public function log(string $message): void;

    protected function format(string $message): string
    {
        return sprintf('[%s] %s', $this->level, $message);
    }
}

final class ConsoleLogger extends Logger
{
    public function log(string $message): void
    {
        echo $this->format($message);
    }
}
```

### 3. Use Enums for Type Safety
Replace inheritance hierarchies with enums when representing fixed sets of related values.

```php
<?php

declare(strict_types=1);

enum TransportMode
{
    case Air;
    case Land;
    case Sea;

    public function capabilities(): array
    {
        return match ($this) {
            self::Air => ['fly', 'land'],
            self::Land => ['drive', 'park'],
            self::Sea => ['swim', 'dock'],
        };
    }
}
```

## Exceptions

Refused Bequest is acceptable in these scenarios:

- **Deliberate interface compliance**: Using a base class for type-hinting while intentionally overriding methods (with clear documentation)
- **Legacy code**: Gradual refactoring of inherited systems where immediate changes aren't feasible
- **Template Method Pattern**: Abstract base class with some methods meant to be overridden while others are consistently used
- **Library design**: When a base class defines a contract but implementations vary significantly

## Related Smells

- **Parallel Inheritance Hierarchies**: Multiple inheritance chains that mirror each other
- **Inappropriate Intimacy**: Classes that know too much about each other's internals
- **Large Class**: Often the root cause when a parent class does too much
- **Lazy Class**: Subclass that adds little value over its parent

## Refactoring.guru Guidance

### Signs and Symptoms
A subclass uses only some of the methods and properties inherited from its parents. The hierarchy is off-kilter. The unneeded methods may simply go unused or be redefined to give off exceptions.

### Reasons for the Problem
Someone was motivated to create inheritance between classes only by the desire to reuse the code in a superclass. But the superclass and subclass are completely different.

### Treatment
- **Replace Inheritance with Delegation**: Use when the inheritance relationship does not actually make sense and the classes share little in common
- **Extract Superclass**: Remove unneeded fields and methods from the subclass, then extract common elements into a new parent class that both the original classes can inherit from

### Payoff
- Improved code clarity and organization
- Eliminates confusing hierarchies where unrelated concepts inherit from one another

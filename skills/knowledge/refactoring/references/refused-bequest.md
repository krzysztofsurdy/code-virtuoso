# Refused Bequest

## Overview

Refused Bequest occurs when a subclass inherits from a parent but ignores or rejects much of what it receives. The subclass may leave inherited methods unused, or override them only to throw exceptions. This signals a wrong inheritance relationship: the subclass borrows code and is not a true specialization of the parent. The Liskov Substitution Principle suffers most, because you cannot safely substitute the child where the parent is expected.

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- **False "is-a" relationship**: inheritance should express a real conceptual specialization, not act as a shortcut for code reuse.
- **Developer confusion**: the hierarchy gives misleading signals about what each class represents and how to use it.
- **Artificial coupling**: the subclass depends on a parent it has little real connection to.
- **Broken substitutability**: subclasses that throw exceptions from inherited methods cannot replace the parent.
- **Unpredictable cascading**: changes to the parent ripple into the subclass in unexpected ways.

## Signs and symptoms

- A subclass overrides parent methods only to throw exceptions or return dummy values
- Most inherited methods and properties go unused in the subclass
- Parent and child represent different domain concepts
- Client code uses type checks or instanceof instead of trusting polymorphism
- Code reviewers ask why the inheritance relationship exists

## Before and after

### Problem: bird hierarchy (before)

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

### Solution: extract to interface (after)

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

## Recommended refactorings

### 1. Replace Inheritance with Composition (Delegation)

Use composition when classes share behavior but have no real "is-a" relationship. Move shared code into helper classes.

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

### 2. Extract a proper base class

Find what is shared and create a minimal parent class with only the essential members.

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

### 3. Use enums for type safety

Replace inheritance hierarchies with enums when you model a fixed set of related values.

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

Refused Bequest is acceptable in these cases:

- **Deliberate interface compliance**: a base class is used for type-hinting while methods are overridden on purpose (document this clearly)
- **Legacy code**: gradual refactoring of inherited systems where immediate changes are not feasible
- **Template Method pattern**: an abstract base class with some methods meant to be overridden and others used as they are
- **Library design**: a base class defines a contract, and implementations vary a lot

## Related smells

- **Parallel Inheritance Hierarchies**: multiple inheritance chains that mirror each other's structure
- **Inappropriate Intimacy**: classes that know too much about each other's implementation details
- **Large Class**: an overly broad parent class is a common root cause. The child needs only a fraction of what the parent offers.
- **Lazy Class**: a subclass that adds almost nothing beyond its parent

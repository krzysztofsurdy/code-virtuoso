# Lazy Class

A Lazy Class does not carry enough weight to justify its place in the codebase. Every class has a cost: developers must learn what it does, maintain it, and navigate around it. When a class contributes too little to offset that cost, fold it into another class or remove it.

This commonly happens when:
- A class was built for future functionality that never arrived
- Successive refactorings stripped the class of its original responsibilities
- A class acts as a thin pass-through to another class without adding logic

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

Each class in the codebase demands:
- **Cognitive investment**: developers must understand its role and how it fits into the system
- **Ongoing upkeep**: interface changes, documentation, and tests all cost effort
- **Structural overhead**: unnecessary classes deepen hierarchies and widen the dependency graph
- **Navigation friction**: more files to browse and search when working on related functionality

A class that does not earn its keep adds technical debt and returns nothing for it.

## Signs and symptoms

- A class has only one or two trivial methods that would fit in another class
- A subclass adds almost nothing beyond what its parent already provides
- A class exists mainly as a placeholder for anticipated future work
- Removing the class would need only minor, localized refactoring
- The class duplicates a narrow responsibility that another class already handles

## Before and after

### Before: lazy utility class

```php
<?php

declare(strict_types=1);

class UserLogger
{
    public function log(User $user, string $action): void
    {
        echo $user->name . " performed " . $action . "\n";
    }
}

class User
{
    public function __construct(
        public string $name,
        private UserLogger $logger
    ) {}

    public function performAction(string $action): void
    {
        $this->logger->log($this, $action);
        echo "Action completed\n";
    }
}
```

### After: inlined responsibility

```php
<?php

declare(strict_types=1);

readonly class User
{
    public function __construct(
        public string $name
    ) {}

    public function performAction(string $action): void
    {
        $this->logAction($action);
        echo "Action completed\n";
    }

    private function logAction(string $action): void
    {
        echo $this->name . " performed " . $action . "\n";
    }
}
```

### Before: lazy subclass

```php
<?php

declare(strict_types=1);

abstract class Document
{
    abstract public function export(): string;
}

class PdfDocument extends Document
{
    public function export(): string
    {
        return "PDF content";
    }
}

class SimplePdfDocument extends PdfDocument
{
    // No additional functionality - inherits everything
}
```

### After: collapse hierarchy

```php
<?php

declare(strict_types=1);

abstract class Document
{
    abstract public function export(): string;
}

readonly class PdfDocument extends Document
{
    public function export(): string
    {
        return "PDF content";
    }
}

// SimplePdfDocument removed entirely
```

## Recommended refactorings

### 1. Inline Class

Merge a lazy class's responsibilities into another class that uses it.

**When to use**: the class is a thin wrapper or has methods that logically belong in another class.

**Process**:
- Move all methods and properties to the target class
- Update all references to use the target class
- Remove the original class
- Use private methods for internal logic

### 2. Collapse Hierarchy

Remove subclasses that add no meaningful functionality.

**When to use**: a subclass does not override or extend the parent in any meaningful way.

**Process**:
- Copy any unique methods to the parent (if any)
- Update all references to use the parent class
- Delete the subclass
- Simplify inheritance chains

### 3. Remove as placeholder

Some lazy classes exist as placeholders for future features.

**When to use**: the functionality is expected but not yet needed.

**Process**:
- Document why the class exists
- Set up code review guidelines for its use
- Create a task to revisit it if the feature materializes
- Consider extracting it to a separate module or plugin

## Exceptions

Keep a lazy class when:

- **Planned feature development**: the class is reserved for near-term functionality with a documented roadmap
- **Framework requirements**: inheritance hierarchies required by frameworks (e.g., Symfony entities, event subscribers) must follow specific patterns
- **Plugin or extension points**: classes designed as extension points for future or third-party plugins
- **Backward compatibility**: removing a public class would break the API, so deprecate it instead
- **Intentional minimal interface**: the class is valuable for its simplicity and clarity, not for its method count

## Related smells

- **Dead Code**: code that is never executed. A Lazy Class is a class-level form of the same problem.
- **Feature Envy**: a class that works more with another class's data than its own often has logic that belongs in that other class.
- **Speculative Generality**: classes built for needs that never materialized. A common origin of Lazy Classes.
- **Middleware classes**: classes that exist only to wire other classes together without contributing logic.
- **Duplicate Code**: several small classes with overlapping functionality that could be consolidated into one.

A Lazy Class sometimes exists on purpose to mark where future functionality will go. Keep it only if the planned work is imminent and documented. Otherwise remove it and recreate it when the need is real.

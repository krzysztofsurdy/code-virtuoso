# Lazy Class

## Overview

A Lazy Class is one that does not carry enough weight to justify its presence in the codebase. Every class incurs a cost - developers must learn what it does, maintain it, and navigate around it. When a class contributes too little to offset these costs, it should be folded into another class or removed entirely.

This commonly happens when:
- A class was built for future functionality that never arrived
- Successive refactorings gradually stripped the class of its original responsibilities
- A class acts as a thin pass-through to another class without adding meaningful logic

## Why It's a Problem

Each class in the codebase demands:
- **Cognitive Investment**: Developers must understand its role and how it fits into the system
- **Ongoing Upkeep**: Interface changes, documentation, and test maintenance all cost effort
- **Structural Overhead**: Unnecessary classes add depth to hierarchies and widen the dependency graph
- **Navigation Friction**: More files to browse and search through when working on related functionality

Retaining classes that do not earn their keep steadily inflates technical debt without delivering compensating value.

## Signs and Symptoms

- A class has only one or two trivial methods that would fit naturally in another class
- A subclass adds negligible functionality beyond what its parent already provides
- A class exists mainly as a placeholder for anticipated future work
- Removing the class would require only minor, localized refactoring
- The class duplicates a narrow responsibility that another class already handles

## Before/After

### Before: Lazy Utility Class

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

### After: Inlined Responsibility

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

### Before: Lazy Subclass

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

### After: Collapse Hierarchy

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

## Recommended Refactorings

### 1. Inline Class
Merge a lazy class's responsibilities into another class that uses it.

**When to use**: The class is a thin wrapper or has methods that logically belong in another class.

**Process**:
- Move all methods and properties to the target class
- Update all references to use the target class
- Remove the original class
- Use private methods for internal logic

### 2. Collapse Hierarchy
Remove unnecessary subclasses that don't add meaningful functionality.

**When to use**: A subclass doesn't override or extend the parent meaningfully.

**Process**:
- Copy any unique methods to the parent (if any)
- Update all references to use the parent class
- Delete the subclass
- Simplify inheritance chains

### 3. Remove as Placeholder
Sometimes lazy classes exist as placeholders for future features.

**When to use**: The functionality is truly anticipated but not yet needed.

**Process**:
- Document why it exists with clear comments
- Set up code review guidelines for its use
- Create a task to revisit if the feature materializes
- Consider extracting to a separate module/plugin

## Exceptions

Keep a class (as a lazy class) when:

- **Planned Feature Development**: The class is explicitly reserved for near-term functionality with a documented roadmap
- **Framework Requirements**: Inheritance hierarchies required by frameworks (e.g., Symfony entities, event subscribers) must follow specific patterns
- **Plugin/Extension Points**: Classes designed as extension points for future or third-party plugins
- **Backward Compatibility**: Removing a public class would break the API; deprecate instead
- **Intentional Minimal Interface**: A class provides value through explicit simplicity and clarity, not just through method count

## Related Smells

- **Dead Code**: Code that is never executed - Lazy Classes are a class-level manifestation of the same problem
- **Feature Envy**: A class that spends more time working with another class's data than its own often signals the logic belongs in that other class
- **Speculative Generality**: Classes built for anticipated needs that never materialized - a common origin of Lazy Classes
- **Middleware Classes**: Classes that exist solely to wire other classes together without contributing logic
- **Duplicate Code**: Multiple small classes with overlapping functionality that could be consolidated into one

Note: A Lazy Class sometimes exists intentionally to mark where future functionality will be added. In that case, keep it only if the planned work is imminent and documented. Otherwise, remove it and recreate it when the need is real - the balance should tip toward simplicity.

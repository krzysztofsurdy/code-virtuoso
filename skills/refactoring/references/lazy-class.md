# Lazy Class

## Overview

A Lazy Class is a code smell that refers to a class that doesn't provide enough functionality to justify its existence. Classes consume development time and maintenance costs, so if a class doesn't do enough to earn its keep in the codebase, it should be removed or merged with other classes.

This typically occurs when:
- A class is created for anticipated functionality that never materializes
- Refactoring leaves a class with minimal responsibilities
- A class serves as a thin wrapper around another class without adding real value

## Why It's a Problem

Every class in your codebase requires:
- **Cognitive Load**: Developers must understand its purpose and functionality
- **Maintenance Costs**: Changes to interfaces, documentation, and testing
- **Complexity**: Unnecessary inheritance hierarchies and dependencies
- **Navigation**: More files to browse and understand

Keeping unnecessary classes increases technical debt and makes codebases harder to maintain without providing compensating benefits.

## Signs and Symptoms

- A class has only one or two methods that could belong elsewhere
- A subclass adds minimal functionality beyond its parent class
- A class exists primarily as a placeholder for future features
- Removing a class would require minimal refactoring elsewhere
- The class has a single, narrow responsibility that duplicates functionality in another class

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

- **Dead Code**: Classes or methods that are never used
- **Feature Envy**: A class that seems more interested in another class's data than its own
- **Speculative Generality**: Building features "for the future" that aren't needed yet
- **Middleware Classes**: Classes that exist only to connect other classes without adding logic
- **Duplicate Code**: Similar functionality across multiple small classes that could be consolidated

## Refactoring.guru Guidance

### Signs and Symptoms

Understanding and maintaining classes always costs time and money. So if a class does not do enough to earn your attention, it should be deleted.

### Reasons for the Problem

- A class may have been designed to be fully functional but after refactoring it has become ridiculously small.
- A class may have been created to support planned future development work that never materialized.

### Treatment

- **Inline Class**: Merge the lazy class's functionality into another class that uses it.
- **Collapse Hierarchy**: For subclasses or superclasses with minimal added functionality, merge them into their parent or child.

### Payoff

- Reduced code size.
- Easier maintenance.

### When to Ignore

Sometimes a Lazy Class is created to delineate intentions for future development. In this case, try to maintain a balance between clarity and simplicity in your code.

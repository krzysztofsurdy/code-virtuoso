## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Dead code is code that exists in the codebase but never runs: unused variables, unreferenced methods, unreachable branches, abandoned classes, or parameters that no caller uses. It builds up when requirements change or a refactoring is left half-finished. New logic is added, but the old implementation it replaces is never removed.

## Why it's a problem

Dead code slows development in several ways:

- **Wasted attention**: Developers spend time reading and working around code that does nothing
- **Navigation friction**: More code to sift through when searching for active logic
- **False complexity**: Dead paths make the system look more complex than it is
- **Debugging noise**: A larger codebase means more to investigate when problems arise
- **Quality signal**: Leftover dead code suggests unfinished refactoring and weak code hygiene

## Signs and symptoms

- Variables, parameters, or class fields that are assigned but never read
- Methods with zero callers anywhere in the codebase
- Conditional branches that can never be reached given the possible input values
- Entire classes or traits with no references from production code
- Function parameters that are accepted but never used inside the method body
- Remnants of old feature flags or temporary debugging scaffolding

## Before and after

### Before: unused parameters and variables

```php
<?php
declare(strict_types=1);

readonly class UserValidator
{
    public function validateEmail(string $email, bool $isLegacy, int $unusedThreshold): bool
    {
        $domain = 'example.com';
        $oldValidationResult = null;

        return str_contains($email, '@') && str_ends_with($email, '.com');
    }

    public function resetPassword(User $user, bool $notifyViaEmail): string
    {
        return 'reset_' . uniqid();
    }
}
```

### After: no dead code

```php
<?php
declare(strict_types=1);

readonly class UserValidator
{
    public function validateEmail(string $email): bool
    {
        return str_contains($email, '@') && str_ends_with($email, '.com');
    }

    public function resetPassword(User $user): string
    {
        return 'reset_' . uniqid();
    }
}
```

### Before: unused method and dead branch

```php
<?php
declare(strict_types=1);

enum OrderStatus {
    case Pending;
    case Confirmed;
    case Shipped;
    case Delivered;
}

class OrderProcessor
{
    public function processOrder(Order $order, OrderStatus $status): void
    {
        // Legacy method no longer called
        $legacyResult = $this->oldDeprecatedCalculation();

        match($status) {
            OrderStatus::Pending => $this->confirmOrder($order),
            OrderStatus::Confirmed => $this->shipOrder($order),
            false => $this->handleError(), // Dead code - can never execute
            default => null,
        };
    }

    private function oldDeprecatedCalculation(): array
    {
        return [];
    }
}
```

### After: focused implementation

```php
<?php
declare(strict_types=1);

enum OrderStatus {
    case Pending;
    case Confirmed;
    case Shipped;
    case Delivered;
}

class OrderProcessor
{
    public function processOrder(Order $order, OrderStatus $status): void
    {
        match($status) {
            OrderStatus::Pending => $this->confirmOrder($order),
            OrderStatus::Confirmed => $this->shipOrder($order),
            default => null,
        };
    }
}
```

## Recommended refactorings

### 1. Remove unused variables
Delete variables declared but never read. Check for assignments that are overwritten before they are used.

```php
// Remove this
$debugInfo = [];
$debugInfo = getSomeData();
```

### 2. Remove unused parameters
Use IDE refactoring tools or update method signatures by hand. Check that callers do not rely on the parameter's side effects.

```php
// Before
public function process(string $name, int $unused): void

// After
public function process(string $name): void
```

### 3. Remove unreachable code
Delete branches that can never execute (after return statements, in switch statements with no matching cases).

### 4. Remove dead methods and classes
Use your IDE's "Find Usages" feature to find methods and classes with zero references, then delete them.

### 5. Extract to a separate package
If code might be useful later, move it to a separate deprecated package instead of keeping it in production.

## Exceptions

Dead code may be acceptable in these cases:

- **Public API**: Methods in public libraries or APIs must stay for backward compatibility. Mark them `@deprecated` instead of removing them.
- **Interface compliance**: Methods required by implemented interfaces cannot be removed without breaking the contract.
- **Intentional stubs**: Placeholder implementations for future features (mark them with comments).
- **Framework requirements**: Some frameworks require specific methods even if your application does not use them.
- **Known usage outside the codebase**: Third-party code may depend on methods your codebase does not use.

## Related smells

- **Duplicate Code**: Dead code often appears when one copy of duplicated logic is maintained and the other is abandoned
- **Feature Envy**: Methods that belong in another class can become dead in their current class after logic is reorganized
- **Speculative Generality**: Parameters, branches, and abstractions built for needs that never came
- **Lazy Class**: Entire classes with no callers are the class-level equivalent of dead methods
- **Comments**: Commented-out code often comes with dead code and carries the same risks

The fastest way to find dead code is IDE tooling (unused symbol highlighting, "Find Usages" returning zero results). For dead classes or subclasses, use Inline Class and Collapse Hierarchy. For unused parameters, use Remove Parameter. Less code means less to maintain, and deleting unused code is one of the safest refactorings there is.

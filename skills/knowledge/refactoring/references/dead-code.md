## Overview

Dead code is any code that exists in the codebase but is never executed - unused variables, unreferenced methods, unreachable branches, abandoned classes, or parameters that no caller passes meaningfully. It typically accumulates when requirements change or refactoring is left half-finished: new logic is added, but the old implementation it replaces is never cleaned up.

## Why It's a Problem

Dead code creates a drag on development in several ways:

- **Wasted Attention**: Developers spend time reading, understanding, and working around code that does nothing
- **Navigation Friction**: More code to sift through when searching for active logic
- **Illusory Complexity**: Dead paths make the system appear more complex than it actually is
- **Debugging Noise**: A larger codebase means a larger surface area to investigate when problems arise
- **Quality Signal**: Leftover dead code suggests incomplete refactoring and insufficient code hygiene

## Signs and Symptoms

- Variables, parameters, or class fields that are assigned but never read
- Methods with zero callers anywhere in the codebase
- Conditional branches that can never be reached given the possible input values
- Entire classes or traits with no references from production code
- Function parameters that are accepted but never used inside the method body
- Remnants of old feature flags or temporary debugging scaffolding

## Before/After

### Before: Unused Parameters and Variables

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

### After: Clean, No Dead Code

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

### Before: Unused Method and Dead Branch

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

### After: Focused Implementation

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

## Recommended Refactorings

### 1. **Remove Unused Variables**
Delete variables declared but never read. Check for assignments that are immediately overwritten without being used.

```php
// Remove this
$debugInfo = [];
$debugInfo = getSomeData();
```

### 2. **Remove Unused Parameters**
Use IDE refactoring tools or manually update method signatures. Ensure callers don't rely on the parameter's side effects.

```php
// Before
public function process(string $name, int $unused): void

// After
public function process(string $name): void
```

### 3. **Remove Unreachable Code**
Delete branches that can never execute (after return statements, in switch statements with no matching cases).

### 4. **Eliminate Dead Methods and Classes**
Use your IDE's "Find Usages" feature to identify methods/classes with zero references, then safely delete them.

### 5. **Extract to Separate Package**
If code might be useful later, move it to a separate deprecated package rather than keeping it in production.

## Exceptions

When dead code may be acceptable:

- **Public API**: Methods in public libraries or APIs must be maintained for backward compatibility. Mark with `@deprecated` instead of removing.
- **Interface Compliance**: Methods required by implemented interfaces cannot be removed without breaking contract.
- **Intentional Stubs**: Placeholder implementations for future features (should be clearly marked with comments).
- **Framework Requirements**: Some frameworks require specific methods even if unused by your application.
- **Known Usage Outside Codebase**: Third-party code may depend on methods your codebase doesn't use.

## Related Smells

- **Duplicate Code**: Dead code often emerges when one copy of duplicated logic gets maintained while the other is abandoned
- **Feature Envy**: Methods that belong in a different class sometimes become dead in their current location after logic is reorganized
- **Speculative Generality**: Over-engineered parameters, branches, and abstractions built for anticipated needs that never materialized
- **Lazy Class**: Entire classes with no callers are the class-level equivalent of dead methods
- **Comments**: Commented-out code blocks frequently accompany dead code and carry the same risks

The fastest way to detect dead code is through IDE tooling (unused symbol highlighting, "Find Usages" returning zero results). For dead classes or subclasses, Inline Class and Collapse Hierarchy help consolidate. For unused parameters, Remove Parameter cleans up the signature. The goal is straightforward: less code means less to maintain, and deleting unused code is one of the safest refactorings you can perform.

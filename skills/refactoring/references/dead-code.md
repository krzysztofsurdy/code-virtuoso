## Overview

Dead code refers to any code that is unreachable or never executed in normal circumstances—unused variables, parameters, methods, or entire classes that have become obsolete due to changing requirements or refactoring. Dead code represents technical debt that accumulates when developers add functionality but fail to remove the old implementation.

## Why It's a Problem

Dead code introduces several maintenance challenges:

- **Cognitive Overload**: Developers waste time understanding which code is actually active versus which paths are dead ends
- **Maintenance Burden**: More code to navigate, comprehend, and potentially fix
- **False Complexity**: Creates illusion of complexity where simpler implementations exist
- **Bug Risk**: Increases the surface area for potential bugs and makes debugging harder
- **Poor Code Quality**: Signals incomplete refactoring and lack of attention to code hygiene

## Signs and Symptoms

- Unused variables, parameters, or class fields
- Methods that are never called anywhere in the codebase
- Branches in conditional statements that can never be reached
- Entire classes or traits with no references
- Parameters to functions that methods don't use
- Dead branches from old feature flags or temporary debugging

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

- **Duplicate Code**: Often dead code emerges when one copy of duplicated code is partially maintained
- **Feature Envy**: Methods that should be elsewhere may appear as dead code in wrong classes
- **Speculative Generality**: Over-engineering with unused parameters and branches
- **Lazy Class**: Entire classes that do too little may have no callers
- **Comments**: Dead code often accumulates alongside commented-out code

## Refactoring.guru Guidance

### Signs and Symptoms

A variable, parameter, field, method, or class is no longer used (usually because it is obsolete).

### Reasons for the Problem

- When requirements change or corrections are made, nobody had time to clean up the old code.
- Dead code can also appear in complex conditionals when certain branches become unreachable due to errors or changed circumstances.

### Treatment

- The quickest way to find dead code is to use a good IDE. Delete unused code and unneeded files.
- **Inline Class** or **Collapse Hierarchy**: Use when dealing with unnecessary classes or subclasses.
- **Remove Parameter**: Eliminate unneeded method parameters.

### Payoff

- Reduced code size.
- Simpler, easier maintenance and support.

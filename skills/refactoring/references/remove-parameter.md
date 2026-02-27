## Overview

Remove Parameter is a refactoring technique that eliminates unused parameters from method signatures. When a parameter isn't used in the body of a method, it becomes dead weight that clutters the interface and confuses developers reading the code.

This refactoring ensures a method contains only the parameters it truly requires, making the codebase more maintainable and easier to understand.

## Motivation

Unused parameters create several problems:

- **Confusion**: Developers must figure out why a parameter exists if it's not used, wasting cognitive effort.
- **Code Clarity**: The method signature should accurately reflect what the method actually needs.
- **API Simplicity**: Simpler method signatures are easier to understand, call, and maintain.
- **Avoiding Speculation**: Parameters are often added "just in case," but anticipated changes often remain anticipated. Don't add parameters preemptively.

## Mechanics

The refactoring process follows these steps:

1. **Identify unused parameters**: Scan the method body to find parameters that are never referenced.
2. **Check for overrides**: Verify if the parameter is used in superclass or subclass implementations.
3. **Update callers**: Find all places where this method is called and update them to omit the unused argument.
4. **Remove the parameter**: Delete the parameter from the method signature.
5. **Handle public APIs**: For public methods, consider deprecation before complete removal.

## Before/After Example (PHP 8.3+)

### Before: Unused Parameter

```php
class UserService
{
    public function updateEmail(User $user, string $email, string $unused): void
    {
        $user->setEmail($email);
        $user->save();
    }
}

// Usage
$service->updateEmail($user, 'new@example.com', 'this is never used');
```

### After: Parameter Removed

```php
class UserService
{
    public function updateEmail(User $user, string $email): void
    {
        $user->setEmail($email);
        $user->save();
    }
}

// Usage
$service->updateEmail($user, 'new@example.com');
```

### With Named Arguments (PHP 8.0+)

```php
class ReportGenerator
{
    // Before
    public function generate(
        Report $report,
        string $format,
        string $title,
        bool $unusedFlag,
        array $options = []
    ): string {
        return $this->render($report, $format, $title, $options);
    }

    // After
    public function generate(
        Report $report,
        string $format,
        string $title,
        array $options = []
    ): string {
        return $this->render($report, $format, $title, $options);
    }
}

// Callers using named arguments adapt automatically
$generator->generate(
    report: $myReport,
    format: 'pdf',
    title: 'Monthly Report',
    options: ['pageSize' => 'A4']
);
```

## Benefits

- **Simpler API**: Methods are easier to understand and use.
- **Reduced Confusion**: No more wondering why a parameter exists.
- **Better Maintainability**: Clearer intent of what the method actually needs.
- **Easier Testing**: Fewer arguments to mock or provide in tests.
- **Performance**: Eliminates unnecessary argument passing.
- **Type Safety**: Makes the contract between caller and method clearer.

## When NOT to Use

Avoid this refactoring if:

- **The parameter is used in subclass/superclass implementations**: Polymorphic methods must maintain compatible signatures.
- **The method is part of a widely-used public API**: Removing parameters could break external code.
- **It's required by an interface contract**: Implementing an interface requires matching the method signature.
- **The parameter might be needed for forward compatibility**: In libraries, sometimes parameters are kept for future use.

## Related Refactorings

- **Add Parameter**: The opposite refactoring; use when a method needs additional data.
- **Rename Method**: Often combined with Remove Parameter to better reflect intent.
- **Change Method Signature**: A broader refactoring that encompasses parameter changes.
- **Extract Method**: May eliminate parameters by creating focused, single-responsibility methods.

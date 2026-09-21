## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Example (PHP 8.3+)](#beforeafter-example-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)

## Overview

Remove Parameter strips an unused parameter from a method signature. A parameter that is never used in the method body adds noise to the interface. It also forces callers to pass a value that does nothing. Dropping it makes the contract match what the method needs.

## Motivation

Unused parameters cause several problems:

- **Wasted attention**: Developers spend time working out why the parameter exists when it contributes nothing
- **Misleading signatures**: The method appears to use data it ignores, which erodes trust in the API
- **Heavier call sites**: Callers must build and pass an argument that is immediately discarded
- **Speculative design**: Parameters are often added "just in case" for changes that never arrive

## Mechanics

1. **Identify unused parameters**: Scan the method body for parameters that are never referenced.
2. **Check for overrides**: Verify whether the parameter is used in superclass or subclass implementations.
3. **Update callers**: Find every call to the method and drop the unused argument.
4. **Remove the parameter**: Delete it from the method signature.
5. **Handle public APIs**: For public methods, consider deprecation before removing the parameter outright.

## Before/After Example (PHP 8.3+)

### Before: unused parameter

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

### After: parameter removed

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

### With named arguments (PHP 8.0+)

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

// Callers using named arguments keep working
$generator->generate(
    report: $myReport,
    format: 'pdf',
    title: 'Monthly Report',
    options: ['pageSize' => 'A4']
);
```

## Benefits

- **Honest interface**: The signature lists exactly the data the method consumes
- **Lighter call sites**: Callers no longer fabricate throwaway arguments
- **Less confusion**: Future readers do not wonder what the parameter was for
- **Simpler testing**: Fewer arguments to set up in test doubles and fixtures

## When NOT to use

Avoid this refactoring if:

- **The parameter is used in subclass or superclass implementations**: Polymorphic methods must keep compatible signatures.
- **The method is part of a widely used public API**: Removing parameters could break external code.
- **An interface contract requires it**: An implementing method must match the interface signature.
- **The parameter is kept for forward compatibility**: Libraries sometimes reserve parameters for future use.

## Related Refactorings

- **Add Parameter**: The opposite refactoring; use it when a method needs additional data.
- **Rename Method**: Often combined with Remove Parameter to better reflect intent.
- **Add Parameter** and **Rename Method**: The other changes to a method's signature.
- **Extract Method**: Can eliminate parameters by creating small, focused methods.

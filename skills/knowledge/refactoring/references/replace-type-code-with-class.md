## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: PHP 8.3+ example](#before-php-83-example)
- [After: PHP 8.3+ example](#after-php-83-example)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Replace Type Code with Class converts magic numbers and strings that stand for categories or statuses into enumeration types or dedicated classes. Invalid values are then rejected by the type system instead of by runtime conditionals.

## Motivation

### When to apply

- **Raw numeric or string codes**: integer codes (1, 2, 3) or string literals ('active', 'pending', 'inactive') represent types.
- **Repeated validation**: the same check that a value belongs to the expected set appears in several places.
- **Scattered definitions**: type code constants are defined in different locations instead of one authoritative source.
- **No IDE help**: the IDE cannot autocomplete or safely rename plain strings or integers.
- **Behavior attached to categories**: different statuses or categories carry validation rules and behavior.

### Why it matters

A primitive type code offers no protection against invalid values. An enum or dedicated type rules out illegal values, gives the IDE something to work with, and names the concept.

## Mechanics

1. **Catalog type codes**: find every magic number or string that represents a distinct category.
2. **Define an enum or class**: PHP 8.1+ enums are the natural choice for simple type codes.
3. **Enumerate all values**: give every valid code a corresponding enum case.
4. **Replace primitive fields**: change variables that store type codes to the new enum type.
5. **Update signatures**: change method parameter and return types from int/string to the enum.
6. **Remove manual validation**: delete the conditionals that check type code validity.
7. **Attach behavior**: move type-specific logic into methods on the enum or class.
8. **Run the test suite**: confirm that all transitions and validations still work.

## Before: PHP 8.3+ example

```php
<?php

declare(strict_types=1);

class User
{
    private int $status; // Magic number: 1=active, 2=inactive, 3=pending
    private string $role; // Magic string: 'admin', 'user', 'guest'

    public function __construct(int $status, string $role)
    {
        // Manual validation
        if (!in_array($status, [1, 2, 3], true)) {
            throw new InvalidArgumentException('Invalid status code: ' . $status);
        }
        if (!in_array($role, ['admin', 'user', 'guest'], true)) {
            throw new InvalidArgumentException('Invalid role: ' . $role);
        }

        $this->status = $status;
        $this->role = $role;
    }

    public function isActive(): bool
    {
        return $this->status === 1; // Magic number comparison
    }

    public function getStatusLabel(): string
    {
        return match($this->status) {
            1 => 'Active',
            2 => 'Inactive',
            3 => 'Pending',
            default => 'Unknown'
        };
    }

    public function canAccessAdmin(): bool
    {
        return $this->role === 'admin'; // String comparison
    }

    public function setStatus(int $status): void
    {
        if (!in_array($status, [1, 2, 3], true)) {
            throw new InvalidArgumentException('Invalid status');
        }
        $this->status = $status;
    }

    public function getStatus(): int
    {
        return $this->status; // Returns magic number
    }
}

// Usage scattered across codebase
$user = new User(1, 'admin');
if ($user->getStatus() === 1) {
    // Active user logic
}
$user->setStatus(2); // What does 2 mean?
```

## After: PHP 8.3+ example

```php
<?php

declare(strict_types=1);

enum UserStatus: int
{
    case Active = 1;
    case Inactive = 2;
    case Pending = 3;

    public function label(): string
    {
        return match($this) {
            self::Active => 'Active',
            self::Inactive => 'Inactive',
            self::Pending => 'Pending',
        };
    }

    public function isActive(): bool
    {
        return $this === self::Active;
    }
}

enum UserRole: string
{
    case Admin = 'admin';
    case User = 'user';
    case Guest = 'guest';

    public function canAccessAdmin(): bool
    {
        return $this === self::Admin;
    }

    public function permissions(): array
    {
        return match($this) {
            self::Admin => ['read', 'write', 'delete'],
            self::User => ['read', 'write'],
            self::Guest => ['read'],
        };
    }
}

class User
{
    public function __construct(
        private UserStatus $status,
        private UserRole $role,
    ) {}

    public function isActive(): bool
    {
        return $this->status->isActive();
    }

    public function getStatusLabel(): string
    {
        return $this->status->label();
    }

    public function canAccessAdmin(): bool
    {
        return $this->role->canAccessAdmin();
    }

    public function setStatus(UserStatus $status): void
    {
        $this->status = $status; // Type-safe, no validation needed
    }

    public function getStatus(): UserStatus
    {
        return $this->status; // Returns meaningful enum type
    }

    public function getRole(): UserRole
    {
        return $this->role;
    }
}

// Usage is now clear and type-safe
$user = new User(UserStatus::Active, UserRole::Admin);
if ($user->getStatus() === UserStatus::Active) {
    // IDE knows exactly what we're checking
}
$user->setStatus(UserStatus::Pending); // Type-safe assignment
$permissions = $user->getRole()->permissions(); // IDE autocomplete available
```

## Benefits

- **Type safety**: the compiler and IDE reject invalid type assignments during development.
- **Self-documenting**: enum case names replace opaque numbers.
- **IDE tooling**: autocompletion, jump-to-definition, and rename support work out of the box.
- **No manual validation**: the type system enforces that only valid values are used.
- **Encapsulated behavior**: type-related logic lives on the enum methods.
- **Centralized changes**: changing the set of allowed values means editing only the enum definition.

## When not to use

- **Dynamic values**: type codes from external APIs that change unpredictably.
- **User-defined categories**: end users can create new types at runtime.
- **Huge numeric ranges**: thousands of possible values are better served by a database lookup.
- **Legacy integration**: the refactoring would force extensive changes in external systems.
- **Strict compatibility**: third-party code mandates raw string or integer types.

## Related refactorings

- **Replace Data Value with Object**: for cases that need richer behavior than a simple enum.
- **Extract Class**: when type codes need their own data and methods.
- **Replace Conditional with Polymorphism**: replaces type-based conditionals with polymorphic dispatch.
- **Introduce Parameter Object**: bundles related type codes into a single parameter.
- **Self Encapsulate Field**: adds validation to primitive type code fields before upgrading to an enum.

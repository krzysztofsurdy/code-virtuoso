## Overview

Replace Type Code with Class eliminates magic numbers and strings that represent distinct types or statuses by replacing them with enumeration types or dedicated classes. This refactoring improves type safety, code clarity, and enables compile-time checking instead of runtime validation.

## Motivation

### When to Apply

- **Magic numbers/strings**: Using numeric codes (1, 2, 3) or string values ('active', 'pending', 'inactive') throughout code
- **Type validation**: Repeatedly checking if a value matches expected codes using conditionals
- **Scattered constants**: Type codes defined in multiple places rather than a single source of truth
- **No IDE support**: IDE can't help with autocompletion or refactoring of string-based types
- **Domain complexity**: Different statuses or types need validation logic and behavior

### Why It Matters

Type codes as primitives provide no type safety. Replacing them with enums or classes provides compile-time checking, eliminates invalid state transitions, enables IDE assistance, and makes code intent clearer through meaningful type names.

## Mechanics: Step-by-Step

1. **Identify type codes**: Find all magic numbers/strings representing distinct types or statuses
2. **Create enumeration type**: PHP 8.1+ enums are ideal for simple type codes
3. **Define all valid values**: Ensure all possible codes are represented
4. **Replace primitive fields**: Change variables holding type codes to the new enum type
5. **Update method signatures**: Change parameter/return types from int/string to enum
6. **Remove validation logic**: Delete conditional checks that validate type codes
7. **Add behavior**: Move type-related logic into enum methods or dedicated classes
8. **Test thoroughly**: Verify all type transitions and validations work correctly

## Before: PHP 8.3+ Example

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

## After: PHP 8.3+ Example

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

- **Type Safety**: Compiler/IDE prevents invalid type assignments at development time
- **Self-Documenting**: Enum names replace magic numbers; intent is immediately clear
- **IDE Assistance**: Autocomplete and refactoring support for type codes
- **Eliminates Validation**: No more scattered if-checks validating primitive values
- **Compile-Time Checking**: Invalid values caught before runtime
- **Behavior Encapsulation**: Type-related logic moves into enum methods
- **Reduced Bugs**: Impossible to accidentally use wrong code value
- **Better Maintainability**: Changing allowed values affects only the enum definition

## When NOT to Use

- **Truly dynamic values**: Codes from external APIs that change unpredictably
- **User-defined categories**: When users can create new types at runtime
- **Large numeric ranges**: Thousands of possible values (consider database lookup instead)
- **Legacy systems**: When refactoring old code requires extensive downstream changes
- **Strict compatibility**: When third-party code requires string/int types

## Related Refactorings

- **Replace Data Value with Object**: For more complex type code behavior
- **Extract Class**: When type codes need associated data and methods
- **Replace Conditional with Polymorphism**: To replace type-based conditionals with subclasses
- **Introduce Parameter Object**: For grouping related type codes as parameters
- **Self Encapsulate Field**: When adding validation to primitive type code fields

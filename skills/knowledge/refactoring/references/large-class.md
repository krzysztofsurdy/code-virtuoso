# Large Class Code Smell

## Overview

A Large Class has accumulated too many fields, methods, or lines of code, handling responsibilities that should belong to separate, focused classes. Growth is natural as a codebase evolves, but unchecked expansion signals poor separation of concerns and a violation of the Single Responsibility Principle. The class becomes a gravitational center that attracts new code because adding to it is easier than creating something new.

## Why It's a Problem

Large classes create compounding difficulties:
- They violate the Single Responsibility Principle by bundling unrelated concerns
- Cognitive load spikes when developers try to understand the class as a whole
- Testing becomes complex, fragile, and slow as the class touches many concerns
- Duplication creeps in as developers copy logic elsewhere rather than untangling the class
- Merge conflicts multiply because many developers touch the same file
- Opportunities for simplification hide inside the sheer volume of code

## Signs and Symptoms

- More than 15 public methods (excluding simple accessors)
- The class exceeds 500-1000 lines of code
- Multiple unrelated instance fields with different lifecycles or usage patterns
- Methods that operate on distinct, non-overlapping subsets of the class's fields
- Vague class names like "Manager," "Handler," "Helper," or "Service"
- Locating specific functionality requires searching through the entire class
- The corresponding test class mirrors the production class structure exactly

## Before/After

### Before: Large User Management Class

```php
<?php
declare(strict_types=1);

class UserManager
{
    private string $email;
    private string $password;
    private string $firstName;
    private string $lastName;
    private string $phone;
    private string $address;
    private string $city;
    private string $postalCode;
    private string $country;
    private \DateTime $createdAt;
    private \DateTime $lastLoginAt;
    private array $permissions;
    private array $roles;
    private bool $isActive;

    public function validateEmail(string $email): bool
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }

    public function hashPassword(string $password): string
    {
        return password_hash($password, PASSWORD_BCRYPT);
    }

    public function sendWelcomeEmail(): void
    {
        // Email logic
    }

    public function updateAddress(string $address, string $city): void
    {
        $this->address = $address;
        $this->city = $city;
    }

    public function grantPermission(string $permission): void
    {
        $this->permissions[] = $permission;
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissions);
    }

    // ... 15+ more methods
}
```

### After: Separated Responsibilities

```php
<?php
declare(strict_types=1);

enum UserRole: string
{
    case Admin = 'admin';
    case User = 'user';
    case Guest = 'guest';
}

readonly class UserCredentials
{
    public function __construct(
        public string $email,
        private string $passwordHash,
    ) {}

    public static function create(string $email, string $password): self
    {
        return new self(
            $email,
            password_hash($password, PASSWORD_BCRYPT)
        );
    }

    public function verifyPassword(string $password): bool
    {
        return password_verify($password, $this->passwordHash);
    }

    public function validateEmail(): bool
    {
        return filter_var($this->email, FILTER_VALIDATE_EMAIL) !== false;
    }
}

readonly class UserProfile
{
    public function __construct(
        public string $firstName,
        public string $lastName,
        public string $phone,
    ) {}

    public function getFullName(): string
    {
        return "{$this->firstName} {$this->lastName}";
    }
}

readonly class UserAddress
{
    public function __construct(
        public string $street,
        public string $city,
        public string $postalCode,
        public string $country,
    ) {}

    public function getFormattedAddress(): string
    {
        return "{$this->street}, {$this->city}";
    }
}

class User
{
    public function __construct(
        private int $id,
        private UserCredentials $credentials,
        private UserProfile $profile,
        private UserAddress $address,
        private \DateTime $createdAt,
        private \DateTime $lastLoginAt,
        /** @var list<UserRole> */
        private array $roles,
        /** @var list<string> */
        private array $permissions,
        private bool $isActive,
    ) {}

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissions);
    }
}

class UserEmailService
{
    public function sendWelcomeEmail(UserCredentials $credentials): void
    {
        // Email logic using only credentials
    }
}
```

## Recommended Refactorings

### Extract Class
When part of the class's data and methods naturally group together. Move them to a new class and keep a reference in the original.
- Best for: Separating data models from behavior
- Example: Extract `UserCredentials`, `UserProfile`, `UserAddress` above

### Extract Subclass
When certain behaviors are variations of the main class or used only in specific contexts.
- Best for: Specialized versions of a class
- Example: `AdminUser extends User`

### Extract Interface
Define a contract for operations clients depend on, implementing multiple interfaces.
- Best for: Clarifying responsibilities and enabling polymorphism
- Example: `interface PermissionChecker { public function hasPermission(string $p): bool; }`

### Duplicate Observed Data
For classes managing UI state, separate data (model) from presentation (view).
- Best for: GUI and data synchronization
- Example: Domain model + UI view model

## Exceptions

Large classes are acceptable when:
- **Data Transfer Objects (DTOs)**: Classes primarily holding data with minimal logic are not a smell
- **Enums with Complex Behavior**: Enums in PHP 8.1+ can legitimately have many cases and methods
- **Generated Code**: Code generators often produce large classes; refactor the generator instead
- **Established Patterns**: Some frameworks require large service classes; use composition over inheritance
- **Domain Models**: Rich domain objects may have legitimate complexity; ensure they follow SRP within their domain

## Related Smells

- **God Class**: The extreme form of Large Class - a class that not only does too much but also intimately knows other objects' internals
- **Feature Envy**: Methods inside a large class that primarily use another class's data suggest those methods belong elsewhere
- **Data Clumps**: Groups of related fields that should be extracted together into their own class
- **Middle Man**: After extracting classes, beware of leaving behind shells that only delegate - those become Middle Man
- **Lazy Class**: The inverse problem - classes with too little responsibility that should be merged back

---

**Metrics to Watch**: Classes over 500 LOC, methods over 20, cyclomatic complexity per method > 10

The root cause is almost always the path of least resistance: it is easier to add a method to an existing class than to design a new one. Over time this incremental growth produces classes that no single developer can hold in their head. Splitting a large class into focused components not only improves comprehension but frequently reveals hidden duplication that the sheer size of the original class concealed.

# Large Class Code Smell

A Large Class has accumulated too many fields, methods, or lines of code, and handles responsibilities that belong in separate, focused classes. Growth is normal as a codebase evolves, but unchecked growth violates the Single Responsibility Principle. The class attracts new code because adding to it is easier than creating something new.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- It bundles unrelated concerns, which violates the Single Responsibility Principle.
- Cognitive load spikes when developers try to understand the class as a whole.
- Testing becomes complex, fragile, and slow because the class touches many concerns.
- Duplication creeps in as developers copy logic elsewhere rather than untangle the class.
- Merge conflicts multiply because many developers touch the same file.
- Opportunities for simplification hide inside the volume of code.

## Signs and symptoms

- More than 15 public methods (excluding simple accessors)
- The class exceeds 500-1000 lines of code
- Multiple unrelated instance fields with different lifecycles or usage patterns
- Methods that operate on distinct, non-overlapping subsets of the class's fields
- Vague class names like "Manager," "Handler," "Helper," or "Service"
- Locating specific functionality requires searching through the entire class
- The test class mirrors the production class structure exactly

## Before and after

### Before: large user management class

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

### After: separated responsibilities

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

## Recommended refactorings

### Extract Class

Use when part of the class's data and methods belong together. Move them to a new class and keep a reference in the original.
- Best for: separating data models from behavior
- Example: extract `UserCredentials`, `UserProfile`, `UserAddress` above

### Extract Subclass

Use when certain behaviors are variations of the main class or used only in specific contexts.
- Best for: specialized versions of a class
- Example: `AdminUser extends User`

### Extract Interface

Define a contract for the operations clients depend on, and implement several interfaces where needed.
- Best for: clarifying responsibilities and enabling polymorphism
- Example: `interface PermissionChecker { public function hasPermission(string $p): bool; }`

### Duplicate Observed Data

Use for classes that manage UI state: separate data (model) from presentation (view).
- Best for: GUI and data synchronization
- Example: domain model plus UI view model

## Exceptions

Large classes are acceptable when:
- **Data Transfer Objects (DTOs)**: classes that mostly hold data with minimal logic are not a smell
- **Enums with complex behavior**: enums in PHP 8.1+ can legitimately have many cases and methods
- **Generated code**: code generators often produce large classes, so refactor the generator instead
- **Established patterns**: some frameworks require large service classes, so use composition over inheritance
- **Domain models**: rich domain objects may have legitimate complexity, but they should follow SRP within their domain

## Related smells

- **God Class**: the extreme form of Large Class. It does too much and also knows other objects' internals.
- **Feature Envy**: methods in a large class that mostly use another class's data belong elsewhere.
- **Data Clumps**: groups of related fields that should be extracted together into their own class.
- **Middle Man**: after extracting classes, watch for shells that only delegate.
- **Lazy Class**: the inverse problem. Classes with too little responsibility should be merged back.

---

**Metrics to watch**: classes over 500 LOC, methods over 20, cyclomatic complexity per method above 10.

The root cause is almost always the path of least resistance: it is easier to add a method to an existing class than to design a new one. Over time this produces classes that no one can hold in their head. Splitting a large class makes it easier to understand. It often exposes duplication that the size of the original hid.

# Large Class Code Smell

## Overview

A "Large Class" occurs when a single class contains too many fields, methods, or lines of code, handling multiple responsibilities that should be separated. Classes naturally grow as code evolves, but excessive growth indicates poor separation of concerns and violations of the Single Responsibility Principle (SRP).

## Why It's a Problem

Large classes are difficult to understand, test, and maintain. They:
- Violate the Single Responsibility Principle
- Increase cognitive load when reading and modifying code
- Make testing more complex and fragile
- Encourage code duplication as developers extract functionality elsewhere
- Complicate version control with merge conflicts
- Hide implementation details that could be simplified

## Signs and Symptoms

- Class contains 15+ public methods (excluding getters/setters)
- Class exceeds 500-1000 lines of code
- Multiple unrelated instance fields with different lifecycles
- Methods operate on different subsets of fields
- Class name uses vague terms like "Manager," "Handler," "Helper," or "Service"
- Difficult to find specific functionality without searching the entire class
- Test class mirrors the structure of the large class perfectly

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

- **God Class**: An extreme version of Large Class that knows about other objects' internals
- **Feature Envy**: Methods that use more methods from another class than their own
- **Data Clumps**: Related fields should be extracted together into a class
- **Middle Man**: Too many delegating methods to extracted classes; consider direct access
- **Lazy Class**: Opposite problem—classes with too little responsibility should be eliminated

---

**Metrics to Watch**: Classes over 500 LOC, methods over 20, cyclomatic complexity per method > 10

## Refactoring.guru Guidance

### Signs and Symptoms
A class contains many fields, methods, and lines of code. Classes accumulate functionality over time as programs grow, with developers often preferring to add features to existing classes rather than creating new ones.

### Reasons for the Problem
Classes begin small but expand gradually. Programmers tend to take the path of least resistance by placing new functionality into established classes instead of establishing separate components.

### Treatment
- **Extract Class**: Helps if part of the behavior of the large class can be spun off into a separate component
- **Extract Subclass**: Helps if part of the behavior can be implemented in different ways or is used in rare cases
- **Extract Interface**: Helps if it is necessary to have a list of the operations and behaviors that the client can use
- **Duplicate Observed Data**: Useful when splitting graphical interface classes, requiring data storage in multiple locations

### Payoff
- Developers avoid memorizing extensive class attributes
- Dividing large classes frequently eliminates code duplication and redundant functionality

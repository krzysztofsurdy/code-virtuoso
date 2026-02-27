## Overview

Hide Method is a refactoring technique for restricting the visibility of methods that aren't used by external classes or are only accessed within their own class hierarchy. By making such methods private or protected, you reduce the public surface area of your class and clarify its true interface.

## Motivation

As classes evolve and develop richer interfaces, methods that were once public may become implementation details. Unnecessary public methods expose internal behavior and make it harder to maintain the contract between classes. Hiding these methods:

- Reduces the public API surface, making the class easier to understand
- Protects implementation details from external modification
- Improves the ability to refactor without breaking dependent code
- Clarifies which methods are part of the intended interface

## Mechanics

1. **Identify Hidden Candidates**: Use static code analysis to find methods that:
   - Are not called from outside their defining class or class hierarchy
   - Are not part of implementing an interface or abstract method
   - Are only used internally by the class

2. **Verify with Tests**: Run unit tests to ensure no external dependencies exist

3. **Change Access Modifier**: Change the method visibility from public to private or protected

4. **Re-run Tests**: Ensure all tests pass after the change

## Before/After (PHP 8.3+)

### Before
```php
class UserRepository
{
    public function findByEmail(string $email): ?User
    {
        return $this->validateAndFetch($email);
    }

    // Only used internally, but public
    public function validateAndFetch(string $email): ?User
    {
        $this->validateEmail($email);
        return $this->query('SELECT * FROM users WHERE email = ?', [$email])->first();
    }

    public function validateEmail(string $email): void
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email format');
        }
    }

    private function query(string $sql, array $params = []): Collection
    {
        // Database query logic
        return new Collection();
    }
}

// External usage
$repo = new UserRepository();
$user = $repo->findByEmail('user@example.com');
// $repo->validateAndFetch(); // This shouldn't be called directly
```

### After
```php
class UserRepository
{
    public function findByEmail(string $email): ?User
    {
        return $this->validateAndFetch($email);
    }

    // Now private - implementation detail
    private function validateAndFetch(string $email): ?User
    {
        $this->validateEmail($email);
        return $this->query('SELECT * FROM users WHERE email = ?', [$email])->first();
    }

    private function validateEmail(string $email): void
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email format');
        }
    }

    private function query(string $sql, array $params = []): Collection
    {
        // Database query logic
        return new Collection();
    }
}

// External usage - unchanged and cleaner
$repo = new UserRepository();
$user = $repo->findByEmail('user@example.com');
```

## Benefits

- **Easier Maintenance**: Changes to private methods only require updating the containing class
- **Clearer Contracts**: The public interface explicitly shows what the class is designed to do
- **Reduced Coupling**: External code has fewer hooks into internal implementation
- **Better Encapsulation**: Implementation details stay hidden from consumers
- **Improved IDE Support**: Autocomplete shows only relevant public methods

## When NOT to Use

- **Interface Implementation**: Methods implementing an interface must remain public
- **Template Method Pattern**: Methods meant to be overridden by subclasses should be protected, not private
- **Legacy Code Dependencies**: If external code may depend on the method, use protected as a middle ground
- **Framework Requirements**: Some frameworks require certain method visibility for reflection/proxying

## Related Refactorings

- **Extract Method**: Often used together to create methods that can then be hidden
- **Remove Dead Code**: Eliminates unused methods entirely
- **Encapsulate Field**: Similar principle applied to class fields
- **Move Method**: Transfer a private method to another class if it's more appropriate there

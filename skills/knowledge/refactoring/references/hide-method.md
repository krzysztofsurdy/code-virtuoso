## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Hide Method narrows the visibility of a method that no external class uses. When a method is only an internal detail, making it private or protected shrinks the public surface of the class and shows what the method is for.

## Motivation

As a class evolves, methods that were once public may lose their external callers. Leaving them public exposes implementation details and enlarges the interface that consumers must learn. Restricting visibility:

- Shrinks the public API, so the class is easier to learn and use
- Protects internals from accidental external calls
- Gives you freedom to refactor without breaking dependents
- Makes the intended contract of the class clear

## Mechanics

1. **Find candidates**: Use static analysis or IDE tooling to locate public methods with no external callers that are not part of an interface or abstract contract
2. **Confirm with tests**: Run the test suite to verify no external code relies on the method
3. **Reduce visibility**: Change the access modifier from public to private (or protected if subclasses need it)
4. **Run the tests again**: Confirm everything still passes

## Before and after (PHP 8.3+)

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

- **Simpler maintenance**: Private methods can be renamed or restructured without affecting external code
- **Clear contract**: The public interface shows what the class is designed to do
- **Lower coupling**: Fewer public methods means fewer hooks for external code
- **Stronger encapsulation**: Internal implementation stays hidden from consumers
- **Cleaner autocomplete**: The IDE lists only the methods that matter

## When not to use

- **Interface contracts**: Methods that fulfill an interface or abstract declaration must stay public
- **Template Method pattern**: Override hooks intended for subclasses should be protected, not private
- **External dependencies**: If legacy or third-party code depends on the method, use protected as a transition step
- **Framework requirements**: Some frameworks rely on method visibility for reflection, proxying, or event dispatching

## Related refactorings

- **Extract Method**: Often creates methods that should then be hidden
- **Remove Dead Code**: Goes further and removes methods that have no callers at all
- **Encapsulate Field**: Applies the same visibility rule to class fields
- **Move Method**: Relocates a private method to a class where it fits better

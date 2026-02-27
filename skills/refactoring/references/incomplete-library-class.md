# Incomplete Library Class

## Overview

The Incomplete Library Class smell occurs when an external library lacks features your code needs, but you cannot modify the read-only library to add them. This forces developers to create workarounds or duplicate functionality instead of extending the library seamlessly. The solution depends on the scope of missing features: minor gaps warrant Foreign Methods, while substantial deficiencies require Local Extensions.

## Why It's a Problem

Libraries evolve independently from your application needs. When a library author refuses to implement required features or considers them out-of-scope, you're left with two bad options:
- Duplicate code throughout your application as workarounds
- Create brittle hacks that become maintenance nightmares
- Reduce code reusability and testability

This creates tight coupling to incomplete abstractions and increases long-term maintenance costs.

## Signs and Symptoms

- Calling the same library method followed by redundant logic in multiple places
- Creating utility classes that wrap library classes with missing methods
- Code comments explaining library limitations or workarounds
- Tests that mock or extend library classes to simulate missing functionality
- Reluctance to use library classes because they're "incomplete"

## Before/After Examples

### Before: Workaround Duplication

```php
<?php
declare(strict_types=1);

namespace App\UserManagement;

use ThirdParty\UserRepository;

final readonly class UserService
{
    public function __construct(private UserRepository $repository)
    {
    }

    public function getUsersOrderedByName(): array
    {
        $users = $this->repository->findAll();

        // Workaround: library lacks sorting capability
        usort($users, static fn($a, $b) =>
            strcmp($a->getName(), $b->getName())
        );

        return $users;
    }

    public function getActiveUsersOrderedByName(): array
    {
        $users = $this->repository->findAllActive();

        // Duplicate workaround logic
        usort($users, static fn($a, $b) =>
            strcmp($a->getName(), $b->getName())
        );

        return $users;
    }
}
```

### After: Local Extension

```php
<?php
declare(strict_types=1);

namespace App\UserManagement;

use ThirdParty\UserRepository;

final readonly class SortableUserRepository
{
    public function __construct(private UserRepository $decorated)
    {
    }

    public function findAll(): array
    {
        return $this->sortByName($this->decorated->findAll());
    }

    public function findAllActive(): array
    {
        return $this->sortByName($this->decorated->findAllActive());
    }

    public function findById(int $id): ?object
    {
        return $this->decorated->findById($id);
    }

    private function sortByName(array $users): array
    {
        usort($users, static fn($a, $b) =>
            strcmp($a->getName(), $b->getName())
        );
        return $users;
    }
}
```

## Recommended Refactorings

### 1. Introduce Foreign Method
Use for 1-2 missing methods. Add as static helper methods in your codebase:

```php
<?php
declare(strict_types=1);

final class UserRepositoryExtensions
{
    public static function sortByName(array $users): array
    {
        usort($users, static fn($a, $b) =>
            strcmp($a->getName(), $b->getName())
        );
        return $users;
    }
}

// Usage
$sorted = UserRepositoryExtensions::sortByName($users);
```

### 2. Introduce Local Extension (Decorator Pattern)
Use for substantial missing features. Wrap the library class:

```php
<?php
declare(strict_types=1);

final readonly class EnhancedUserRepository
{
    public function __construct(
        private \ThirdParty\UserRepository $repository
    ) {
    }

    public function findAllSorted(SortOrder $order = SortOrder::NAME): array
    {
        $users = $this->repository->findAll();
        return $this->applySorting($users, $order);
    }

    private function applySorting(array $users, SortOrder $order): array
    {
        return match($order) {
            SortOrder::NAME => $this->sortByName($users),
            SortOrder::DATE => $this->sortByCreatedDate($users),
        };
    }

    private function sortByName(array $users): array
    {
        usort($users, static fn($a, $b) =>
            strcmp($a->getName(), $b->getName())
        );
        return $users;
    }

    private function sortByCreatedDate(array $users): array
    {
        usort($users, static fn($a, $b) =>
            $a->getCreatedAt() <=> $b->getCreatedAt()
        );
        return $users;
    }
}

enum SortOrder
{
    case NAME;
    case DATE;
}
```

## Exceptions

It's acceptable to tolerate incomplete library classes when:
- The missing feature is truly out-of-scope for the library's purpose
- Adding extensions would require understanding library internals deeply
- You only use the library for its core functionality and don't rely on extensions
- Contributing back to the library or switching to a better alternative isn't feasible

## Related Smells

- **Feature Envy**: When your code needs too much data from a class
- **Inappropriate Intimacy**: When extensions require deep library knowledge
- **Data Clumps**: Often combined with workarounds for missing grouping methods
- **Duplicated Code**: The natural result of multiple workarounds

## Refactoring.guru Guidance

### Signs and Symptoms

Sooner or later, libraries stop meeting user needs. The only solution to the problem -- changing the library -- is often impossible since the library is read-only.

### Reasons for the Problem

The author of the library has not provided the features you need, or has refused to implement them.

### Treatment

- **Introduce Foreign Method**: For a few missing methods, add them as utility methods in your own codebase that take the library object as a parameter.
- **Introduce Local Extension**: For substantial missing features, create a wrapper class (decorator) or subclass that adds the needed functionality.

### Payoff

- Reduces code duplication by extending an existing library rather than building a custom replacement from scratch.

### When to Ignore

Extending a library can generate additional work if the library's changes require corresponding updates in your extension code. Consider the long-term cost before committing.

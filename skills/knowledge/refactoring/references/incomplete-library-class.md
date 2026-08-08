# Incomplete Library Class

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after examples](#before-and-after-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

The Incomplete Library Class smell appears when a third-party library lacks functionality your application needs and you cannot change its source. Developers end up scattering workarounds and duplicated logic through the codebase. The fix depends on scale. A few missing methods call for Foreign Methods. Broader gaps justify a Local Extension (wrapper or decorator).

## Why it's a problem

Libraries follow their own roadmap, which may never match your application's needs. When you need something outside the library's scope or timeline, you face trade-offs:

- Workaround logic gets copy-pasted wherever the library is used
- Fragile hacks pile up and get more expensive to maintain
- Reuse and testing suffer because custom logic is scattered instead of centralized

Over time your application becomes tied to an incomplete abstraction, and maintenance costs rise.

## Signs and symptoms

- The same supplemental logic appearing after library calls in multiple places
- Utility classes that exist only to patch missing library methods
- Comments explaining library shortcomings or justifying workarounds
- Tests that mock or extend library classes to simulate absent features
- Developers avoiding certain library classes because they feel "incomplete"

## Before and after examples

### Before: workaround duplication

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

## Recommended refactorings

### 1. Introduce Foreign Method

Use for 1-2 missing methods. Add them as static helper methods in your codebase:

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

### 2. Introduce Local Extension (Decorator pattern)

Use for larger missing features. Wrap the library class:

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

It is reasonable to tolerate an incomplete library class when:

- The missing feature is outside the library's intended scope
- Building extensions would need detailed knowledge of library internals
- You use only the library's core functionality and rarely hit the gap
- Contributing upstream or switching libraries is impractical

An extension is extra code to maintain. When the library updates, your extensions may need changes too. Weigh that cost before you commit to a wrapper or decorator.

## Related smells

- **Feature Envy**: Your code keeps reaching into another class for data it needs
- **Inappropriate Intimacy**: Extensions that need detailed knowledge of library internals
- **Data Clumps**: Workarounds that repeat parameter groups the library does not encapsulate
- **Duplicated Code**: The usual result of scattering the same workaround in several places

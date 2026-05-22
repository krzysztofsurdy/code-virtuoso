# Middle Man

## Overview

The Middle Man smell appears when a class contributes nothing beyond forwarding method calls to another class. It sits between the caller and the actual implementation, adding a layer of indirection without adding any meaningful logic, transformation, or abstraction. The class is effectively an empty relay.

This commonly happens in two ways: as an overcorrection when eliminating Message Chains (hiding too much delegation), or when a class gradually loses its responsibilities to other classes and becomes a hollow shell.

## Why It's a Problem

- **Obscured Logic**: Extra delegation layers hide where work actually happens, making the code harder to trace
- **Cognitive Overhead**: Developers must navigate through intermediary classes to understand real behavior
- **Maintenance Cost**: Any changes to the delegated interface require updating the pass-through class as well
- **Subtle Performance Drag**: Additional method hops add minor overhead
- **No Added Value**: The class exists without contributing unique behavior - it only repeats what another class already provides

## Signs and Symptoms

- A class contains no logic of its own; every public method simply calls through to another object
- The majority of methods are one-line wrappers around a delegate
- The class was introduced to decouple components, but it provides no real abstraction benefit
- Deleting the class and having clients call the delegate directly would change nothing functionally

## Before/After

### Before: Unnecessary Delegation

```php
<?php
declare(strict_types=1);

readonly class PersonRepository
{
    public function __construct(private DatabaseConnection $db) {}

    public function findById(int $id): ?Person
    {
        return $this->db->findById($id);
    }

    public function save(Person $person): void
    {
        $this->db->save($person);
    }

    public function delete(int $id): void
    {
        $this->db->delete($id);
    }
}

// Client code
$repo = new PersonRepository($connection);
$person = $repo->findById(1);
```

### After: Direct Interaction

```php
<?php
declare(strict_types=1);

readonly class PersonDatabaseConnection
{
    public function __construct(private DatabaseConnection $db) {}

    public function findById(int $id): ?Person
    {
        return $this->db->findById($id);
    }

    public function save(Person $person): void
    {
        $this->db->save($person);
    }

    public function delete(int $id): void
    {
        $this->db->delete($id);
    }
}

// Client code - interact directly with the actual implementation
$connection = new PersonDatabaseConnection($db);
$person = $connection->findById(1);
```

## Recommended Refactorings

### Remove Middle Man

Eliminate the intermediary class and have clients interact directly with the actual implementation. This is the primary solution.

```php
<?php
declare(strict_types=1);

interface PersonRepositoryInterface
{
    public function findById(int $id): ?Person;
    public function save(Person $person): void;
    public function delete(int $id): void;
}

readonly class PersonDatabaseConnection implements PersonRepositoryInterface
{
    public function __construct(private DatabaseConnection $db) {}

    public function findById(int $id): ?Person
    {
        return $this->db->findById($id);
    }

    public function save(Person $person): void
    {
        $this->db->save($person);
    }

    public function delete(int $id): void
    {
        $this->db->delete($id);
    }
}

// Client code
$repo = new PersonDatabaseConnection($db);
$person = $repo->findById(1);
```

### Inline Method

If individual methods are delegating, inline them into the client code where appropriate.

## Exceptions

Do **not** remove the middle man class in these scenarios:

- **Design Patterns**: When it implements intentional patterns like Proxy, Decorator, or Adapter that provide architectural benefits
- **Dependency Reduction**: When it genuinely reduces coupling between important components
- **Abstraction Layer**: When it shields clients from implementation complexity or future changes
- **Security/Access Control**: When it enforces permissions or filters access to the wrapped object

## Related Smells

- **Message Chains**: The inverse problem - too many intermediaries in a call chain. Aggressively fixing Message Chains is a common way to accidentally create Middle Man
- **Feature Envy**: A class that leans heavily on another class's methods, suggesting the logic belongs elsewhere
- **Inappropriate Intimacy**: When classes are too tightly coupled to each other's internals

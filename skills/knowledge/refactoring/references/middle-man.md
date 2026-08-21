# Middle Man

The Middle Man smell appears when a class does nothing except forward method calls to another class. It sits between the caller and the real implementation and adds indirection without adding logic, transformation, or abstraction. The class is an empty relay.

It usually arises in one of two ways: as an overcorrection when eliminating Message Chains (hiding too much delegation), or when a class loses its responsibilities to other classes and becomes a hollow shell.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- **Obscured logic**: extra delegation layers hide where work happens, so the code is harder to trace.
- **Cognitive overhead**: developers must step through intermediary classes to understand real behavior.
- **Maintenance cost**: any change to the delegated interface also requires updating the pass-through class.
- **Minor performance cost**: each extra method hop adds a little overhead.
- **No added value**: the class has no unique behavior and only repeats what another class already provides.

## Signs and symptoms

- A class contains no logic of its own, and every public method calls through to another object
- Most methods are one-line wrappers around a delegate
- The class was introduced to decouple components but gives no real abstraction benefit
- Deleting the class and having clients call the delegate directly would change nothing functionally

## Before and after

### Before: unnecessary delegation

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

### After: direct interaction

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

## Recommended refactorings

### Remove Middle Man

Eliminate the intermediary class and have clients talk directly to the real implementation. This is the primary solution.

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

If individual methods only delegate, inline them into the client code where appropriate.

## Exceptions

Do **not** remove the middle man in these cases:

- **Design patterns**: it implements an intentional pattern such as Proxy, Decorator, or Adapter that gives architectural benefits
- **Dependency reduction**: it reduces coupling between important components
- **Abstraction layer**: it shields clients from implementation complexity or future changes
- **Security or access control**: it enforces permissions or filters access to the wrapped object

## Related smells

- **Message Chains**: the inverse problem, too many intermediaries in a call chain. Fixing Message Chains too eagerly is a common way to create a Middle Man by accident.
- **Feature Envy**: a class that leans on another class's methods suggests the logic belongs elsewhere.
- **Inappropriate Intimacy**: classes that are too tightly coupled to each other's internals.

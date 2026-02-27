# Middle Man

## Overview

The Middle Man code smell occurs when a class exists primarily to delegate method calls to another class without adding meaningful functionality. This unnecessary indirection creates extra layers in your code architecture, making it harder to understand and maintain. The intermediary class serves no clear purpose and obscures the actual implementation details.

This smell often emerges as a result of over-correcting Message Chains or when a class's responsibilities gradually migrate elsewhere, leaving behind an empty shell.

## Why It's a Problem

- **Increased Complexity**: Extra layers of delegation obscure the real implementation and make code harder to follow
- **Reduced Clarity**: Developers must trace through multiple classes to understand actual behavior
- **Maintenance Burden**: Changes must be propagated through unnecessary intermediary classes
- **Performance Impact**: Extra method calls add subtle overhead
- **Violates DRY**: The delegating class adds no unique behavior, only repetition

## Signs and Symptoms

- A class has no behavior of its own, only forwarding calls to another class
- Most or all public methods are simple wrappers around another object's methods
- The class exists solely to reduce coupling without providing an abstraction benefit
- Removing the class would not impact functionality, only the call path

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

- **Message Chains**: The opposite problem—too many intermediate objects. Fixing Message Chains sometimes creates Middle Man
- **Feature Envy**: A class that relies too heavily on another class's methods
- **Inappropriate Intimacy**: When a class knows too much about another class's internals

## Refactoring.guru Guidance

### Signs and Symptoms

If a class performs only one action, delegating work to another class, why does it exist at all?

### Reasons for the Problem

- Over-elimination of Message Chains: developers may aggressively refactor chained calls and inadvertently create unnecessary intermediary classes.
- Gradual work migration: over time, a class's functionality moves to other classes, leaving behind an empty shell that merely delegates.

### Treatment

- **Remove Middle Man**: If most of a class's methods delegate to another class, eliminate the intermediary and have clients interact directly with the end object.

### Payoff

- Less bulky code.

### When to Ignore

- Do not delete a middle man that has been created for a reason, such as avoiding interclass dependencies.
- Do not remove classes that serve as intentional Proxy or Decorator patterns where intermediation has a deliberate architectural purpose.

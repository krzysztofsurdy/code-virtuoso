## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after examples](#before-and-after-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Inappropriate Intimacy describes classes that are tangled up with each other's internal details. Instead of talking through public interfaces, one class reaches directly into another's private fields and methods. This tight coupling makes both classes fragile. A change to one can break the other without warning. Neither can be understood, tested, or reused alone.

## Why it's a problem

- **Implementation dependence**: Classes rely on internal details that can change without notice
- **Cascading breakage**: Changing one class's internals can break every class that depends on them
- **No independent reuse**: Intertwined classes cannot be extracted and used in other contexts
- **Complex test setup**: Tests need elaborate mocking to satisfy the cross-class dependencies
- **Broken encapsulation**: Implementation is no longer hidden behind a stable interface

## Signs and symptoms

- One class directly accessing another class's private or internal properties
- A class calling multiple non-public methods of another class
- Bidirectional dependencies where each class references the other
- Internal state shared between classes without a formal public contract
- Using a class requires detailed knowledge of another class's implementation

## Before and after examples

### Problem: direct access to private properties

```php
// BAD: Inappropriate Intimacy
final readonly class UserRepository
{
    public function __construct(private Database $db) {}

    public function save(User $user): void
    {
        $query = $this->db->buildQuery('INSERT INTO users');
        $query->addValue('name', $user->name);
        $query->addValue('email', $user->email); // Accessing public properties
        $this->db->execute($query); // Using private methods indirectly
    }
}

final readonly class User
{
    public string $name;
    public string $email;
    private string $hashedPassword;
}
```

### Solution: use public interface methods

```php
// GOOD: Proper encapsulation
final readonly class User
{
    private function __construct(
        public string $name,
        public string $email,
        private string $hashedPassword,
    ) {}

    public static function create(string $name, string $email, string $password): self
    {
        return new self($name, $email, password_hash($password, PASSWORD_BCRYPT));
    }

    public function toDatabase(): array
    {
        return [
            'name' => $this->name,
            'email' => $this->email,
            'password' => $this->hashedPassword,
        ];
    }
}

final readonly class UserRepository
{
    public function __construct(private Database $db) {}

    public function save(User $user): void
    {
        $this->db->execute(
            'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
            $user->toDatabase(),
        );
    }
}
```

### Problem: bidirectional coupling

```php
// BAD: Order knows too much about Customer
final class Order
{
    public Customer $customer;

    public function calculateDiscount(): float
    {
        return $this->customer->memberSince->diff(new DateTimeImmutable())->y > 5 ? 0.1 : 0;
    }
}

final class Customer
{
    public DateTimeImmutable $memberSince;
    public array $orders = [];
}
```

### Solution: delegate responsibility

```php
// GOOD: Order delegates to Customer
enum MembershipLevel
{
    case NEW;
    case LOYAL;
    case PLATINUM;
}

final readonly class Customer
{
    private function __construct(
        public string $id,
        private DateTimeImmutable $memberSince,
        private array $orders = [],
    ) {}

    public function getMembershipLevel(): MembershipLevel
    {
        $years = $this->memberSince->diff(new DateTimeImmutable())->y;
        return match (true) {
            $years > 10 => MembershipLevel::PLATINUM,
            $years > 5 => MembershipLevel::LOYAL,
            default => MembershipLevel::NEW,
        };
    }

    public function getDiscount(): float
    {
        return match ($this->getMembershipLevel()) {
            MembershipLevel::PLATINUM => 0.15,
            MembershipLevel::LOYAL => 0.1,
            MembershipLevel::NEW => 0.0,
        };
    }
}

final readonly class Order
{
    public function __construct(
        private Customer $customer,
        private float $subtotal,
    ) {}

    public function calculateTotal(): float
    {
        return $this->subtotal * (1 - $this->customer->getDiscount());
    }
}
```

## Recommended refactorings

### 1. Move Method/Field
Move functionality to the class that uses it. If class A frequently accesses a method of class B, consider moving that method to class A.

### 2. Extract Class and Hide Delegate
Create an intermediary class to formalize the relationship. Extract shared functionality into a dedicated class that both original classes interact with.

### 3. Change Association Direction
Convert bidirectional dependencies to unidirectional. Decide which class should own the relationship and remove the reverse dependency.

### 4. Replace Delegation with Inheritance
For a clear parent-child relationship, use inheritance instead of composition to reduce the intimacy.

## Exceptions

Intimacy is acceptable in these cases:

- **Framework integration**: Using framework internals at extension points
- **Close collaborators**: Classes designed as one unit (e.g., value objects with a single repository)
- **Performance-critical code**: Intimacy in tight loops, when profiling shows it is needed
- **Data Transfer Objects**: DTO classes designed to expose all fields are exempt
- **Legacy systems**: Gradual refactoring may require temporary intimacy

## Related smells

- **Feature Envy**: A method that uses more of another class's data than its own. It often appears alongside Inappropriate Intimacy
- **Message Chains**: Traversing returned objects to reach nested data, which creates hidden structural dependencies
- **Middle Man**: A class that exists only to delegate, sometimes introduced as an overcorrection for intimacy
- **Data Clumps**: Groups of variables that travel together and should be encapsulated, which reduces cross-class field access
- **Temporal Coupling**: Methods that must be called in a specific order, where that requirement is hidden in implementation details

Classes should know as little as possible about each other's internals. When you find intimacy, first decide which class should own the shared data or behavior. Then use Move Method, Move Field, or Extract Class to set the boundary. For bidirectional dependencies, decide which direction is needed and remove the other.

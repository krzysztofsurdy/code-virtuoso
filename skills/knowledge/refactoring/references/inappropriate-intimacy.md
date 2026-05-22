## Overview

Inappropriate Intimacy describes classes that are entangled with each other's internal implementation details. Rather than communicating through well-defined public interfaces, one class reaches directly into another's private fields and methods. This tight coupling makes both classes fragile - changes to one can silently break the other, and neither can be understood, tested, or reused in isolation.

## Why It's a Problem

- **Implementation Dependence**: Classes rely on internal details that are free to change without notice
- **Cascading Breakage**: Modifying one class's internals risks breaking every class that depends on those details
- **No Independent Reuse**: Tightly intertwined classes cannot be extracted and used in different contexts
- **Complex Test Setup**: Testing requires elaborate mocking to satisfy intimate cross-class dependencies
- **Encapsulation Erosion**: The fundamental OOP principle of hiding implementation behind a stable interface is undermined

## Signs and Symptoms

- One class directly accessing another class's private or internal properties
- A class calling multiple non-public methods of another class
- Bidirectional dependencies where each class references the other
- Internal state shared between classes without a formal public contract
- Using a class requires deep knowledge of another class's implementation structure

## Before/After Examples

### Problem: Direct Access to Private Properties

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

### Solution: Use Public Interface Methods

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

### Problem: Bidirectional Coupling

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

### Solution: Delegate Responsibility

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

## Recommended Refactorings

### 1. Move Method/Field
Move functionality to the class that actually uses it. If class A frequently accesses a method of class B, consider moving that method to class A.

### 2. Extract Class & Hide Delegate
Create an intermediary class to formalize the relationship. Extract shared functionality into a dedicated class that both original classes interact with.

### 3. Change Association Direction
Convert bidirectional dependencies to unidirectional. Determine which class should own the relationship and remove the reverse dependency.

### 4. Replace Delegation with Inheritance
For clear parent-child relationships, use inheritance instead of composition to reduce unnecessary intimacy.

## Exceptions

Appropriate Intimacy is acceptable in these cases:

- **Framework Integration**: Using framework internals when necessary for extension points
- **Close Collaborators**: Classes designed as a cohesive unit (e.g., value objects with a single repository)
- **Performance Critical Code**: Strategic intimacy in tight loops when profiling proves necessary
- **Data Transfer Objects**: DTO classes designed to expose all fields are exempt
- **Legacy Systems**: Gradual refactoring may require temporary intimacy

## Related Smells

- **Feature Envy**: A method that uses more of another class's data than its own - a frequent companion to Inappropriate Intimacy
- **Message Chains**: Traversing returned objects to reach deeply nested data, creating implicit structural dependencies
- **Middle Man**: A class that exists solely to delegate, sometimes introduced as an overcorrection for intimacy
- **Data Clumps**: Groups of variables that travel together and should be encapsulated, reducing the need for cross-class field access
- **Temporal Coupling**: Methods that must be called in a specific order, with that requirement hidden inside implementation details

The guiding principle is that well-designed classes should know as little as possible about each other's internals. When intimacy is detected, the first step is deciding which class should own the shared data or behavior, then using Move Method, Move Field, or Extract Class to establish proper boundaries. For bidirectional dependencies, determine which direction is essential and convert the other to unidirectional.

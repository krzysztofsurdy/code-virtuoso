## Overview

Inappropriate Intimacy occurs when one class uses the internal fields and methods of another class, violating encapsulation principles. Classes become tightly coupled through direct access to private implementation details rather than communicating through public interfaces. This makes code harder to maintain, test, and reuse.

## Why It's a Problem

- **Tight Coupling**: Classes depend on implementation details that may change
- **Maintenance Burden**: Modifying one class risks breaking others that depend on its internals
- **Reduced Reusability**: Coupled classes cannot be used independently in other contexts
- **Testing Difficulty**: Tightly coupled code requires more complex test setup and mocking
- **Violation of Encapsulation**: Breaks the fundamental object-oriented principle of hiding implementation

## Signs and Symptoms

- Classes directly accessing private properties of other classes
- One class calling multiple private methods of another class
- Bidirectional dependencies between classes
- Classes sharing internal state without a clear public interface
- Need for detailed knowledge of another class's internal structure to use it

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

- **Feature Envy**: One method uses more features of another class than its own
- **Message Chains**: Objects call methods on returned objects, creating dependency chains
- **Middle Man**: A class exists only to delegate to another class
- **Data Clumps**: Groups of variables that should be encapsulated together
- **Temporal Coupling**: Methods must be called in a specific order, hidden in implementation details

## Refactoring.guru Guidance

### Signs and Symptoms

One class uses the internal fields and methods of another class.

### Reasons for the Problem

Classes become overly dependent on each other's implementation details. Good classes should know as little about each other as possible. Such tightly coupled classes are harder to maintain, test, and reuse.

### Treatment

- **Move Method** and **Move Field**: Move parts of one class to the class where they are actually used, if the originating class truly does not need them.
- **Extract Class** and **Hide Delegate**: Create proper boundaries and delegation patterns to formalize the relationship.
- **Change Bidirectional Association to Unidirectional**: Reduce mutual interdependency by establishing a clear directional flow.
- **Replace Delegation with Inheritance**: If appropriate for a subclass-superclass relationship.

### Payoff

- Improved code organization and separation of concerns.
- Simplified maintenance and improved code reuse.

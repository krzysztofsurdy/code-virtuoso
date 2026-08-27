---
name: solid
description: SOLID principles for object-oriented design with multi-language examples (PHP, Java, Python, TypeScript, C++). Use when the user asks to review SOLID compliance, fix a SOLID violation, evaluate class design, reduce coupling, improve extensibility, or apply Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, or Dependency Inversion principles. Covers motivation, violation detection, refactoring fixes, and real-world trade-offs for each principle.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# SOLID Principles

Five core principles of object-oriented design that make systems simpler to maintain, test, and extend. Robert C. Martin (Uncle Bob) formalized these ideas, and Michael Feathers coined the SOLID acronym.

## Principle index

| Principle | Summary | Reference |
|---|---|---|
| **S**: Single Responsibility | A class should have only one reason to change | [reference](references/srp.md) |
| **O**: Open/Closed | Open for extension, closed for modification | [reference](references/ocp.md) |
| **L**: Liskov Substitution | Subtypes must be substitutable for their base types | [reference](references/lsp.md) |
| **I**: Interface Segregation | Prefer many specific interfaces over one general-purpose interface | [reference](references/isp.md) |
| **D**: Dependency Inversion | Depend on abstractions, not concretions | [reference](references/dip.md) |

## Why SOLID matters

Without SOLID, codebases gradually develop these problems:

- **Rigidity**: one change ripples through many unrelated modules
- **Fragility**: modifying one area breaks another, seemingly unconnected area
- **Immobility**: components are so intertwined that extracting them for reuse is impractical
- **Viscosity**: doing things correctly is harder than hacking around the design

SOLID addresses each of these with clear boundaries, explicit contracts, and defined points for extension.

## Quick decision guide

| Symptom | Likely violated principle | Fix |
|---|---|---|
| Class does too many things | **SRP** | Split into focused classes |
| Adding a feature requires editing existing classes | **OCP** | Introduce polymorphism or strategy |
| Subclass breaks when used in place of parent | **LSP** | Fix inheritance hierarchy or use composition |
| Classes forced to implement unused methods | **ISP** | Break interface into smaller ones |
| High-level module imports low-level details | **DIP** | Introduce an abstraction layer |

## Quick examples

### SRP: before and after

```php
// BEFORE: Class handles both user data AND email sending
class UserService {
    public function createUser(string $name, string $email): void { /* ... */ }
    public function sendWelcomeEmail(string $email): void { /* ... */ }
}

// AFTER: Each class has one responsibility
class UserService {
    public function __construct(private UserNotifier $notifier) {}
    public function createUser(string $name, string $email): void {
        // persist user...
        $this->notifier->welcomeNewUser($email);
    }
}

class UserNotifier {
    public function welcomeNewUser(string $email): void { /* ... */ }
}
```

### OCP: extend without modifying

```php
interface DiscountPolicy {
    public function calculate(float $total): float;
}

class PercentageDiscount implements DiscountPolicy {
    public function __construct(private float $rate) {}
    public function calculate(float $total): float {
        return $total * $this->rate;
    }
}

// Adding a new discount type requires NO changes to existing code
class FlatDiscount implements DiscountPolicy {
    public function __construct(private float $amount) {}
    public function calculate(float $total): float {
        return min($this->amount, $total);
    }
}
```

### DIP: depend on abstractions

```php
// High-level policy depends on abstraction, not on database details
interface OrderRepository {
    public function save(Order $order): void;
}

class PlaceOrderHandler {
    public function __construct(private OrderRepository $repository) {}
    public function handle(PlaceOrderCommand $cmd): void {
        $order = Order::create($cmd->items);
        $this->repository->save($order);
    }
}
```

## Relationships between principles

The five principles reinforce one another:

- **SRP + ISP**: Both narrow a class or interface to a single concern
- **OCP + DIP**: Abstractions are what make extension without modification possible
- **LSP + OCP**: Polymorphic extension only works if subtypes are correctly substitutable
- **ISP + DIP**: Well-segregated interfaces make it easier to depend on exactly the right abstraction

## Common misconceptions

- **"One method per class"**: SRP means one *reason to change*, not one method. A class can have many methods as long as they serve the same responsibility.
- **"Never modify existing code"**: OCP does not prohibit bug fixes. It means *new behavior* should be addable without changing existing working code.
- **"Always use interfaces"**: DIP calls for depending on abstractions. Sometimes a base class is the right abstraction. Do not create interfaces for classes that will never have a second implementation.
- **"Inheritance is bad"**: LSP does not discourage inheritance. It sets rules for *correct* inheritance so that subtypes stay substitutable.

## Best practices

- Adopt SOLID incrementally. Do not refactor everything in one pass
- Treat SOLID as a diagnostic tool: when code resists change, check which principle is being violated
- Pair with design patterns: Strategy (OCP), Adapter (DIP), and Decorator (OCP) are direct implementations of SOLID ideas
- Write tests first. TDD steers designs toward SOLID compliance
- Target PHP 8.3+ with strict typing, readonly classes, and enums

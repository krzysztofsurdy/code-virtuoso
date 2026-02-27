---
name: solid
description: SOLID principles for object-oriented design — Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion. Covers motivation, violations, fixes, and multi-language examples (PHP, Java, Python, TypeScript, C++) for building maintainable, extensible software.
---

# SOLID Principles

Five foundational principles of object-oriented design that produce systems which are easier to maintain, test, and extend. Introduced by Robert C. Martin (Uncle Bob), the acronym was coined by Michael Feathers.

## Principle Index

| Principle | Summary | Reference |
|---|---|---|
| **S** — Single Responsibility | A class should have only one reason to change | [reference](references/srp.md) |
| **O** — Open/Closed | Open for extension, closed for modification | [reference](references/ocp.md) |
| **L** — Liskov Substitution | Subtypes must be substitutable for their base types | [reference](references/lsp.md) |
| **I** — Interface Segregation | Prefer many specific interfaces over one general-purpose interface | [reference](references/isp.md) |
| **D** — Dependency Inversion | Depend on abstractions, not concretions | [reference](references/dip.md) |

## Why SOLID Matters

Without SOLID, codebases develop these symptoms over time:

- **Rigidity** — a single change cascades through many unrelated modules
- **Fragility** — touching one area breaks another seemingly unrelated area
- **Immobility** — components are so entangled they can't be reused elsewhere
- **Viscosity** — doing things the right way is harder than hacking around the design

SOLID addresses each of these by establishing clear boundaries, explicit contracts, and flexible extension points.

## Quick Decision Guide

| Symptom | Likely Violated Principle | Fix |
|---|---|---|
| Class does too many things | **SRP** | Split into focused classes |
| Adding a feature requires editing existing classes | **OCP** | Introduce polymorphism or strategy |
| Subclass breaks when used in place of parent | **LSP** | Fix inheritance hierarchy or use composition |
| Classes forced to implement unused methods | **ISP** | Break interface into smaller ones |
| High-level module imports low-level details | **DIP** | Introduce an abstraction layer |

## Quick Examples

### SRP — Before and After

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

### OCP — Extend Without Modifying

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

### DIP — Depend on Abstractions

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

## Relationships Between Principles

The five principles reinforce each other:

- **SRP + ISP**: Both reduce the surface area of a class/interface to a focused concern
- **OCP + DIP**: Abstractions enable extension without modification
- **LSP + OCP**: Correct substitutability is required for polymorphic extension
- **ISP + DIP**: Segregated interfaces make it easier to depend on the right abstraction

## Common Misconceptions

- **"One method per class"** — SRP means one *reason to change*, not one method. A class can have many methods if they all serve the same responsibility.
- **"Never modify existing code"** — OCP doesn't forbid bug fixes. It means *new behavior* should be addable without changing existing working code.
- **"Always use interfaces"** — DIP says depend on abstractions. Sometimes a well-designed base class is the right abstraction. Don't create interfaces for classes that will never have a second implementation.
- **"Inheritance is bad"** — LSP doesn't discourage inheritance. It sets rules for *correct* inheritance so subtypes remain substitutable.

## Best Practices

- Apply SOLID gradually — don't refactor everything at once
- Use SOLID as a diagnostic tool: when code is hard to change, check which principle is violated
- Combine with design patterns — Strategy (OCP), Adapter (DIP), and Decorator (OCP) directly implement SOLID
- Write tests first — TDD naturally drives toward SOLID designs
- Target PHP 8.3+ with strict typing, readonly classes, and enums

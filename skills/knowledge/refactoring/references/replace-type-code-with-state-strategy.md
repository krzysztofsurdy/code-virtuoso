## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before code (PHP 8.3)](#before-code-php-83)
- [After code (PHP 8.3 with State pattern)](#after-code-php-83-with-state-pattern)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Replace Type Code with State/Strategy removes conditional logic driven by a type code by moving each type's behavior into its own class. Use it for objects whose behavior depends on a type or state that can change during the object's lifetime.

## Motivation

Legacy code often controls behavior through a type code checked in switch statements or if-else chains. This causes several problems:

- **Duplicate code**: behavior logic is scattered through the codebase.
- **Hard to extend**: adding a type means modifying multiple locations.
- **Poor encapsulation**: type-dependent behavior lives outside the types.
- **Difficult testing**: testing one behavior requires complex setup.
- **Single Responsibility violation**: one class handles the logic of every type.

State or Strategy classes take over that behavior, so each type can be changed and extended in one place.

## Mechanics

1. **Identify the type code**: find the field that controls behavior.
2. **Create an interface or abstract class**: define the common interface for all behaviors.
3. **Create concrete classes**: implement each type's behavior in its own class.
4. **Replace conditionals**: delegate to the polymorphic objects instead of switch statements.
5. **Move type-specific methods**: move behavior methods from the original class to the type classes.
6. **Remove the type code**: delete or encapsulate the type code field.

## Before code (PHP 8.3)

```php
class Order
{
    private string $status; // 'pending', 'shipped', 'delivered'

    public function __construct(string $status = 'pending')
    {
        $this->status = $status;
    }

    public function ship(): void
    {
        if ($this->status === 'pending') {
            $this->status = 'shipped';
        } else if ($this->status === 'shipped') {
            throw new Exception('Already shipped');
        }
    }

    public function deliver(): void
    {
        if ($this->status === 'shipped') {
            $this->status = 'delivered';
        } else {
            throw new Exception('Cannot deliver in current status');
        }
    }

    public function getPrice(): float
    {
        return match($this->status) {
            'pending' => 100.0,
            'shipped' => 105.0,
            'delivered' => 105.0,
            default => throw new Exception('Unknown status')
        };
    }
}
```

## After code (PHP 8.3 with State pattern)

```php
// State interface
interface OrderState
{
    public function ship(Order $order): void;
    public function deliver(Order $order): void;
    public function getPrice(): float;
}

// Concrete states
class PendingState implements OrderState
{
    public function ship(Order $order): void
    {
        $order->setState(new ShippedState());
    }

    public function deliver(Order $order): void
    {
        throw new Exception('Cannot deliver pending order');
    }

    public function getPrice(): float
    {
        return 100.0;
    }
}

class ShippedState implements OrderState
{
    public function ship(Order $order): void
    {
        throw new Exception('Already shipped');
    }

    public function deliver(Order $order): void
    {
        $order->setState(new DeliveredState());
    }

    public function getPrice(): float
    {
        return 105.0;
    }
}

class DeliveredState implements OrderState
{
    public function ship(Order $order): void
    {
        throw new Exception('Cannot ship delivered order');
    }

    public function deliver(Order $order): void
    {
        throw new Exception('Already delivered');
    }

    public function getPrice(): float
    {
        return 105.0;
    }
}

// Refactored Order class
class Order
{
    private OrderState $state;

    public function __construct()
    {
        $this->state = new PendingState();
    }

    public function setState(OrderState $state): void
    {
        $this->state = $state;
    }

    public function ship(): void
    {
        $this->state->ship($this);
    }

    public function deliver(): void
    {
        $this->state->deliver($this);
    }

    public function getPrice(): float
    {
        return $this->state->getPrice();
    }
}

// Usage
$order = new Order();
$order->ship();      // Pending → Shipped
$order->deliver();   // Shipped → Delivered
echo $order->getPrice(); // 105.0
```

## Benefits

- **Cleaner code**: switch statements and complex conditionals disappear.
- **Easier to extend**: adding a type means adding a class.
- **Better encapsulation**: type-specific logic lives in separate classes.
- **Testability**: each state can be tested independently.
- **Open/Closed Principle**: open for extension, closed for modification.
- **Explicit transitions**: state changes are visible in the code.
- **Less duplication**: common behavior can be shared through inheritance.

## When not to use

- **Simple type codes**: for 2-3 simple types with minimal behavior, the overhead may not be justified.
- **Read-only type codes**: if the type never changes, use constants or enums instead.
- **Performance-critical code**: polymorphic dispatch adds minimal overhead, but it may matter in tight loops.
- **Temporary code**: if the code will be refactored soon anyway, defer this refactoring.

## Related refactorings

- **Replace Type Code with Subclasses**: for types that do not change after construction.
- **Replace Type Code with Enum**: for simple type codes without complex behavior.
- **Replace Conditional with Polymorphism**: the general technique for eliminating conditionals.
- **State pattern**: the design pattern behind this refactoring.
- **Strategy pattern**: an alternative for interchangeable algorithms.

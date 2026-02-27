## Overview

Replace Type Code with State/Strategy is a refactoring technique that eliminates conditional logic based on type codes by replacing them with polymorphic classes. This pattern provides a cleaner, more maintainable way to handle objects that exhibit different behavior based on their type or state.

## Motivation

Type codes are often used in legacy code to control an object's behavior through switch statements or if-else chains. This approach has several drawbacks:

- **Duplicate code**: Behavior logic is scattered throughout the codebase
- **Hard to extend**: Adding new types requires modifying multiple locations
- **Poor encapsulation**: Type-dependent behavior isn't properly encapsulated
- **Difficult testing**: Testing individual behaviors requires complex setup
- **Violates Single Responsibility Principle**: Classes handle multiple types' logic

Using State or Strategy patterns delegates behavior to separate classes, making the code more maintainable and extensible.

## Mechanics

### Basic Steps

1. **Identify the type code**: Find the field that controls behavior
2. **Create interface/abstract class**: Define a common interface for all behaviors
3. **Create concrete classes**: Implement each type's behavior in separate classes
4. **Replace conditionals**: Delegate to polymorphic objects instead of switch statements
5. **Move type-specific methods**: Move behavior methods from the original class to type classes
6. **Remove type code**: Delete or encapsulate the type code field

## Before Code (PHP 8.3)

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

## After Code (PHP 8.3 with State Pattern)

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

- **Cleaner code**: Eliminates switch statements and complex conditionals
- **Easier to extend**: Adding new types only requires creating a new class
- **Better encapsulation**: Type-specific logic is encapsulated in separate classes
- **Improved testability**: Each state can be tested independently
- **Follows Open/Closed Principle**: Open for extension, closed for modification
- **State transitions are explicit**: State changes are clearly visible in the code
- **Reduced duplication**: Common behavior can be shared through inheritance

## When NOT to Use

- **Simple type codes**: For 2-3 simple types with minimal behavior, the refactoring overhead may not be justified
- **Read-only type codes**: If the type never changes, consider using constants or enums instead
- **Performance-critical code**: The polymorphic dispatch adds minimal overhead but may matter in tight loops
- **Temporary code**: If the code will be refactored soon anyway, defer this refactoring

## Related Refactorings

- **Replace Type Code with Subclasses**: When types are immutable
- **Replace Type Code with Enum**: For simple type codes without complex behavior
- **Replace Conditional with Polymorphism**: General pattern for eliminating conditionals
- **State Pattern**: The design pattern foundation for this refactoring
- **Strategy Pattern**: Alternative pattern for interchangeable algorithms

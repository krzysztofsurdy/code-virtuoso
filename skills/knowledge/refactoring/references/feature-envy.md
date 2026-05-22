## Overview

Feature Envy describes a method that reaches into another object's data far more than it uses its own. The method is effectively doing work that belongs to the other class - it is "envious" of that class's fields and methods. This violates encapsulation and is a strong signal that the logic should live closer to the data it operates on.

## Why It's a Problem

Feature Envy introduces several compounding issues:

- **Tight Coupling**: The method becomes deeply dependent on another class's internal layout, making both classes resistant to change
- **Scattered Cohesion**: Data and the behavior that acts on it end up in different classes, weakening the conceptual integrity of both
- **Ripple Effects**: Structural changes to the data-holding class force updates in every envious method across the codebase
- **Poor Reusability**: Code tangled with another object's internals is difficult to extract and reuse in other contexts
- **Testing Friction**: Envious methods require elaborate setup to satisfy external dependencies, making unit tests harder to write and maintain

## Signs and Symptoms

- A method makes multiple getter calls on a single external object
- The method references another object's fields more often than its own class's fields
- Logic in the method is primarily concerned with data belonging to a different class
- The same conditions on another object are checked repeatedly across methods
- Helper methods exist mainly to reach into another object's state

## Before and After

### Before: Feature Envy

```php
<?php
declare(strict_types=1);

readonly class OrderProcessor
{
    public function calculateShipping(Order $order): float
    {
        $weight = $order->getWeight();
        $distance = $order->getDeliveryAddress()->getDistance();
        $zone = $order->getDeliveryAddress()->getZone();

        $baseRate = match($zone) {
            'domestic' => 5.0,
            'regional' => 10.0,
            'international' => 25.0,
        };

        return ($weight * 0.5) + ($distance * 0.1) + $baseRate;
    }
}

class Order
{
    public function __construct(
        private Address $deliveryAddress,
        private float $weight,
    ) {}

    public function getWeight(): float { return $this->weight; }
    public function getDeliveryAddress(): Address { return $this->deliveryAddress; }
}

class Address
{
    public function __construct(
        private string $zone,
        private float $distance,
    ) {}

    public function getZone(): string { return $this->zone; }
    public function getDistance(): float { return $this->distance; }
}
```

### After: Proper Encapsulation

```php
<?php
declare(strict_types=1);

enum ShippingZone: string
{
    case DOMESTIC = 'domestic';
    case REGIONAL = 'regional';
    case INTERNATIONAL = 'international';
}

readonly class Address
{
    public function __construct(
        private ShippingZone $zone,
        private float $distance,
    ) {}

    public function calculateShippingCost(float $weight): float
    {
        $baseRate = match($this->zone) {
            ShippingZone::DOMESTIC => 5.0,
            ShippingZone::REGIONAL => 10.0,
            ShippingZone::INTERNATIONAL => 25.0,
        };

        return ($weight * 0.5) + ($this->distance * 0.1) + $baseRate;
    }
}

readonly class Order
{
    public function __construct(
        private Address $deliveryAddress,
        private float $weight,
    ) {}

    public function calculateShipping(): float
    {
        return $this->deliveryAddress->calculateShippingCost($this->weight);
    }

    public function getWeight(): float { return $this->weight; }
}
```

## Recommended Refactorings

### 1. Move Method
Move the entire method to the class whose data it primarily uses. The refactored code above demonstrates this: shipping cost calculation moves from `OrderProcessor` to `Address` where the zone and distance data reside.

**When to use**: The method operates mainly on one class's data, with minimal interaction with its current class.

### 2. Extract Method & Move
Extract the portion of code that accesses another object's data into a separate method, then move it to that object's class.

```php
// Extract to Address class
private function getBaseRate(): float
{
    return match($this->zone) {
        ShippingZone::DOMESTIC => 5.0,
        ShippingZone::REGIONAL => 10.0,
        ShippingZone::INTERNATIONAL => 25.0,
    };
}
```

**When to use**: Only part of the method exhibits feature envy, and the rest needs to remain in the original class.

### 3. Delegate Method
Create a delegation method in the data-holder class and call it instead of accessing data directly.

```php
readonly class Order
{
    public function getShippingCost(): float
    {
        return $this->deliveryAddress->calculateShippingCost($this->weight);
    }
}
```

## Exceptions

Feature Envy is sometimes acceptable:

- **Utility/Helper Classes**: Methods in utility classes or data mappers may naturally access other objects' data without being "envious"
- **Value Objects**: Operations on multiple value objects (like distance calculations) are legitimate
- **DTOs in Data Transfer**: Data Transfer Objects intentionally expose all data for transfer purposes
- **Framework Code**: ORM/framework code deliberately accesses object internals

## Related Smells

- **Inappropriate Intimacy**: Classes that dig into each other's private implementation details - a broader form of the same coupling issue
- **Message Chains**: Traversing a chain of method calls (like `object->a()->b()->c()`) is often a symptom of envy for data buried deep in the object graph
- **Lazy Class**: An object that does very little itself and mostly delegates, pushing logic outward where it becomes envious
- **Anemic Domain Model**: Domain objects that hold data but no behavior, forcing all logic into service classes that are inherently envious

A useful rule of thumb: if things change together, keep them together. When a method uses data from several classes, determine which class owns the majority of that data and place the method there. The exception is when behavior is intentionally kept separate to enable runtime flexibility - patterns like Strategy and Visitor deliberately separate behavior from data.

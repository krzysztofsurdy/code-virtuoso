## Overview

Feature Envy occurs when a method accesses the data of another object more than its own data. This code smell represents a coupling problem where methods show more interest in another class's internal state than in their own object's data. It violates the principle of encapsulation and indicates that logic should be relocated closer to the data it manipulates.

## Why It's a Problem

Feature Envy creates several critical issues:

- **Tight Coupling**: Methods depend heavily on another class's internal structure, making refactoring risky
- **Low Cohesion**: Related data and behavior become scattered across multiple classes
- **Maintenance Burden**: Changes to one class's structure require updates in multiple locations
- **Reduced Reusability**: Tightly coupled code is harder to reuse in different contexts
- **Testing Complexity**: Methods become harder to test in isolation due to external dependencies

## Signs and Symptoms

- A method calls multiple getters on another object
- The method accesses another object's fields more frequently than its own
- A method works more with another class's data than the class containing the method
- You find yourself checking the same conditions on another object repeatedly
- Helper methods exist primarily to access another object's state

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

- **Inappropriate Intimacy**: When classes know too much about each other's private implementation
- **Message Chains**: Calling multiple methods in sequence (like `object->method1()->method2()`) is often a symptom
- **Lazy Class**: When an object doesn't do much and mostly delegates to others
- **Anemic Domain Model**: Domain objects lack behavior, forcing logic into service classes

## Refactoring.guru Guidance

### Signs and Symptoms

A method accesses the data of another object more than its own data.

### Reasons for the Problem

This smell may occur after fields are moved to a data class. If so, the operations on that data should be moved to the data class as well.

### Treatment

- **Move Method**: As a rule, if things change at the same time, keep them in the same place. Move the method to the class whose data it primarily uses.
- **Extract Method**: If only a part of a method accesses another object's data, extract that part into its own method and move it.
- When a method uses functions from several other classes, determine which class contains most of the data used and place the method there.

### Payoff

- Less code duplication (if the data-handling code is consolidated in a central location).
- Better code organization (methods are next to the data they use).

### When to Ignore

Sometimes behavior is intentionally kept separate from the class that holds the data. The usual advantage of this is the ability to dynamically change the behavior (see Strategy, Visitor, and other patterns).

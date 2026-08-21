# Primitive Obsession

## Overview

Primitive Obsession is the habit of using basic data types (strings, integers, floats, arrays) to represent domain concepts that deserve their own objects. You pass a raw string instead of an `Email` class with validation. You pass a float and a currency string separately instead of a `Money` value object. The result is logic scattered across the codebase, domain rules enforced inconsistently or not at all, and code that does not express the business vocabulary.

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- **Fragmented logic**: data and the operations that belong to it are spread across several classes.
- **No built-in validation**: primitives accept any value. A string meant to hold an email accepts "not-an-email".
- **Weak type safety**: the compiler and IDE cannot tell apart two strings that represent different concepts.
- **Obscured meaning**: magic numbers and string constants hide business intent behind opaque values.
- **Repeated validation**: the same constraints are checked in several places, and one gets updated while the others do not.
- **Costly extensions**: adding behavior for a domain concept means finding every place that handles the primitive.

## Signs and symptoms

- Integers standing in for enumerated values (roles, statuses, permission levels)
- Several related primitives passed as separate parameters (amount and currency, latitude and longitude)
- String constants used as keys in associative arrays to simulate object fields
- Magic numbers embedded in business logic
- The same validation logic duplicated across functions or classes
- Comments explaining what a primitive value represents
- Parameters named `$status`, `$type`, or `$role` that accept any string

## Before and after

### Before: Primitive Obsession

```php
class Order
{
    public function __construct(
        private int $id,
        private string $customerEmail,
        private string $status,  // "pending", "processing", "shipped"
        private float $amount,
        private string $currency,  // "USD", "EUR", "GBP"
    ) {}

    public function ship(): void
    {
        if ($this->status !== "processing") {
            throw new \Exception("Order must be processing to ship");
        }
        $this->status = "shipped";
        // Send email with raw strings
        $this->sendNotification($this->customerEmail, $this->status);
    }

    private function sendNotification(string $email, string $status): void
    {
        $message = match($status) {
            "pending" => "Your order is pending",
            "shipped" => "Your order has shipped",
            default => "Unknown status"
        };
    }
}
```

### After: meaningful objects

```php
enum OrderStatus: string
{
    case Pending = "pending";
    case Processing = "processing";
    case Shipped = "shipped";
    case Cancelled = "cancelled";
}

enum Currency: string
{
    case USD = "USD";
    case EUR = "EUR";
    case GBP = "GBP";
}

readonly class Money
{
    public function __construct(
        private float $amount,
        private Currency $currency,
    ) {
        if ($amount < 0) {
            throw new \InvalidArgumentException("Amount cannot be negative");
        }
    }

    public function amount(): float
    {
        return $this->amount;
    }

    public function currency(): Currency
    {
        return $this->currency;
    }
}

readonly class Email
{
    public function __construct(private string $address)
    {
        if (!filter_var($address, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email address");
        }
    }

    public function address(): string
    {
        return $this->address;
    }
}

class Order
{
    public function __construct(
        private int $id,
        private Email $customerEmail,
        private OrderStatus $status,
        private Money $totalAmount,
    ) {}

    public function ship(): void
    {
        if ($this->status !== OrderStatus::Processing) {
            throw new \LogicException("Order must be processing to ship");
        }
        $this->status = OrderStatus::Shipped;
        $this->sendNotification();
    }

    private function sendNotification(): void
    {
        $message = match($this->status) {
            OrderStatus::Pending => "Your order is pending",
            OrderStatus::Shipped => "Your order has shipped",
            OrderStatus::Processing => "Processing your order",
            OrderStatus::Cancelled => "Order cancelled",
        };
        // Type-safe email notification
    }
}
```

## Recommended refactorings

### 1. Replace Primitive with Enum

Convert magic numbers and strings to typed enums for fixed sets of values:
- Use `enum` for status codes, types, and permissions
- Gives IDE autocomplete and type checking
- PHP 8.1+ feature, with backed or pure enums

### 2. Extract Value Object

Wrap primitives in small, immutable objects that validate their input:
- `Money`, `Email`, `PhoneNumber`, `UserId`
- Keep validation logic inside the object
- Use `readonly` classes for immutability (PHP 8.2+)

### 3. Introduce Parameter Object

Group related primitive parameters into a data object:
- Reduces the parameter count in methods
- Makes relationships explicit
- Makes it easier to add related data later

### 4. Replace Array with Object

Replace associative arrays with typed objects:
- Better type hints and autocomplete
- Self-documenting properties
- Validation at construction time

## Exceptions

Primitive Obsession is acceptable when:
- You work with configuration arrays or DTOs that are generic by nature
- You pass simple data through frameworks with type constraints
- You write simple, throwaway scripts
- You handle performance-critical numeric arrays (rare)
- You interact with external APIs that require primitive payloads

## Related smells

- **Data Clumps**: groups of primitives that always appear together. The next step from Primitive Obsession is to bundle them into an object.
- **Magic Numbers**: unexplained numeric literals in logic. Value objects or enums remove them.
- **Duplicate Code**: the same validation and constraint checks scattered across the codebase because no central type enforces them.
- **Feature Envy**: classes reaching into other objects to manipulate primitive fields. The pattern disappears when those fields become objects.

The root cause is usually pragmatic: adding a primitive field is faster than adding a class. The shortcut costs more over time. Small objects improve type safety and keep validation in one place. They also make duplicate code easier to spot, because the logic now lives in one place.

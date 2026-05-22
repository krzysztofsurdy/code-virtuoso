# Primitive Obsession

## Overview

Primitive Obsession is the habit of using basic data types - strings, integers, floats, arrays - to represent domain concepts that deserve their own objects. Instead of an `Email` class with validation, you pass a raw string. Instead of a `Money` value object, you pass a float and a currency string separately. The result is logic scattered across the codebase, domain rules that are enforced inconsistently (or not at all), and code that fails to express the actual business vocabulary.

## Why It's a Problem

- **Fragmented Logic**: Data and the operations that belong to it are spread across multiple classes instead of living together
- **No Built-In Validation**: Primitives accept any value - a string meant to hold an email will happily accept "not-an-email"
- **Weak Type Safety**: The compiler and IDE cannot distinguish between two strings that represent fundamentally different concepts
- **Obscured Meaning**: Magic numbers and string constants hide business intent behind opaque values
- **Repeated Validation**: The same constraints are checked in multiple places, leading to inconsistencies when one is updated and others are not
- **Expensive Extensions**: Adding behavior related to a domain concept requires hunting down every location that manipulates the primitive

## Signs and Symptoms

- Integers standing in for enumerated values (roles, statuses, permission levels)
- Multiple related primitives passed as separate parameters (amount + currency, latitude + longitude)
- String constants used as keys in associative arrays to simulate object fields
- Magic numbers embedded directly in business logic
- The same validation logic duplicated across different functions or classes
- Comments explaining what a primitive value actually represents
- Parameters named `$status`, `$type`, or `$role` that accept any arbitrary string

## Before/After

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

### After: Using Meaningful Objects

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

## Recommended Refactorings

### 1. Replace Primitive with Enum
Convert magic numbers/strings to strongly-typed enums for fixed sets of values:
- Use `enum` for status codes, types, permissions
- Provides IDE autocomplete and type checking
- PHP 8.1+ feature with backed or pure enums

### 2. Extract Value Object
Create small, immutable objects wrapping primitives with validation:
- `Money`, `Email`, `PhoneNumber`, `UserId`
- Encapsulate validation logic
- Use `readonly` classes for immutability (PHP 8.2+)

### 3. Introduce Parameter Object
Group related primitive parameters into a data object:
- Reduces parameter count in methods
- Makes relationships explicit
- Easier to add new related data

### 4. Replace Array with Object
Replace associative arrays with typed objects:
- Better type hints and autocomplete
- Self-documenting properties
- Validation at construction time

## Exceptions

Primitive Obsession is acceptable when:
- Working with configuration arrays or DTOs that are truly generic
- Passing simple data through frameworks with type constraints
- Building simple, throwaway scripts
- Performance-critical numeric arrays (rare cases)
- Interacting with external APIs that require primitive payloads

## Related Smells

- **Data Clumps**: Groups of primitives that always appear together - the natural next step from Primitive Obsession is bundling them into an object
- **Magic Numbers**: Unexplained numeric literals embedded in logic, which proper value objects or enums would eliminate
- **Duplicate Code**: The same validation and constraint checks scattered across the codebase because there is no central type to enforce them
- **Feature Envy**: Classes reaching into other objects to manipulate primitive fields, a pattern that disappears when those fields become rich objects

The root cause is often pragmatic: creating a primitive field is faster than introducing a new class. But this shortcut accumulates over time. Replacing primitives with small objects improves type safety, centralizes validation, and makes duplicate code detection straightforward since the logic now lives in one place.

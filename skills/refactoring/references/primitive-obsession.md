# Primitive Obsession

## Overview

Primitive Obsession is a code smell where developers excessively rely on basic data types (int, string, float, array) instead of creating small, meaningful objects to represent domain concepts. This creates scattered logic, poor encapsulation, and makes code harder to maintain and evolve.

## Why It's a Problem

- **Scattered Logic**: Related data and operations live in multiple places instead of being cohesive
- **Weak Encapsulation**: No validation or behavior bundled with data
- **Reduced Type Safety**: Primitives accept any value; domain constraints aren't enforced
- **Hidden Intent**: Magic numbers and string constants obscure business meaning
- **Duplicate Validation**: Validation logic repeats across the codebase
- **Harder to Extend**: Adding related behavior requires modifying multiple locations

## Signs and Symptoms

- Using integers to represent enumerated values (roles, statuses, permissions)
- Passing multiple related primitives as separate parameters
- String constants used as object keys in associative arrays
- Magic numbers scattered throughout code
- Validation logic duplicated in different functions
- Comments explaining what a primitive value represents
- Parameters like `$status`, `$type`, `$role` that accept any string

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

- **Data Clumps**: Multiple primitives that should be grouped together
- **Magic Numbers**: Unexplained numeric constants lacking semantic meaning
- **Duplicate Code**: Validation and constraints scattered across codebase
- **Feature Envy**: Classes accessing primitive fields from other objects excessively

## Refactoring.guru Guidance

### Signs and Symptoms
- Use of primitives instead of small objects for simple tasks (such as currency, ranges, special strings for phone numbers)
- Using constants to encode information (e.g., `USER_ADMIN_ROLE = 1`)
- Using string constants as field names in data arrays

### Reasons for the Problem
Creating a primitive field is much easier than making a whole new class, leading to accumulation of primitive fields over time. Programmers use primitives to simulate custom types through numbered or string-based constants, and sometimes use string constants as array indices for field simulation.

### Treatment
- **Replace Data Value with Object** for grouping related primitive fields
- **Introduce Parameter Object** or **Preserve Whole Object** when primitives appear in method parameters
- **Replace Type Code with Class**, **Replace Type Code with Subclasses**, or **Replace Type Code with State/Strategy** for coded data
- **Replace Array with Object** when arrays contain mixed variables

### Payoff
- Improved code flexibility through object-oriented design
- Enhanced clarity and organization with data operations grouped logically
- Simplified duplicate code detection

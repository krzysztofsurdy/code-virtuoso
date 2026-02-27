# Introduce Parameter Object

## Overview

The Introduce Parameter Object refactoring consolidates multiple related parameters into a single object. This technique eliminates code duplication when the same group of parameters appears repeatedly across methods, making code more maintainable and readable.

## Motivation

**The Problem**: When identical groups of parameters are scattered throughout your codebase, they create code duplication and make methods harder to understand. Long parameter lists are a common code smell that signals data clumping.

**The Solution**: Instead of passing multiple related parameters individually, create a dedicated object class that groups them together. This provides several advantages:

- Single, meaningful parameter instead of a long list
- Self-documenting code through the object's name
- Easier to add new related parameters in the future
- Preparation for moving related behaviors into the parameter object

## Mechanics

1. **Create a new class** to represent the parameter group (typically immutable)
2. **Add the new parameter** to your method signature while keeping existing parameters
3. **Replace old parameters one by one** with references to the object fields
4. **Test after each change** to ensure correctness
5. **Consider moving methods** into the parameter object using Move Method or Extract Method

## Before & After: PHP 8.3+ Code

### Before: Multiple Parameters

```php
class OrderService
{
    public function createOrder(
        string $customerName,
        string $customerEmail,
        string $customerPhone,
        string $address,
        string $city,
        string $zipCode
    ): Order {
        // Validation repeated across methods
        if (empty($customerName)) {
            throw new InvalidArgumentException('Name required');
        }

        // Create order...
        return new Order(
            $customerName,
            $customerEmail,
            $customerPhone,
            $address,
            $city,
            $zipCode
        );
    }

    public function validateCustomer(
        string $customerName,
        string $customerEmail,
        string $customerPhone
    ): bool {
        return !empty($customerName) && filter_var($customerEmail, FILTER_VALIDATE_EMAIL);
    }
}
```

### After: Parameter Object

```php
readonly class CustomerInfo
{
    public function __construct(
        public string $name,
        public string $email,
        public string $phone,
    ) {
        if (empty($name)) {
            throw new InvalidArgumentException('Name required');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email');
        }
    }

    public function isValid(): bool
    {
        return !empty($this->name) && filter_var($this->email, FILTER_VALIDATE_EMAIL);
    }
}

readonly class Address
{
    public function __construct(
        public string $street,
        public string $city,
        public string $zipCode,
    ) {}
}

class OrderService
{
    public function createOrder(
        CustomerInfo $customer,
        Address $address
    ): Order {
        return new Order($customer, $address);
    }

    public function validateCustomer(CustomerInfo $customer): bool
    {
        return $customer->isValid();
    }
}
```

## Benefits

- **Improved Readability**: Method signatures become clearer and self-documenting
- **Reduced Duplication**: Eliminates repetitive parameter patterns across methods
- **Better Maintainability**: Adding related parameters requires only class modification
- **Encapsulation**: Related data and validation logic can be grouped together
- **Type Safety**: Parameter objects provide stronger typing than individual primitives
- **Scalability**: Easier to extend functionality as the parameter object grows

## When NOT to Use

- When parameters are unrelated and appear together coincidentally
- If the parameter object would be used only once or twice
- When adding an intermediate class adds unnecessary complexity
- For simple, stable APIs where change frequency is low
- When domain models already encapsulate the data better

## Related Refactorings

- **Replace Parameter with Query**: Simplify method signatures by computing parameters
- **Extract Class**: Split parameter objects when they become too large
- **Move Method**: Transfer validation and behavior to the parameter object
- **Remove Parameter**: Clean up parameters no longer needed
- **Preserve Whole Object**: Pass an object instead of extracting multiple fields

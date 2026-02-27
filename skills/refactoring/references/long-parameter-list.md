# Long Parameter List

## Overview

A method or function has more than three or four parameters, making it difficult to understand, test, and use. This code smell typically emerges when algorithms are merged or when object creation logic is pushed to the calling code. Long parameter lists violate the principle of least astonishment and become increasingly confusing as parameters accumulate.

## Why It's a Problem

- **Reduced Readability**: Callers struggle to remember parameter order and meaning
- **Testing Complexity**: Creating test fixtures requires passing numerous arguments
- **Maintenance Burden**: Changes to parameters ripple through entire codebase
- **Hidden Dependencies**: Parameter relationships and constraints aren't explicit
- **Coupling Issues**: Passing many primitive values tightly couples caller to implementation

## Signs and Symptoms

- Methods with 4+ parameters
- Parameters with similar types that could be grouped
- Callers passing calculated values as parameters
- Difficulty remembering parameter order when calling methods
- Repeated parameter patterns across multiple methods
- Parameters that are only used together

## Before/After

### Before: Long Parameter List

```php
<?php declare(strict_types=1);

class OrderProcessor
{
    public function processOrder(
        string $customerEmail,
        string $customerName,
        string $addressLine1,
        string $addressLine2,
        string $city,
        string $state,
        string $zipCode,
        string $country,
        float $subtotal,
        float $tax,
        float $shipping,
        array $items,
        bool $expressShipping,
        string $paymentMethod
    ): void {
        // Complex logic with many parameters
    }
}

// Calling code is unclear and error-prone
$processor = new OrderProcessor();
$processor->processOrder(
    'john@example.com',
    'John Doe',
    '123 Main St',
    'Apt 4',
    'Springfield',
    'IL',
    '62701',
    'USA',
    150.00,
    12.50,
    10.00,
    $items,
    true,
    'credit_card'
);
```

### After: Parameter Objects

```php
<?php declare(strict_types=1);

readonly class ShippingAddress
{
    public function __construct(
        public string $line1,
        public string $line2,
        public string $city,
        public string $state,
        public string $zipCode,
        public string $country,
    ) {}
}

readonly class OrderTotal
{
    public function __construct(
        public float $subtotal,
        public float $tax,
        public float $shipping,
    ) {}

    public function getGrandTotal(): float
    {
        return $this->subtotal + $this->tax + $this->shipping;
    }
}

enum ShippingMethod
{
    case Standard;
    case Express;
}

enum PaymentMethod
{
    case CreditCard;
    case PayPal;
    case BankTransfer;
}

readonly class OrderRequest
{
    public function __construct(
        public string $customerEmail,
        public string $customerName,
        public ShippingAddress $address,
        public OrderTotal $total,
        public array $items,
        public ShippingMethod $shippingMethod,
        public PaymentMethod $paymentMethod,
    ) {}
}

class OrderProcessor
{
    public function processOrder(OrderRequest $request): void
    {
        // Clear, maintainable code with explicit structure
        $this->validateOrder($request);
        $this->calculateTax($request);
        $this->processPayment($request);
    }
}

// Calling code is clear and type-safe
$address = new ShippingAddress(
    line1: '123 Main St',
    line2: 'Apt 4',
    city: 'Springfield',
    state: 'IL',
    zipCode: '62701',
    country: 'USA',
);

$total = new OrderTotal(
    subtotal: 150.00,
    tax: 12.50,
    shipping: 10.00,
);

$request = new OrderRequest(
    customerEmail: 'john@example.com',
    customerName: 'John Doe',
    address: $address,
    total: $total,
    items: $items,
    shippingMethod: ShippingMethod::Express,
    paymentMethod: PaymentMethod::CreditCard,
);

$processor = new OrderProcessor();
$processor->processOrder($request);
```

## Recommended Refactorings

### 1. Introduce Parameter Object
Combine related parameters into a single value object. Group logically cohesive data that travels together, reducing parameter count while increasing semantic clarity.

### 2. Replace Parameter with Method Call
When a parameter is merely the result of another object's method, retrieve it directly inside the method instead of passing it. Eliminates unnecessary parameters and reduces coupling.

### 3. Preserve Whole Object
Pass the source object itself rather than extracting and passing individual values. This is effective when the caller already has access to the object, though consider circular dependency risks.

### 4. Use Enums for Options
Replace boolean flags and string choices with enums for type safety and clarity at call sites.

### 5. Extract to Builder Pattern
For complex object construction with many optional parameters, use a builder to make call sites more readable.

## Exceptions

When NOT to refactor:
- **Framework Requirements**: Some frameworks mandate specific signatures
- **Public APIs**: Changing signatures breaks client code; add overloads instead
- **Performance Critical**: If parameters are frequently accessed, object wrapping may add negligible overhead but consider profiling
- **Intentional Flexibility**: Some methods legitimately need many parameters for algorithmic control
- **Legacy Constraints**: When refactoring would require changes across large codebases

## Related Smells

- **Data Clumps**: Parameters that should be grouped into objects
- **Primitive Obsession**: Using primitives instead of value objects
- **Feature Envy**: Method using many values from another object (suggests moving the method)
- **Message Chains**: Accessing deeply nested values (related to Preserve Whole Object solution)

## Refactoring.guru Guidance

### Signs and Symptoms
More than three or four parameters for a method. The method has grown unwieldy with excessive parameters, making it difficult to understand and use effectively.

### Reasons for the Problem
Methods develop lengthy parameter lists when multiple algorithms merge into a single function or when code is refactored to increase class independence. Parameters may also accumulate when objects created elsewhere are passed as arguments instead of being accessed directly.

### Treatment
- **Replace Parameter with Method Call** when arguments are results of calling another object's methods
- **Preserve Whole Object** instead of passing individual data points extracted from another object
- **Introduce Parameter Object** to bundle related parameters from different sources into a single parameter

### Payoff
- More readable, shorter code
- Refactoring may reveal previously unnoticed duplicate code, leading to further improvements and simplification

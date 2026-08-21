# Long Parameter List

A method or function takes more than three or four parameters, which turns call sites into puzzles and invites mistakes. The smell usually appears when several algorithms are folded into one method. It also appears when callers must assemble data that the method could fetch on its own. As the parameter count climbs, the method gets harder to call, test in isolation, and maintain.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

- **Opaque call sites**: callers must remember the order and meaning of each argument, especially when several parameters share a type.
- **Test setup overhead**: test cases need many arguments, most irrelevant to the behavior under test.
- **Cascading changes**: adding, removing, or reordering parameters forces updates at every call site.
- **Hidden constraints**: dependencies and invariants among parameters stay invisible instead of being captured in a type.
- **Tight coupling**: passing many primitive values ties the caller to the method's internal expectations.

## Signs and symptoms

- Methods that accept four or more parameters
- Several parameters of the same type that logically belong together
- Callers computing values only to pass them as arguments
- Developers checking the signature to remember parameter order
- The same parameter groupings recurring across several methods
- Parameters that are never used independently of one another

## Before and after

### Before: long parameter list

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

### After: parameter objects

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

## Recommended refactorings

### 1. Introduce Parameter Object

Consolidate related parameters into a single value object. Group data that belongs together, which cuts the parameter count and makes the relationship explicit.

### 2. Replace Parameter with Method Call

When a parameter value is just the result of calling a method on another object, let the receiving method fetch it directly. This removes unnecessary arguments and loosens the coupling between caller and callee.

### 3. Preserve Whole Object

Instead of extracting individual fields from an object and passing them one by one, pass the whole object. This works well when the caller already holds a reference. Watch for circular dependencies.

### 4. Use enums for options

Replace boolean flags and string-based choices with enums. They add type safety and make the intent obvious at call sites.

### 5. Extract to Builder pattern

For assembling complex objects with many optional parameters, a builder keeps call sites readable and avoids telescoping constructors.

Refactoring long parameter lists often uncovers duplicate code, since the same parameter groupings tend to appear in several places.

## Exceptions

Do not refactor when:
- **Framework requirements**: some frameworks mandate specific method signatures
- **Public APIs**: changing signatures breaks consumer code, so add overloads or new methods instead
- **Performance sensitivity**: object wrapping adds very little overhead in most cases, but profile before deciding in hot paths
- **Deliberate flexibility**: some methods need many parameters for algorithmic control
- **Legacy constraints**: the refactoring would cascade across too large a surface to be practical

## Related smells

- **Data Clumps**: parameters that always travel together and should be grouped into objects
- **Primitive Obsession**: raw types standing in for value objects
- **Feature Envy**: a method extracting many values from another object suggests the method belongs there
- **Message Chains**: deep object traversal to extract values (related to the Preserve Whole Object solution)

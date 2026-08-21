# Introduce Parameter Object

Introduce Parameter Object bundles a recurring group of parameters into a dedicated object. When the same cluster of arguments appears in several method signatures, replacing them with one object removes duplication, clarifies intent, and gives related behavior a place to live.

## Contents

- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after: PHP 8.3+ code](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Motivation

**The problem**: Identical groups of parameters repeated across method signatures are a form of data clumping. Long parameter lists are hard to read, easy to misorder, and painful to extend.

**The solution**: Create a small, typically immutable class that holds the related values and pass one object instead of many primitives. This:

- Replaces a long parameter list with a single, meaningful argument
- Makes the method signature self-documenting through the object's class name
- Centralizes validation that was previously duplicated at every call site
- Gives methods that operate on the grouped data a natural home

## Mechanics

1. **Define a new class** for the parameter group (typically readonly/immutable).
2. **Add the new parameter** to the method signature alongside the existing ones.
3. **Migrate parameters one by one** into the object, updating callers as you go.
4. **Run tests after each step** to catch breakage early.
5. **Move related behavior** (validation, formatting, and so on) into the parameter object where it fits.

## Before and after: PHP 8.3+ code

### Before: multiple parameters

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

### After: parameter object

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

- **Readable signatures**: one named parameter shows the group's purpose at a glance.
- **Less duplication**: the parameter cluster is defined in one class, not in every method.
- **Easier extension**: adding a field to the group means changing the class, not every caller.
- **Centralized validation**: constraints are enforced once, in the constructor.
- **Stronger types**: an object carries more type information than a list of primitives.
- **Behavior magnet**: the object attracts related methods such as formatting and comparison.

## When not to use

- The parameters appear together by coincidence and do not form a coherent concept.
- The group would be used in only one or two places.
- The extra class adds complexity without measurable benefit.
- The API is simple, stable, and unlikely to change.
- An existing domain model already encapsulates the data better.

## Related refactorings

- **Replace Parameter with Query**: simplify signatures by computing values instead of passing them.
- **Extract Class**: split a parameter object that grows too large.
- **Move Method**: relocate validation and formatting logic into the parameter object.
- **Remove Parameter**: drop parameters that the parameter object makes unnecessary.
- **Preserve Whole Object**: pass an existing object rather than pulling fields out of it.

## Overview

Change Reference to Value is a refactoring technique that transforms a reference object (mutable object that is identity-based) into a value object (immutable object that is equality-based). This refactoring is beneficial when you have objects that should be treated based on their content rather than their identity.

## Motivation

In object-oriented design, objects can be classified as either:

- **Reference Objects**: Identity matters more than content. Two objects with identical data are still considered different.
- **Value Objects**: Content matters; two objects with identical data are considered equal.

You should apply this refactoring when:

1. An object is small and logically immutable
2. The object is frequently compared by value rather than identity
3. You're creating many instances of semantically identical objects
4. The reference-based approach causes confusion or inefficiency
5. You need reliable equality comparisons based on content

## Mechanics

### Before Refactoring

1. Identify a reference object that should be treated as a value
2. Verify the object has few fields and no mutable state
3. Check all places where instances are created and compared

### Steps to Refactor

1. Make the class immutable (remove setters, final properties)
2. Implement proper equality comparison (`__equals()` or PHP 8.1+ implementation)
3. Implement hashability if needed for collections
4. Update any identity-based comparisons to equality-based
5. Create factory methods for value object instantiation
6. Remove mutable operations

## Before/After PHP 8.3+ Code

### Before: Reference Object

```php
class Money
{
    private string $currency;
    private float $amount;

    public function __construct(string $currency, float $amount)
    {
        $this->currency = $currency;
        $this->amount = $amount;
    }

    public function getCurrency(): string
    {
        return $this->currency;
    }

    public function setCurrency(string $currency): void
    {
        $this->currency = $currency;
    }

    public function getAmount(): float
    {
        return $this->amount;
    }

    public function setAmount(float $amount): void
    {
        $this->amount = $amount;
    }
}

// Usage with identity comparison
$wallet1 = new Money('USD', 100.00);
$wallet2 = new Money('USD', 100.00);

if ($wallet1 === $wallet2) {  // False - different objects
    echo "Same money";
}

if ($wallet1 == $wallet2) {  // False - no __equals implementation
    echo "Equivalent money";
}
```

### After: Value Object (PHP 8.3+)

```php
final readonly class Money
{
    public function __construct(
        public string $currency,
        public float $amount,
    ) {
        if ($amount < 0) {
            throw new InvalidArgumentException('Amount cannot be negative');
        }
    }

    public function equals(Money $other): bool
    {
        return $this->currency === $other->currency
            && $this->amount === $other->amount;
    }

    public function add(Money $other): Money
    {
        if ($this->currency !== $other->currency) {
            throw new InvalidArgumentException('Cannot add different currencies');
        }
        return new Money($this->currency, $this->amount + $other->amount);
    }

    public function __toString(): string
    {
        return sprintf('%s %.2f', $this->currency, $this->amount);
    }

    public function __hash(): string
    {
        return hash('sha256', $this->currency . '|' . $this->amount);
    }
}

// Usage with value comparison
$wallet1 = new Money('USD', 100.00);
$wallet2 = new Money('USD', 100.00);

if ($wallet1->equals($wallet2)) {  // True - same value
    echo "Equivalent money";
}

// Safe to use in collections
$moneySet = [$wallet1, $wallet2];  // Duplicates are identical values
```

### Alternative: PHP 8.1+ with enum or backed enum

```php
enum Currency: string
{
    case USD = 'USD';
    case EUR = 'EUR';
    case GBP = 'GBP';
}

final readonly class Money
{
    public function __construct(
        public Currency $currency,
        public float $amount,
    ) {}

    public function equals(Money $other): bool
    {
        return $this->currency === $other->currency
            && $this->amount === $other->amount;
    }
}
```

## Benefits

- **Simplified Logic**: Equality comparisons based on content instead of identity
- **Immutability**: Eliminates whole classes of bugs from unexpected mutations
- **Better Performance**: Value objects can be safely cached and reused
- **Clearer Semantics**: The code explicitly conveys that objects are interchangeable
- **Type Safety**: Readonly properties prevent accidental modifications
- **Easier Testing**: No need to track object instances, only values matter

## When NOT to Use

- The object has mutable state that changes over time
- Object identity is fundamental to the design (like User or Entity objects)
- The object maintains references to other mutable objects
- You need polymorphic behavior through inheritance
- The object's lifecycle requires tracking and state changes
- Performance is critical and object creation overhead matters significantly

## Related Refactorings

- **Replace Data Class with Object** (opposite refactoring)
- **Extract Value Object** - Separate immutable concerns into dedicated value classes
- **Replace Type Code with Enum** - Use enums for value objects with limited options
- **Remove Setting Method** - Part of making objects immutable
- **Introduce Parameter Object** - Combine multiple parameters into a value object

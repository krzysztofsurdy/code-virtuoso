## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Change Reference to Value turns a mutable, identity-based reference object into an immutable value object whose equality depends on its contents. Use it when an object is defined by the data it carries, not by which instance you hold.

## Motivation

Object-oriented systems distinguish between two kinds of objects:

- **Reference objects**: Identity matters. Two objects with identical data are still distinct entities.
- **Value objects**: Data matters. Two objects holding the same data are interchangeable.

Consider this refactoring when:

1. The object is compact and has no meaningful mutable state
2. Code across the system compares objects by their data, not their identity
3. Multiple independent instances carry duplicate data
4. Identity-based semantics cause confusion or hard-to-trace bugs
5. You need reliable, content-based equality checks

## Mechanics

### Before refactoring

1. Identify a reference object that should behave as a value
2. Verify it has few fields and no state that legitimately changes
3. Review every place the object is instantiated and compared

### Steps

1. Remove setters and declare properties as final or readonly
2. Implement content-based equality (for example, an `equals()` method or PHP 8.1+ readonly semantics)
3. Provide hashing support if the object will live inside hash-based collections
4. Swap any identity comparisons (`===`) for equality method calls
5. Create instances through a factory or constructor and remove mutation methods
6. Remove any remaining mutable operations

## Before and after (PHP 8.3+)

### Before: reference object

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

### After: value object (PHP 8.3+)

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

### Alternative: PHP 8.1+ enum or backed enum

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

- **Reliable equality**: Comparisons reflect actual data instead of object identity
- **Immutability**: Preventing mutation removes a whole category of state-related bugs
- **Shareability and caching**: Immutable value objects can be passed around and cached safely
- **Clear semantics**: The code states that two objects with matching data are equivalent
- **Language-level enforcement**: Readonly properties enforce immutability
- **Simpler tests**: Tests check data values without tracking specific instances

## When NOT to use

- The object has state that legitimately changes over its lifetime
- Object identity is central to the domain (entities like User or Order)
- The object holds references to other mutable objects
- You rely on polymorphic behavior through inheritance hierarchies
- The object takes part in lifecycle management that requires tracking
- Object creation is expensive and reuse by reference matters

## Related refactorings

- **Replace Data Class with Object** (the opposite direction)
- **Extract Value Object** - Move immutable concerns into standalone value classes
- **Replace Type Code with Enum** - Use enums for value objects with a fixed set of options
- **Remove Setting Method** - A prerequisite step toward immutability
- **Introduce Parameter Object** - Bundle several parameters into one value object

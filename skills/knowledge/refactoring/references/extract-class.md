## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Extract Class splits a class that has too many responsibilities into two or more focused classes. When a class collects unrelated fields and methods, moving a cohesive subset into its own class restores clarity and keeps each class in line with the Single Responsibility Principle.

## Motivation

Classes grow over time. Features get added and fields multiply until the class handles concerns that have little to do with each other. Signs that extraction is overdue:

- **Multiple reasons to change**: Different kinds of requirements drive modifications to the same class
- **Feature envy**: Methods spend more time working with another class's data than their own
- **Repeated patterns**: Similar groups of fields and methods appear in several places
- **Hard-to-test code**: The class needs elaborate setup because it juggles too many concerns
- **Excessive size**: The class is long and hard to hold in your head
- **Vague purpose**: Describing what the class does takes several conjunctions

## Mechanics

1. **Spot the cohesive subset**: Identify fields and methods that belong together
2. **Create a new class**: Name it after the extracted concept
3. **Move fields**: Move the relevant fields into the new class
4. **Move methods**: Move methods that mainly operate on those fields
5. **Wire up the original class**: Replace the moved fields and methods with a reference to the new class
6. **Verify behavior**: Run the tests to confirm behavior is unchanged

## Before and after (PHP 8.3+)

### Before: class with too many responsibilities

```php
class Person {
    private string $name;
    private string $officeAreaCode;
    private string $officeNumber;
    private string $mobileAreaCode;
    private string $mobileNumber;
    private string $officeAddress;
    private string $officeCity;
    private string $officeState;
    private string $officePostalCode;
    private string $officeCountry;

    public function getPhoneNumber(string $type = 'office'): string {
        return match($type) {
            'office' => "({$this->officeAreaCode}) {$this->officeNumber}",
            'mobile' => "({$this->mobileAreaCode}) {$this->mobileNumber}",
            default => throw new InvalidArgumentException('Invalid phone type'),
        };
    }

    public function getOfficeAddress(): string {
        return "{$this->officeAddress}\n{$this->officeCity}, {$this->officeState} {$this->officePostalCode}\n{$this->officeCountry}";
    }

    public function getTelephoneNumber(): string {
        return $this->getPhoneNumber('office');
    }
}
```

### After: extracted responsibilities

```php
// New TelephoneNumber class
class TelephoneNumber {
    public function __construct(
        private readonly string $areaCode,
        private readonly string $number,
    ) {}

    public function toString(): string {
        return "({$this->areaCode}) {$this->number}";
    }

    public function getAreaCode(): string {
        return $this->areaCode;
    }

    public function getNumber(): string {
        return $this->number;
    }
}

// New Address class
class Address {
    public function __construct(
        private readonly string $street,
        private readonly string $city,
        private readonly string $state,
        private readonly string $postalCode,
        private readonly string $country,
    ) {}

    public function toString(): string {
        return "{$this->street}\n{$this->city}, {$this->state} {$this->postalCode}\n{$this->country}";
    }

    public function getCity(): string {
        return $this->city;
    }

    public function getState(): string {
        return $this->state;
    }
}

// Refactored Person class
class Person {
    public function __construct(
        private readonly string $name,
        private readonly TelephoneNumber $officeTelephone,
        private readonly TelephoneNumber $mobileTelephone,
        private readonly Address $officeAddress,
    ) {}

    public function getName(): string {
        return $this->name;
    }

    public function getOfficeTelephone(): TelephoneNumber {
        return $this->officeTelephone;
    }

    public function getMobileTelephone(): TelephoneNumber {
        return $this->mobileTelephone;
    }

    public function getOfficeAddress(): Address {
        return $this->officeAddress;
    }

    // Convenience method for backward compatibility
    public function getTelephoneNumber(): string {
        return $this->officeTelephone->toString();
    }
}

// Usage
$officeTel = new TelephoneNumber('203', '2222222');
$mobileTel = new TelephoneNumber('203', '1111111');
$address = new Address('123 Main St', 'New York', 'NY', '10001', 'USA');
$person = new Person('John Doe', $officeTel, $mobileTel, $address);

echo $person->getOfficeTelephone()->toString(); // (203) 2222222
echo $person->getOfficeAddress()->toString();    // 123 Main St
```

## Benefits

- **Focused classes**: Each class does one thing
- **Easier testing**: Smaller classes need less setup and fewer test scenarios
- **More reuse**: Extracted classes like TelephoneNumber and Address can serve other parts of the system
- **Lower cognitive load**: A class with a single concern is quicker to understand
- **Independent change**: A change to one concern does not ripple into unrelated code
- **Stronger types**: Rich types replace scattered primitives, especially with PHP 8.3+ readonly support
- **SOLID alignment**: Supports the Single Responsibility and Open/Closed principles

## When NOT to use

- **Premature extraction**: Wait until the separation is clear. Extracting too early can fragment the design
- **No natural cohesion**: If the fields and methods do not form a coherent concept, the extraction will feel forced
- **Performance-critical code**: The extra object allocation rarely matters. Profile before ruling it out
- **Trivial classes**: When the data is simple and has no behavior, a plain array or simple object may be enough
- **Early development**: Get the feature working first and extract once patterns emerge

## Related refactorings

- **Extract Method**: Often a first step that shows which groups of code belong together
- **Move Method/Field**: The fine-grained counterpart for moving individual members between classes
- **Extract Interface**: Useful after extraction when several implementations of the new concept are likely
- **Replace Temp with Query**: Removes temporary variables before extraction
- **Replace Method with Method Object**: An alternative when a single method has too many local variables
- **Introduce Parameter Object**: Groups related parameters into a new class

## Overview

Extract Class is a refactoring technique that improves code organization by breaking down a large, overly-responsible class into smaller, more focused classes. When a class accumulates too many responsibilities or contains features that naturally belong together, Extract Class creates a new class to encapsulate that subset of functionality.

This refactoring technique is essential for maintaining the Single Responsibility Principle (SRP) and reducing code complexity as applications grow.

## Motivation

Classes often grow over time, accumulating responsibilities that were originally related but have naturally separated. Several signals indicate when Extract Class is needed:

- **Multiple Reasons to Change**: If a class has multiple reasons to change, it likely violates SRP
- **Feature Envy**: Methods within a class frequently access features of another class more than its own
- **Duplicated Code**: Related code patterns appear in different classes
- **Difficult Testing**: A class is hard to test because it handles multiple concerns
- **Size and Complexity**: The class becomes difficult to understand due to its length and interconnected logic
- **Unclear Purpose**: The class description requires multiple "ifs" or "ands" to describe what it does

## Mechanics

The Extract Class refactoring follows these steps:

1. **Identify Cohesive Features**: Analyze the class to find attributes and methods that form a cohesive group
2. **Create New Class**: Create a new class to represent the extracted concept
3. **Move Fields**: Move the relevant fields from the original class to the new class
4. **Move Methods**: Move the methods that operate on those fields to the new class
5. **Update References**: Update the original class to use an instance of the new class
6. **Test Thoroughly**: Ensure all existing functionality remains intact

## Before/After PHP 8.3+ Code

### Before: Overly Responsible Class

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

### After: Extracted Responsibilities

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

- **Improved Clarity**: Each class has a single, well-defined responsibility
- **Better Testability**: Smaller classes are easier to test in isolation
- **Enhanced Reusability**: Extracted classes can be used in other contexts
- **Reduced Complexity**: Fewer responsibilities per class reduce cognitive load
- **Easier Maintenance**: Changes to one concern don't affect others
- **Type Safety**: Strong types replace scattered primitive values (especially in PHP 8.3+)
- **Follows SOLID**: Directly supports the Single Responsibility and Open/Closed principles

## When NOT to Use

Extract Class is not always appropriate:

- **Premature Extraction**: Don't extract before you're confident about the separation. Over-extraction leads to design fragmentation
- **Insufficient Cohesion**: If the extracted subset lacks clear cohesion, the extraction may not be justified
- **Performance Critical Code**: In rare performance-critical paths, additional object creation might be problematic
- **Simple Value Objects**: Sometimes using arrays or simple objects is sufficient; avoid over-engineering
- **Early Design Phases**: Focus on getting functionality working first; refactor as patterns become clear

## Related Refactorings

- **Extract Method**: Extract methods before extracting a class to better identify cohesive groups
- **Move Method/Field**: Move individual members between classes when Extract Class seems too large
- **Extract Interface**: After extracting a class, consider extracting an interface if multiple implementations are needed
- **Replace Temp with Query**: Often used alongside Extract Class to reduce temporary variables
- **Replace Method with Method Object**: An alternative when a method has many local variables
- **Introduce Parameter Object**: Group parameters into objects when methods have many related parameters

## Overview

Inline Class is a refactoring technique that removes a class by distributing its functionality to its single caller or merging it with another class. This refactoring eliminates unnecessary abstraction layers when a class has become too simple or is tightly coupled to a single consumer.

## Motivation

Classes exist to help organize and encapsulate related functionality. However, not all abstractions are beneficial. A class may become a candidate for inlining when:

- **Reduced responsibility**: A class has become too small and simple, offering little value as a separate entity.
- **Single responsibility violation**: The class is only used by one other class, indicating tight coupling that could be simplified.
- **Over-engineering**: The initial design created more abstraction than necessary for the problem domain.
- **Maintenance burden**: The class adds cognitive overhead without providing clear benefits.
- **Refactoring aftermath**: After other refactorings, a class may no longer justify its existence.

## Mechanics

1. **Analyze dependencies**: Ensure the class has minimal usage (ideally one consumer).
2. **Move members**: Migrate all fields and methods from the inline class to the consuming class.
3. **Update references**: Replace all references to the inlined class with the consuming class.
4. **Remove class**: Delete the now-empty class definition.
5. **Compile and test**: Verify that the refactoring maintains behavior without introducing regressions.

## Before/After: PHP 8.3+ Code

### Before (Unnecessary Abstraction)

```php
class Person
{
    private string $name;
    private Telephone $telephone;

    public function __construct(string $name, string $number)
    {
        $this->name = $name;
        $this->telephone = new Telephone($number);
    }

    public function getTelephoneNumber(): string
    {
        return $this->telephone->getNumber();
    }

    public function getName(): string
    {
        return $this->name;
    }
}

class Telephone
{
    private string $number;

    public function __construct(string $number)
    {
        $this->number = $number;
    }

    public function getNumber(): string
    {
        return $this->number;
    }

    public function formatNumber(): string
    {
        return preg_replace('/(\d{3})(\d{3})(\d{4})/', '($1) $2-$3', $this->number);
    }
}

// Usage
$person = new Person('John Doe', '5551234567');
echo $person->getTelephoneNumber();
```

### After (Inlined Class)

```php
class Person
{
    private string $name;
    private string $telephoneNumber;

    public function __construct(string $name, string $number)
    {
        $this->name = $name;
        $this->telephoneNumber = $number;
    }

    public function getTelephoneNumber(): string
    {
        return $this->telephoneNumber;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function formatTelephoneNumber(): string
    {
        return preg_replace(
            '/(\d{3})(\d{3})(\d{4})/',
            '($1) $2-$3',
            $this->telephoneNumber
        );
    }
}

// Usage - Same as before, but simpler structure
$person = new Person('John Doe', '5551234567');
echo $person->getTelephoneNumber();
```

## Benefits

- **Simplified codebase**: Fewer classes reduce the cognitive load and navigation overhead.
- **Clearer intent**: When there's a single responsibility, merging can make the relationship explicit.
- **Reduced indirection**: Direct method calls eliminate intermediate objects and method delegations.
- **Better maintainability**: Fewer moving parts make the code easier to understand and modify.
- **Improved testability**: Testing can focus on the unified class rather than multiple interdependent classes.
- **Performance**: Eliminates object instantiation and method delegation overhead.

## When NOT to Use

- **Multiple consumers**: If the class is used by several clients, inlining creates duplication and complexity.
- **Meaningful domain concept**: Classes representing domain entities should be preserved for clarity and expressiveness.
- **Plugin or extension points**: Classes designed for polymorphism or inheritance should not be inlined.
- **Distinct responsibilities**: If the class manages distinct concerns, preserving separation is valuable.
- **Future extensibility**: If you anticipate the class may gain additional uses or responsibilities.
- **Third-party interfaces**: Classes implementing contracts external to your module shouldn't be inlined.

## Related Refactorings

- **Extract Class**: The opposite refactoring; splits responsibilities into new classes.
- **Hide Delegate**: Encapsulates object interaction patterns (consider before inlining).
- **Replace Temp with Query**: Simplifies by removing intermediate variables.
- **Consolidate Duplicate Code**: Merges similar methods when inlining multiple classes.
- **Collapse Hierarchy**: Removes unnecessary inheritance layers, a similar pattern for class hierarchies.

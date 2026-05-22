## Overview

Inline Class dissolves a class that no longer earns its keep by folding its fields and methods into the class that uses it. When a class has shrunk to the point where it adds more indirection than value, merging it into its sole consumer simplifies the codebase.

## Motivation

Not every abstraction pays for itself. A class may become a candidate for inlining when:

- **It has too little substance**: After other refactorings, the class holds only a field or two and a trivial method
- **Only one consumer exists**: A single class uses it, making the separation purely ceremonial
- **The original split was premature**: The design introduced more structure than the problem warranted
- **Reading the code is harder**: Tracing through the extra class adds cognitive cost without illuminating intent
- **It outlived its purpose**: Subsequent refactorings have shifted responsibilities elsewhere, leaving the class hollow

## Mechanics

1. **Check usage**: Confirm the class has a single consumer (or very few)
2. **Migrate members**: Move all fields and methods from the inlined class into the consumer
3. **Redirect references**: Update all code that references the inlined class to use the consumer instead
4. **Delete the class**: Remove the now-empty class file
5. **Verify with tests**: Run the full suite to confirm behavior is preserved

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

- **Fewer moving parts**: One less class to navigate, name, and maintain
- **Direct relationships**: Data and the methods that use it live in the same place
- **Less indirection**: No delegation layer between the consumer and the data
- **Easier comprehension**: Readers see everything in one class instead of chasing references
- **Simpler testing**: Tests target a single class rather than a pair of collaborators
- **Reduced overhead**: Eliminates object creation and method delegation costs

## When NOT to Use

- **Multiple consumers**: If several classes depend on the class, inlining duplicates code and spreads responsibility
- **Meaningful domain concept**: If the class represents a real-world entity, preserving it keeps the model honest
- **Polymorphic use**: Classes designed for substitution or extension should not be collapsed
- **Distinct responsibilities**: If the class manages a genuinely separate concern, merging muddies the consumer
- **Anticipated growth**: If the class is likely to gain new behavior or additional consumers, keep it
- **External contracts**: Classes that implement interfaces consumed by other modules or libraries must stay

## Related Refactorings

- **Extract Class**: The inverse - splitting a class when it takes on too many responsibilities
- **Hide Delegate**: Consider hiding the delegation before deciding to inline
- **Replace Temp with Query**: Simplifies code by removing intermediate variables during inlining
- **Collapse Hierarchy**: A parallel refactoring that merges a subclass into its parent

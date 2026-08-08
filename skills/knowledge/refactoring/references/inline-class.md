## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after: PHP 8.3+ code](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Inline Class removes a class that no longer earns its keep by folding its fields and methods into the class that uses it. When a class has shrunk until it adds more indirection than value, merge it into its only consumer.

## Motivation

Not every abstraction pays for itself. A class is a candidate for inlining when:

- **It has too little substance**: After other refactorings, the class holds only a field or two and a trivial method
- **Only one consumer exists**: A single class uses it, so the separation is ceremony
- **The original split was premature**: The design added more structure than the problem needed
- **Reading the code is harder**: Tracing through the extra class costs effort and clarifies nothing
- **It outlived its purpose**: Later refactorings moved its responsibilities elsewhere and left it hollow

## Mechanics

1. **Check usage**: Confirm the class has a single consumer (or very few)
2. **Move members**: Move all fields and methods from the inlined class into the consumer
3. **Redirect references**: Update all code that references the inlined class to use the consumer
4. **Delete the class**: Remove the now-empty class file
5. **Run the tests**: Run the full suite to confirm behavior is preserved

## Before and after: PHP 8.3+ code

### Before (unnecessary abstraction)

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

### After (inlined class)

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
- **Easier to read**: Everything is in one class, with no references to chase
- **Simpler testing**: Tests target one class instead of a pair of collaborators
- **Less overhead**: No extra object creation or method delegation

## When not to use

- **Multiple consumers**: If several classes depend on the class, inlining duplicates code and spreads the responsibility
- **Meaningful domain concept**: If the class represents a real-world entity, keeping it keeps the model accurate
- **Polymorphic use**: Classes designed for substitution or extension should stay
- **Distinct responsibilities**: If the class manages a separate concern, merging muddies the consumer's purpose
- **Anticipated growth**: If the class is likely to gain new behavior or additional consumers, keep it
- **External contracts**: Classes that implement interfaces consumed by other modules or libraries must stay

## Related refactorings

- **Extract Class**: The inverse: splitting a class that has too many responsibilities
- **Hide Delegate**: Consider hiding the delegation before you decide to inline
- **Replace Temp with Query**: Removes intermediate variables while you inline
- **Collapse Hierarchy**: A similar refactoring that merges a subclass into its parent

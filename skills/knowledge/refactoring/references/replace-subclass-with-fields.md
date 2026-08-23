## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After](#beforeafter)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)

## Overview

Replace Subclass with Fields collapses a class hierarchy by removing subclasses whose only job is to return different values for a set of fields. A single class with configurable fields, usually set through factory methods, handles all the variation.

Use it when the subclasses differ only in the field values they assign.

## Motivation

Subclasses that differ only in the data they store add structure for no gain:

- **Too many classes**: Several classes do the same thing with slightly different data
- **Redundant maintenance**: Changes to shared logic must be applied across every subclass
- **Hidden instantiation rules**: Client code must know which subclass to build for each case
- **Repeated boilerplate**: Each subclass duplicates constructor logic
- **Testing overhead**: Covering many classes that behave almost the same is wasteful

Folding these subclasses into the parent class with configurable fields means fewer types and a design that is easier to navigate.

## Mechanics

1. **Identify data-only subclasses**: Find subclasses that differ only in how they initialize inherited fields
2. **Introduce factory methods**: Add a static factory method to the parent class for each variant
3. **Shift field initialization**: Let the factory methods set the field values directly
4. **Delete subclasses**: Remove the now-redundant subclass definitions
5. **Redirect client code**: Update all instantiation sites to use the factory methods
6. **Verify**: Run the test suite to confirm behavior is unchanged

## Before/After

### Before (PHP 8.3+)

```php
abstract class Employee {
    protected string $name;
    protected string $type;

    public function __construct(string $name) {
        $this->name = $name;
    }

    public function getType(): string {
        return $this->type;
    }

    public function getName(): string {
        return $this->name;
    }
}

class Engineer extends Employee {
    public function __construct(string $name) {
        parent::__construct($name);
        $this->type = 'engineer';
    }
}

class Manager extends Employee {
    public function __construct(string $name) {
        parent::__construct($name);
        $this->type = 'manager';
    }
}

class Intern extends Employee {
    public function __construct(string $name) {
        parent::__construct($name);
        $this->type = 'intern';
    }
}

// Client code
$engineer = new Engineer('Alice');
$manager = new Manager('Bob');
$intern = new Intern('Charlie');
```

### After (PHP 8.3+)

```php
class Employee {
    public function __construct(
        private string $name,
        private string $type,
    ) {}

    public static function createEngineer(string $name): self {
        return new self($name, 'engineer');
    }

    public static function createManager(string $name): self {
        return new self($name, 'manager');
    }

    public static function createIntern(string $name): self {
        return new self($name, 'intern');
    }

    public function getType(): string {
        return $this->type;
    }

    public function getName(): string {
        return $this->name;
    }
}

// Client code
$engineer = Employee::createEngineer('Alice');
$manager = Employee::createManager('Bob');
$intern = Employee::createIntern('Charlie');
```

## Benefits

- **Fewer classes**: Removes subclasses that add no behavior
- **Simpler hierarchy**: The type structure is flatter and easier to picture
- **Centralized logic**: All behavior lives in one class, which simplifies maintenance
- **Expressive construction**: Factory methods state the purpose of each variant
- **Easier instantiation**: Callers use descriptive factory methods instead of remembering subclass names
- **Strong typing**: One class with typed properties (in PHP 8.3+) gives a clear contract
- **Easy extension**: A new variant is one factory method, not a whole class

## When NOT to use

- **Behavioral differences**: If subclasses override methods beyond initialization, keep them
- **Non-trivial constructors**: If subclass constructors contain significant setup logic, the hierarchy may be justified
- **Polymorphic contracts**: If subclasses implement different interfaces, do not collapse them
- **Field explosion**: If the parent class would collect many optional fields, subclasses may be clearer
- **API compatibility**: If external code depends on the subclass types, removing them is a breaking change

## Related Refactorings

- **Replace Conditional with Polymorphism**: Consider it if the single class starts to grow switch statements on the type field
- **Extract Superclass**: Use it to share behavior among several classes by moving it up
- **Factory Method Pattern**: The factory methods introduced here follow this pattern
- **Replace Type Code with Subclass**: The inverse refactoring, applied when distinct behavior is needed

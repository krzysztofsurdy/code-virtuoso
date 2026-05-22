## Overview

Replace Subclass with Fields collapses a class hierarchy by eliminating subclasses whose only purpose is to return different values for a set of fields. Instead of maintaining separate subclass definitions, a single class with configurable fields - typically populated through factory methods - handles all the variation.

This refactoring is appropriate when subclasses carry no behavioral differences beyond assigning distinct field values.

## Motivation

Subclasses that differ only in the data they store introduce unnecessary structural complexity:

- **Excessive class count**: Multiple classes exist that functionally do the same thing with slightly different data
- **Redundant maintenance**: Changes to shared logic must be propagated across every subclass
- **Obscured instantiation**: Client code must know which subclass to construct for each scenario
- **Repeated boilerplate**: Each subclass duplicates constructor logic
- **Testing overhead**: Covering many classes that behave almost identically is wasteful

Consolidating these subclasses into the parent class with configurable fields reduces the number of types in the system and makes the design easier to navigate and maintain.

## Mechanics

1. **Identify data-only subclasses**: Find subclasses that differ solely in how they initialize inherited fields
2. **Introduce factory methods**: Add static factory methods to the parent class for each variant
3. **Shift field initialization**: Let the factory methods set the appropriate field values directly
4. **Delete subclasses**: Remove the now-redundant subclass definitions
5. **Redirect client code**: Update all instantiation sites to use the factory methods
6. **Verify**: Run the test suite to confirm that behavior is unchanged

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

- **Fewer classes**: Removes subclasses that carry no real behavioral weight
- **Simpler hierarchy**: The type structure becomes flatter and easier to visualize
- **Centralized logic**: All behavior lives in a single class, simplifying maintenance
- **Expressive construction**: Factory methods communicate the purpose of each variant clearly
- **Easier instantiation**: Callers use descriptive factory methods rather than remembering subclass names
- **Strong typing**: A single class with typed properties (especially in PHP 8.3+) provides clear contracts
- **Easy extension**: Adding a new variant means adding one factory method, not an entire class

## When NOT to Use

- **Behavioral differences exist**: If subclasses override methods beyond mere initialization, they deserve to remain
- **Non-trivial constructors**: If subclass constructors contain significant setup logic, the hierarchy may be justified
- **Polymorphic contracts**: When subclasses implement different interfaces, collapsing them is inappropriate
- **Field explosion**: If the parent class would accumulate many optional fields, subclasses might actually be clearer
- **API compatibility**: If external code depends on the subclass types, removing them is a breaking change

## Related Refactorings

- **Replace Conditional with Polymorphism**: Consider if the resulting single class develops switch statements on the type field
- **Extract Superclass**: Used when you want to share behavior among multiple classes by factoring it upward
- **Factory Method Pattern**: The factory methods introduced here follow this design pattern
- **Replace Type Code with Subclass**: The inverse refactoring, applied when distinct behavior needs to be introduced

## Overview

Replace Subclass with Fields is a refactoring technique that simplifies class hierarchies by removing subclasses that only exist to provide different values for a set of fields. Instead of having multiple subclass variants, use a single class with configurable fields that can be set during instantiation or through a factory method.

This refactoring reduces complexity when subclasses serve no purpose beyond storing different combinations of attribute values.

## Motivation

Subclasses introduce unnecessary complexity when they only differ in the values they assign to parent class fields. This creates several problems:

- **Increased complexity**: Multiple classes do the same thing in slightly different ways
- **Maintenance burden**: Changes to shared logic must be replicated across subclasses
- **Difficult instantiation**: Clients must know which subclass to instantiate for different scenarios
- **Code duplication**: Each subclass repeats constructor logic
- **Poor testability**: Multiple classes doing similar things are harder to test comprehensively

By consolidating subclasses into a single parent class with configurable fields, you reduce the number of classes and make the codebase simpler to understand and maintain.

## Mechanics

1. **Identify subclass-only variations**: Find subclasses that only differ in field initialization values
2. **Add factory method**: Create a static factory method or method in the parent class
3. **Move field initialization**: Replace constructor calls with factory methods that set field values
4. **Remove subclasses**: Delete the now-unnecessary subclass definitions
5. **Update references**: Change all client code that instantiated subclasses to use the new factory methods
6. **Test**: Verify that behavior remains unchanged

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

- **Reduced class count**: Eliminates unnecessary subclasses
- **Simpler hierarchy**: Easier to understand and visualize the structure
- **Better maintainability**: Logic is centralized in one class
- **Clearer intent**: Factory methods clearly express what each variant represents
- **Easier instantiation**: Clients use descriptive factory methods instead of remembering subclass names
- **Type safety**: Single class definition with clear field types (especially with PHP 8.3+ typed properties)
- **Flexibility**: Adding new variants is simpler (just add a new factory method)

## When NOT to Use

- **Behavior differs**: If subclasses override methods beyond just initialization, keep them
- **Complex initialization logic**: If subclass constructors contain significant logic, subclasses may be warranted
- **Polymorphic contracts**: When subclasses implement different interfaces or contracts, refactoring is inappropriate
- **Large field count**: If the parent class would accumulate many optional fields, subclasses might be clearer
- **Existing API compatibility**: If you can't modify existing code that depends on the subclass hierarchy

## Related Refactorings

- **Replace Conditional with Polymorphism**: Consider after this refactoring if you have switch statements based on the type field
- **Extract Superclass**: If you want to share behavior among multiple classes
- **Factory Method Pattern**: The factory methods created during this refactoring follow this design pattern
- **Replace Type Code with Subclass**: The inverse operation when behavior differentiation is necessary

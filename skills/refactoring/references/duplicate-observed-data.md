## Overview

Duplicate Observed Data is a refactoring technique that eliminates the duplication of data between domain models and their UI representations. It establishes a synchronization mechanism using the Observer pattern, where the UI automatically updates whenever domain data changes, ensuring a single source of truth.

This refactoring is particularly valuable in applications with complex UI logic that mirrors domain data, preventing inconsistencies and reducing maintenance burden.

## Motivation

### When to Apply

- **Parallel Data Storage**: Data is stored both in domain objects and UI components
- **Synchronization Problems**: Data gets out of sync when domain is updated but UI isn't
- **Redundant Updates**: Code frequently updates both domain and UI with the same values
- **Bug-Prone Changes**: Forgetting to update one copy creates subtle bugs
- **Complex State Management**: Multiple places maintain the same information
- **Difficult Testing**: UI logic is tightly coupled to data duplication

### Why It Matters

Duplicate Observed Data ensures data consistency by establishing a single source of truth (the domain model) with automatic UI synchronization. This reduces bugs, simplifies testing, and makes changes safer.

## Mechanics: Step-by-Step

1. **Identify Duplication**: Find where the same data is stored in domain and UI
2. **Implement Observer Interface**: Create observer mechanism in domain model
3. **Add Observers to UI**: Register UI components as observers of domain changes
4. **Update Domain Model**: Modify domain to notify observers when data changes
5. **Remove UI Data Storage**: Eliminate duplicate data storage in UI components
6. **Change UI Access**: Update UI to read from domain instead of cached copies
7. **Test Synchronization**: Verify UI updates automatically on all domain changes

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class Person
{
    private string $name;
    private int $age;

    public function __construct(string $name, int $age)
    {
        $this->name = $name;
        $this->age = $age;
    }

    public function setName(string $name): void
    {
        $this->name = $name;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setAge(int $age): void
    {
        $this->age = $age;
    }

    public function getAge(): int
    {
        return $this->age;
    }
}

class PersonUI
{
    private string $nameField;
    private int $ageField;
    private Person $person;

    public function __construct(Person $person)
    {
        $this->person = $person;
        // Duplicate data storage in UI
        $this->nameField = $person->getName();
        $this->ageField = $person->getAge();
    }

    public function updatePerson(string $name, int $age): void
    {
        // Must update both domain and UI separately
        $this->person->setName($name);
        $this->person->setAge($age);

        // Easy to forget these UI updates
        $this->nameField = $name;
        $this->ageField = $age;
    }

    public function getNameDisplay(): string
    {
        return $this->nameField;
    }

    public function getAgeDisplay(): int
    {
        return $this->ageField;
    }

    // Risk: Data can become out of sync if person is updated elsewhere
}
```

## After: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

interface Observer
{
    public function update(): void;
}

class Person
{
    private string $name;
    private int $age;
    /** @var Observer[] */
    private array $observers = [];

    public function __construct(string $name, int $age)
    {
        $this->name = $name;
        $this->age = $age;
    }

    public function attach(Observer $observer): void
    {
        $this->observers[] = $observer;
    }

    public function detach(Observer $observer): void
    {
        $this->observers = array_filter(
            $this->observers,
            fn(Observer $obs) => $obs !== $observer
        );
    }

    private function notifyObservers(): void
    {
        foreach ($this->observers as $observer) {
            $observer->update();
        }
    }

    public function setName(string $name): void
    {
        $this->name = $name;
        $this->notifyObservers();
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setAge(int $age): void
    {
        $this->age = $age;
        $this->notifyObservers();
    }

    public function getAge(): int
    {
        return $this->age;
    }
}

class PersonUI implements Observer
{
    private Person $person;

    public function __construct(Person $person)
    {
        $this->person = $person;
        // Register as observer instead of storing duplicate data
        $person->attach($this);
    }

    public function update(): void
    {
        // Automatically called when person changes
        // No need to manually sync - read from domain directly
    }

    public function updatePerson(string $name, int $age): void
    {
        // Single update point - domain notifies observers
        $this->person->setName($name);
        $this->person->setAge($age);
    }

    public function getNameDisplay(): string
    {
        // Always reads from single source of truth
        return $this->person->getName();
    }

    public function getAgeDisplay(): int
    {
        // Always reads from single source of truth
        return $this->person->getAge();
    }

    public function __destruct()
    {
        $this->person->detach($this);
    }
}

// Usage
$person = new Person('John Doe', 30);
$ui = new PersonUI($person);

echo $ui->getNameDisplay(); // "John Doe"

// Update through UI
$ui->updatePerson('Jane Doe', 31);
echo $ui->getNameDisplay(); // "Jane Doe" - automatically synced

// Update domain directly - UI stays in sync automatically
$person->setName('Bob Smith');
echo $ui->getNameDisplay(); // "Bob Smith" - still synced
```

## Benefits

- **Single Source of Truth**: Domain model is the only authoritative data store
- **Automatic Synchronization**: UI updates automatically without manual coordination
- **Reduced Bugs**: No risk of data inconsistency between domain and UI
- **Cleaner Code**: Eliminates duplicate update logic scattered throughout
- **Better Testability**: UI logic can be tested independently of data duplication
- **Easier Maintenance**: Changes to data structure require updates in one place only
- **Flexible Observers**: Multiple UI components can observe the same domain object
- **Decoupled Design**: Domain doesn't depend on UI; UI depends on domain through observer interface

## When NOT to Use

- **Simple Value Objects**: For immutable or read-only data, duplication may be unnecessary
- **Performance-Critical Code**: Observer notifications add overhead; avoid in tight loops
- **Many Small Updates**: Frequent notifications might overwhelm observers; consider batching
- **Decoupled Systems**: When domain and UI are completely separate processes/services
- **Legacy Systems**: Implementing observer pattern in tightly-coupled legacy code may require extensive refactoring
- **Unidirectional Data**: If data only flows from UI to domain, not back, duplication isn't the issue

## Related Refactorings

- **Extract Class**: Create separate observer classes if UI becomes too complex
- **Replace Temp with Query**: Eliminate temporary variables that duplicate data
- **Replace Data Value with Object**: Convert primitive fields to richer objects that can notify observers
- **Move Method**: Move observer-related methods to appropriate classes
- **Introduce Parameter Object**: Group related observed fields into objects
- **Observer Pattern**: Foundation for implementing this refactoring

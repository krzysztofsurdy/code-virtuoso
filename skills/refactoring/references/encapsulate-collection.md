## Overview

Encapsulate Collection is a refactoring technique that replaces public access to collection fields with controlled getter and setter methods. Instead of exposing a raw collection that external code can directly modify, the collection is hidden behind an API that governs all interactions. This ensures the object maintains control over its state and can enforce invariants.

## Motivation

Collections are frequently mutable data structures. When a collection field is public or accessed directly through a simple getter returning the reference, external code can add, remove, or modify elements without the class knowing about these changes. This leads to several problems:

- Loss of encapsulation and control over state
- Inability to validate or enforce business rules
- Difficulty debugging unexpected collection mutations
- Code that's fragile and hard to maintain
- Violation of the Single Responsibility Principle

By encapsulating the collection, the class becomes a gatekeeper for all collection operations, enabling validation, logging, and consistent state management.

## Mechanics

1. **Create getter and adder/remover methods**: Instead of returning the collection directly, provide methods like `getItems()`, `addItem()`, and `removeItem()`.

2. **Return unmodifiable copies**: The getter should return a copy or read-only view to prevent external mutation.

3. **Remove direct access**: Delete the public field or make it private.

4. **Update all clients**: Replace direct collection access with the new methods throughout the codebase.

5. **Consider bulk operations**: Add methods for adding/removing multiple items if performance is a concern.

## Before/After PHP 8.3+ Code

### Before: Direct Collection Access

```php
class Person
{
    public array $hobbies = [];
}

// Client code - problematic
$person = new Person();
$person->hobbies[] = 'reading';
$person->hobbies[] = 'gaming';
unset($person->hobbies[0]); // Direct modification!
```

### After: Encapsulated Collection

```php
class Person
{
    private array $hobbies = [];

    public function addHobby(string $hobby): void
    {
        if (empty(trim($hobby))) {
            throw new InvalidArgumentException('Hobby cannot be empty');
        }
        if (!in_array($hobby, $this->hobbies, true)) {
            $this->hobbies[] = $hobby;
        }
    }

    public function removeHobby(string $hobby): void
    {
        $key = array_search($hobby, $this->hobbies, true);
        if ($key !== false) {
            unset($this->hobbies[$key]);
            $this->hobbies = array_values($this->hobbies); // Re-index
        }
    }

    public function getHobbies(): array
    {
        return [...$this->hobbies]; // Return copy, not reference
    }

    public function hasHobby(string $hobby): bool
    {
        return in_array($hobby, $this->hobbies, true);
    }
}

// Client code - controlled and safe
$person = new Person();
$person->addHobby('reading');
$person->addHobby('gaming');
$person->removeHobby('reading');
$hobbies = $person->getHobbies();
```

### Advanced: Using Collections Class (PHP 8.3+)

```php
#[Attribute]
readonly class Hobby
{
    public function __construct(public string $name) {}
}

class PersonWithCollection
{
    /** @var array<Hobby> */
    private array $hobbies = [];

    public function addHobby(Hobby $hobby): self
    {
        if (!in_array($hobby, $this->hobbies, true)) {
            $this->hobbies[] = $hobby;
        }
        return $this;
    }

    public function removeHobby(Hobby $hobby): self
    {
        $this->hobbies = array_filter(
            $this->hobbies,
            fn(Hobby $h) => $h !== $hobby
        );
        return $this;
    }

    /** @return array<Hobby> */
    public function getHobbies(): array
    {
        return [...$this->hobbies];
    }

    public function countHobbies(): int
    {
        return count($this->hobbies);
    }
}

// Usage
$person = new PersonWithCollection();
$person->addHobby(new Hobby('reading'))
       ->addHobby(new Hobby('gaming'));

foreach ($person->getHobbies() as $hobby) {
    echo $hobby->name;
}
```

## Benefits

- **Encapsulation**: The class maintains full control over its collections
- **Validation**: Add business logic when items are added or removed
- **Maintainability**: Changes to collection handling are isolated in one place
- **Debugging**: Track modifications through controlled methods
- **Immutability guarantees**: Returned copies prevent accidental external mutations
- **Consistency**: Ensures invariants are maintained at all times
- **Clear intent**: The API explicitly shows allowed collection operations

## When NOT to Use

- **Performance-critical code**: Copying large collections on every access may be inefficient; consider lazy loading or more sophisticated collection patterns
- **Simple data holders**: If the class is purely a data container with no validation logic, full encapsulation may be over-engineering
- **Immutable value objects**: If using immutable types (readonly classes with named constructors), direct field access may be acceptable
- **Internal-only classes**: Private classes with no external consumers may not need full encapsulation
- **Working with Collection Framework**: If using specialized collection libraries, defer to their encapsulation patterns

## Related Refactorings

- **Extract Class**: Break down overly complex collection management into separate objects
- **Replace Temp with Query**: Cache collection computations rather than storing mutable collections
- **Move Method**: Relocate collection-specific logic from clients to the collection owner
- **Introduce Parameter Object**: Group related collection-like parameters into a dedicated class
- **Replace Array with Object**: Convert arrays to typed objects for better type safety and encapsulation

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Encapsulate Collection replaces direct public access to a collection field with a controlled API of add, remove, and query methods. The class becomes the gatekeeper for every change to the collection. External code can no longer bypass validation or break invariants.

## Motivation

Collections are mutable. When exposed through a public field or a getter that returns the live reference, any caller can insert, delete, or replace elements without the owning class knowing. This causes several problems:

- The class loses control over its own state
- Business rules and validation logic can be bypassed
- Unexpected mutations are hard to debug
- The code becomes fragile and hard to change
- Responsibilities leak from the owning class to its callers

Wrapping the collection behind dedicated methods lets the class validate inputs, enforce constraints, and react to changes.

## Mechanics

1. **Provide targeted mutation methods**: Create `addX()` and `removeX()` methods instead of exposing the raw collection
2. **Return defensive copies**: The getter should return a copy or read-only snapshot so callers cannot mutate the original
3. **Restrict field visibility**: Make the collection field private
4. **Migrate all callers**: Replace every direct collection change in client code with a call to the new methods
5. **Add bulk operations if needed**: For performance-sensitive paths, add methods that accept several items at once

## Before and after (PHP 8.3+)

### Before: direct collection access

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

### After: encapsulated collection

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

### Advanced: collection class (PHP 8.3+)

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

- **Full state control**: The owning class decides what goes into the collection and when
- **Built-in validation**: Business rules are enforced every time the collection changes
- **Localized changes**: All collection management logic lives in one place
- **Observable mutations**: Changes go through methods that can log, trigger events, or audit
- **Safe reads**: Returning copies stops callers from altering internal state by accident
- **Preserved invariants**: The class can guarantee consistency at all times
- **Deliberate API**: The allowed operations are explicit and easy to find

## When NOT to use

- **Hot paths with large collections**: Copying a large array on every read can hurt performance. Consider lazy or immutable collection types instead
- **Pure data holders**: If the class has no validation logic and serves only as a data container, full encapsulation may be needless overhead
- **Immutable value objects**: Readonly classes constructed via named constructors may not need mutation methods
- **Internal-only classes**: Private implementation details with no external consumers may not need the ceremony
- **Specialized collection libraries**: If a library has its own encapsulation conventions, follow those instead

## Related refactorings

- **Extract Class**: When collection management grows complex enough to justify its own class
- **Replace Temp with Query**: Avoids caching collection computations in temporary variables
- **Move Method**: Moves collection-related logic from callers into the collection owner
- **Introduce Parameter Object**: Bundles related collection-like parameters into a dedicated type
- **Replace Array with Object**: Turns untyped arrays into typed objects for stronger guarantees

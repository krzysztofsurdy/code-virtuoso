## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After PHP 8.3+ code](#beforeafter-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Self Encapsulate Field replaces direct field access inside a class with getter and setter methods. The accessors sit between the field and all code that reads or writes it, so the class can change its internal representation without affecting its consumers.

Instead of referencing a field directly (e.g., `$this->name`), all access goes through accessor methods (`getName()` and `setName()`). This pays off in larger systems where fields eventually need validation, change notification, or deferred initialization.

## Motivation

Reasons to encapsulate fields:

1. **Flexibility**: storage format or computation logic can change without breaking callers.
2. **Validation**: setters can enforce constraints and business rules at the point of assignment.
3. **Side effects**: field changes can trigger observers, dirty flags, or audit logging.
4. **Lazy initialization**: getters can delay expensive object creation until first access.
5. **Single Responsibility**: data access is separated from data storage.
6. **Gradual evolution**: computed properties or derived values can be introduced later.

## Mechanics

1. Write a getter method that returns the field value.
2. Write a setter method that assigns a new value to the field.
3. Find every direct read of the field in the class.
4. Replace each direct read with a call to the getter.
5. Replace each direct write with a call to the setter.
6. Restrict the field's visibility to private or protected.
7. Add validation or side-effect logic to the setter as needed.

## Before/After PHP 8.3+ code

### Before: direct field access

```php
class User
{
    public string $email;
    public int $age;
    public string $status = 'active';

    public function __construct(string $email, int $age)
    {
        $this->email = $email;
        $this->age = $age;
    }

    public function processUser(): void
    {
        // Direct access to fields throughout the class
        if ($this->age < 18) {
            $this->status = 'minor';
        }

        echo "User: " . $this->email . " is " . $this->status;
    }
}

// Client code with direct access
$user = new User('john@example.com', 15);
$user->email = 'newemail@example.com'; // Direct assignment
$user->age = 25; // Direct assignment
echo $user->status; // Direct read
```

### After: encapsulated access

```php
class User
{
    private string $email;
    private int $age;
    private string $status = 'active';

    public function __construct(string $email, int $age)
    {
        $this->setEmail($email);
        $this->setAge($age);
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): void
    {
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email format');
        }
        $this->email = $email;
    }

    public function getAge(): int
    {
        return $this->age;
    }

    public function setAge(int $age): void
    {
        if ($age < 0 || $age > 150) {
            throw new InvalidArgumentException('Age must be between 0 and 150');
        }
        $this->age = $age;
        // Trigger validation logic
        $this->updateStatus();
    }

    public function getStatus(): string
    {
        return $this->status;
    }

    protected function setStatus(string $status): void
    {
        $this->status = $status;
    }

    private function updateStatus(): void
    {
        if ($this->age < 18) {
            $this->setStatus('minor');
        } else {
            $this->setStatus('adult');
        }
    }

    public function processUser(): void
    {
        if ($this->getAge() < 18) {
            $this->setStatus('minor');
        }

        echo "User: " . $this->getEmail() . " is " . $this->getStatus();
    }
}

// Client code with encapsulated access
$user = new User('john@example.com', 15);
$user->setEmail('newemail@example.com'); // Through setter
$user->setAge(25); // Through setter with validation
echo $user->getStatus(); // Through getter
```

## Benefits

- **Validation and constraints**: business rules are enforced at the moment of assignment.
- **Centralized modification**: all changes to a field pass through one point, which simplifies debugging.
- **Lazy initialization**: expensive computations can be deferred until the getter is first called.
- **Observable state**: observers or event handlers can be triggered on field changes.
- **Computed properties**: a field can be replaced by a derived value without callers noticing.
- **Backward compatibility**: the internal representation can change without altering the public API.
- **Debugging**: breakpoints in getters and setters make it easy to trace access.
- **Polymorphic behavior**: subclasses can override accessors to customize field behavior.

## When not to use

- **Value Objects**: immutable value classes with final fields may not benefit from encapsulation.
- **DTOs**: simple data transfer objects might not justify the getters and setters.
- **High-frequency access**: accessor overhead is negligible, but in extreme cases it may matter.
- **Wholesale public fields**: if the entire codebase relies on public fields, a massive encapsulation effort may not be justified.
- **Already encapsulated**: if getters and setters are already in place, further application yields little.

## Related refactorings

- **Replace Data Value with Object**: upgrades a primitive field to a dedicated object with richer behavior.
- **Remove Setter**: eliminates setters for fields that should be immutable or write-once.
- **Replace Temp with Query**: extracts field initialization logic into query methods.
- **Hide Delegate**: encapsulates internal dependencies behind the class's own interface.
- **Introduce Parameter Object**: bundles related fields into a single parameter object.

## Examples in other languages

### Java

**Before:**
```java
class Range {
  private int low, high;
  boolean includes(int arg) {
    return arg >= low && arg <= high;
  }
}
```

**After:**
```java
class Range {
  private int low, high;
  boolean includes(int arg) {
    return arg >= getLow() && arg <= getHigh();
  }
  int getLow() {
    return low;
  }
  int getHigh() {
    return high;
  }
}
```

### C#

**Before:**
```csharp
class Range
{
  private int low, high;

  bool Includes(int arg)
  {
    return arg >= low && arg <= high;
  }
}
```

**After:**
```csharp
class Range
{
  private int low, high;

  int Low {
    get { return low; }
  }
  int High {
    get { return high; }
  }

  bool Includes(int arg)
  {
    return arg >= Low && arg <= High;
  }
}
```

### TypeScript

**Before:**
```typescript
class Range {
  private low: number
  private high: number;
  includes(arg: number): boolean {
    return arg >= low && arg <= high;
  }
}
```

**After:**
```typescript
class Range {
  private low: number
  private high: number;
  includes(arg: number): boolean {
    return arg >= getLow() && arg <= getHigh();
  }
  getLow(): number {
    return low;
  }
  getHigh(): number {
    return high;
  }
}
```

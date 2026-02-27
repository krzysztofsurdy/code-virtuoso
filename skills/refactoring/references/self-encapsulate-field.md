## Overview

Self Encapsulate Field is a fundamental refactoring technique that involves replacing direct access to a class field with getter and setter methods. This creates an intermediary layer between the field and its users, allowing for future modifications without affecting external code.

Rather than accessing a field directly (e.g., `$this->name`), you create getter and setter methods (`getName()` and `setName()`) and route all access through these methods. This is particularly valuable in larger systems where fields may need validation, notification, or lazy initialization.

## Motivation

**Why encapsulate fields:**

1. **Flexibility**: Future code changes to field storage or computation become possible without breaking client code
2. **Validation**: Setters can enforce constraints and business rules
3. **Notifications**: You can trigger side effects when fields change (observers, dirty flags, etc.)
4. **Lazy initialization**: Getters can defer expensive object creation until actually needed
5. **Single Responsibility**: Separates data access from data modification logic
6. **Controlled Evolution**: Allows gradual introduction of computed properties or derived values

## Mechanics

The refactoring process involves:

1. Create a getter method that returns the field's current value
2. Create a setter method that assigns a new value to the field
3. Find all direct accesses to the field (both reads and writes)
4. Replace field reads with getter calls
5. Replace field assignments with setter calls
6. Make the field private or protected
7. Consider adding validation or side effects in setters

## Before/After PHP 8.3+ Code

### Before: Direct Field Access

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

### After: Encapsulated Access

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

- **Validation & Constraints**: Enforce business rules in setters before state changes
- **Change Location**: Centralize field modification logic for easier debugging
- **Lazy Initialization**: Defer expensive computations until needed
- **Observable State**: Add notifications when fields change (observer pattern)
- **Computed Properties**: Fields can become derived from other values
- **Backward Compatible**: Change implementation without affecting public contracts
- **Debugging**: Set breakpoints in getters/setters to trace field access
- **Polymorphic Behavior**: Override getters/setters in subclasses

## When NOT to Use

- **Value Objects**: Immutable value classes with final fields may not need encapsulation
- **DTOs**: Simple data transfer objects might not benefit from getter/setter overhead
- **Performance-Critical Code**: High-frequency access might suffer minimal overhead impact (though usually negligible)
- **Legacy Systems**: If the codebase uses public fields universally, massive refactoring may not be justified
- **Getters/Setters Exist**: If the pattern is already established, applying it further offers diminishing returns

## Related Refactorings

- **Replace Data Value with Object**: Convert primitive field to a dedicated object
- **Remove Setter**: For immutable or write-once fields, eliminate setters
- **Replace Temp with Query**: Extract field initialization logic into methods
- **Hide Delegate**: Encapsulate dependencies within the class
- **Introduce Parameter Object**: Group related fields into a single parameter object

## Examples in Other Languages

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

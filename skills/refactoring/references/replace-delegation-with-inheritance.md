# Replace Delegation with Inheritance

## Overview

Replace Delegation with Inheritance is a refactoring technique that converts a class that delegates to another class into a subclass of that delegate. This eliminates unnecessary delegation methods when a class delegates its entire public interface to a single delegate object.

Instead of maintaining wrapper methods that forward calls, the class inherits directly from the delegate, gaining direct access to all parent methods.

## Motivation

While delegation is powerful and flexible, this advantage diminishes when:

- A class delegates to **only one** delegate object
- The class delegates **all or most** public methods of that delegate
- Wrapper methods create unnecessary code duplication

In these scenarios, inheritance provides a simpler, cleaner design without sacrificing flexibility when the inheritance relationship is semantically correct.

## Mechanics

1. **Establish inheritance**: Make your class extend the delegate class
2. **Remove delegation methods**: Delete wrapper methods one by one
3. **Replace field access**: Change all references to the delegate field with `this`
4. **Delete the delegate field**: Once all delegation methods are removed
5. **Test thoroughly**: Ensure polymorphic behavior remains correct

## Before/After Examples

### Before: Delegation Pattern

```php
readonly class PersonAddress
{
    public function __construct(
        private string $street,
        private string $city,
        private string $zipCode,
    ) {}

    public function street(): string
    {
        return $this->street;
    }

    public function city(): string
    {
        return $this->city;
    }

    public function zipCode(): string
    {
        return $this->zipCode;
    }
}

class Employee
{
    private PersonAddress $address;

    public function __construct(
        private string $name,
        PersonAddress $address,
    ) {
        $this->address = $address;
    }

    public function name(): string
    {
        return $this->name;
    }

    // Delegating methods
    public function street(): string
    {
        return $this->address->street();
    }

    public function city(): string
    {
        return $this->address->city();
    }

    public function zipCode(): string
    {
        return $this->address->zipCode();
    }
}
```

### After: Inheritance Pattern

```php
readonly class PersonAddress
{
    public function __construct(
        private string $street,
        private string $city,
        private string $zipCode,
    ) {}

    public function street(): string
    {
        return $this->street;
    }

    public function city(): string
    {
        return $this->city;
    }

    public function zipCode(): string
    {
        return $this->zipCode;
    }
}

final class Employee extends PersonAddress
{
    public function __construct(
        private string $name,
        string $street,
        string $city,
        string $zipCode,
    ) {
        parent::__construct($street, $city, $zipCode);
    }

    public function name(): string
    {
        return $this->name;
    }

    // No delegation methods needed!
}
```

## Benefits

- **Reduced code duplication**: Eliminates boilerplate delegation methods
- **Improved maintainability**: Fewer methods to update when parent class changes
- **Clearer intent**: Direct inheritance semantically expresses "is-a" relationships
- **Simpler API**: One coherent interface instead of repeated wrapper methods
- **Better polymorphism**: Subclass can be used wherever parent is expected

## When NOT to Use

- **Partial delegation**: If your class only delegates *some* methods, not all—this violates Liskov Substitution Principle and breaks polymorphic contracts
- **Multiple inheritance needed**: If the class already extends another class (use composition instead)
- **Semantically incorrect**: If the relationship is truly "has-a" not "is-a"
- **Encapsulation breaking**: If inheritance exposes methods that should remain hidden
- **Loose coupling preferred**: When delegation better expresses optional dependency

## Related Refactorings

- **Extract Superclass**: Create a common parent for multiple delegating classes
- **Hide Delegate**: Reverse operation—convert inheritance to delegation for better encapsulation
- **Replace Type Code with Subclasses**: Use inheritance to handle variant behaviors
- **Form Template Method**: When subclasses have similar structure, extract common behavior
- **Introduce Strategy Pattern**: Use composition when multiple algorithms apply to same data

## Examples in Other Languages

### Java

**Before:**

```java
class Employee {
    Person person = new Person();

    String getName() {
        return person.getName();
    }

    void setName(String name) {
        person.setName(name);
    }

    String toString() {
        return "Employee: " + person.getLastName();
    }
}
```

**After:**

```java
class Employee extends Person {
    String toString() {
        return "Employee: " + getLastName();
    }
}
```

### C#

**Before:**

```csharp
class Employee
{
    Person person = new Person();

    string GetName() => person.GetName();
    void SetName(string name) => person.SetName(name);

    string ToString() => "Employee: " + person.GetLastName();
}
```

**After:**

```csharp
class Employee : Person
{
    override string ToString() => "Employee: " + GetLastName();
}
```

### Python

**Before:**

```python
class Employee:
    def __init__(self):
        self._person = Person()

    def get_name(self) -> str:
        return self._person.get_name()

    def set_name(self, name: str):
        self._person.set_name(name)

    def __str__(self) -> str:
        return f"Employee: {self._person.get_last_name()}"
```

**After:**

```python
class Employee(Person):
    def __str__(self) -> str:
        return f"Employee: {self.get_last_name()}"
```

### TypeScript

**Before:**

```typescript
class Employee {
    private person: Person = new Person();

    getName(): string {
        return this.person.getName();
    }

    setName(name: string): void {
        this.person.setName(name);
    }

    toString(): string {
        return `Employee: ${this.person.getLastName()}`;
    }
}
```

**After:**

```typescript
class Employee extends Person {
    toString(): string {
        return `Employee: ${this.getLastName()}`;
    }
}
```

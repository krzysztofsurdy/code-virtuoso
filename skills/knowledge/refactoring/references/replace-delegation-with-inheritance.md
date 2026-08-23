# Replace Delegation with Inheritance

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After Examples](#beforeafter-examples)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Delegation with Inheritance turns a class that wraps another object and forwards most of its methods into a subclass of that object. When a class forwards nearly its whole public interface to one collaborator, the wrapper is boilerplate and adds no abstraction. Inheriting directly removes the forwarding code. The subclass then uses the parent's behavior as its own.

## Motivation

Delegation is a useful way to compose objects, but it loses its value when:

- A class delegates to **only one** delegate object
- The class delegates **all or most** public methods of that delegate
- Wrapper methods duplicate code for no gain

In these cases inheritance is simpler, as long as the inheritance relationship makes sense.

## Mechanics

1. **Establish inheritance**: Make your class extend the delegate class
2. **Remove delegation methods**: Delete wrapper methods one by one
3. **Replace field access**: Change all references to the delegate field to `this`
4. **Delete the delegate field**: Once all delegation methods are removed
5. **Run the tests**: Check that polymorphic behavior is still correct

## Before/After Examples

### Before: delegation

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

### After: inheritance

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

- **Less boilerplate**: Forwarding methods disappear and inherited behavior takes their place
- **Stays in sync**: Changes to the parent class reach the subclass without edits
- **Clear relationship**: The type system states the "is-a" relationship instead of leaving it implied
- **One interface**: One class instead of mirrored method signatures
- **Substitutability**: The subclass can be used wherever the parent type is expected

## When NOT to use

- **Partial delegation**: If your class delegates only *some* methods, inheriting violates the Liskov Substitution Principle and breaks polymorphic contracts
- **Multiple inheritance needed**: If the class already extends another class, use composition instead
- **Wrong relationship**: The relationship is "has-a", not "is-a"
- **Broken encapsulation**: Inheritance would expose methods that should stay hidden
- **Loose coupling preferred**: Delegation better expresses an optional dependency

## Related Refactorings

- **Extract Superclass**: Create a common parent for multiple delegating classes
- **Hide Delegate**: The reverse operation. Convert inheritance to delegation for better encapsulation
- **Replace Type Code with Subclasses**: Use inheritance to handle variant behaviors
- **Form Template Method**: When subclasses have a similar structure, extract the common behavior
- **Introduce Strategy Pattern**: Use composition when several algorithms apply to the same data

## Examples in other languages

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

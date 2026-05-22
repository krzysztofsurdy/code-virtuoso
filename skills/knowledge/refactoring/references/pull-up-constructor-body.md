## Overview

Pull Up Constructor Body extracts repeated initialization logic from subclass constructors into a shared superclass constructor. When several subclasses perform the same setup steps - assigning the same fields, running the same validation - that common work belongs in the parent, leaving each subclass responsible only for its own unique initialization.

## Motivation

Duplicated constructor code across sibling classes creates familiar problems:

- **Synchronized edits**: Changing the shared initialization forces updates in every subclass
- **Consistency gaps**: A fix applied to one constructor can easily be missed in another
- **Larger codebase**: Redundant lines inflate the size of the hierarchy without adding value
- **Hidden commonality**: Developers may not realize that initialization logic is identical across classes

Centralizing the shared portion in the superclass establishes a single authoritative version of the common setup and lets each subclass focus exclusively on what makes it different.

## Mechanics

The refactoring follows these steps:

1. **Analyze subclass constructors** - Identify identical or nearly identical initialization code across subclasses
2. **Create superclass constructor** - Define a new constructor in the parent class that contains the shared logic
3. **Determine parameters** - Include only parameters the superclass genuinely needs (subclasses may have additional parameters)
4. **Call parent constructor** - Update each subclass constructor to call the superclass constructor as the first statement using `parent::__construct()`
5. **Remove duplicate code** - Delete the now-redundant initialization code from subclass constructors
6. **Test thoroughly** - Verify that all subclass instantiation behavior remains identical

## Before/After (PHP 8.3+ Code)

### Before - Duplicate Constructor Logic

```php
abstract class Vehicle
{
    protected string $brand;
    protected string $color;
    protected float $price;
}

class Car extends Vehicle
{
    private int $doors;

    public function __construct(
        string $brand,
        string $color,
        float $price,
        int $doors
    ) {
        $this->brand = $brand;
        $this->color = $color;
        $this->price = $price;
        $this->doors = $doors;
    }
}

class Motorcycle extends Vehicle
{
    private bool $hasSidecar;

    public function __construct(
        string $brand,
        string $color,
        float $price,
        bool $hasSidecar
    ) {
        $this->brand = $brand;
        $this->color = $color;
        $this->price = $price;
        $this->hasSidecar = $hasSidecar;
    }
}
```

### After - Common Logic in Superclass

```php
abstract class Vehicle
{
    protected string $brand;
    protected string $color;
    protected float $price;

    public function __construct(
        string $brand,
        string $color,
        float $price
    ) {
        $this->brand = $brand;
        $this->color = $color;
        $this->price = $price;
    }
}

class Car extends Vehicle
{
    private int $doors;

    public function __construct(
        string $brand,
        string $color,
        float $price,
        int $doors
    ) {
        parent::__construct($brand, $color, $price);
        $this->doors = $doors;
    }
}

class Motorcycle extends Vehicle
{
    private bool $hasSidecar;

    public function __construct(
        string $brand,
        string $color,
        float $price,
        bool $hasSidecar
    ) {
        parent::__construct($brand, $color, $price);
        $this->hasSidecar = $hasSidecar;
    }
}
```

## Benefits

- **One authoritative version**: Shared initialization lives in a single place
- **Guaranteed consistency**: Every subclass initializes inherited properties through the same path
- **Lighter subclasses**: Constructors shrink to only the subclass-specific setup
- **Clearer hierarchy**: The parent-child relationship becomes explicit in the constructor chain
- **Easier verification**: Testing the common setup requires exercising only the parent constructor

## When NOT to Use

- **Minimal duplication** - If only one or two lines are duplicated, consider keeping them separate
- **Fundamentally different initialization** - If subclasses initialize parent properties in substantially different ways, duplication may indicate a design problem better solved with composition
- **Conditional logic complexity** - If pulling up creates overly complex conditional logic in the parent constructor, this is a code smell
- **Parameter misalignment** - If subclasses require entirely different parameters, pulling up may hide design issues
- **Interface contracts** - If constructors are meant to signal different contracts to clients, keep them separate

## Related Refactorings

- **Pull Up Method** - Similar concept applied to regular methods rather than constructors
- **Extract Superclass** - Often used in conjunction when creating new common parent classes
- **Replace Constructor with Factory Method** - Alternative for complex initialization logic
- **Move Method** - For moving constructor logic to utility classes instead of up the hierarchy

## Examples in Other Languages

### Java

**Before:**

```java
class Manager extends Employee {
    public Manager(String name, String id, int grade) {
        this.name = name;
        this.id = id;
        this.grade = grade;
    }
}
```

**After:**

```java
class Manager extends Employee {
    public Manager(String name, String id, int grade) {
        super(name, id);
        this.grade = grade;
    }
}
```

### C#

**Before:**

```csharp
public class Manager : Employee
{
    public Manager(string name, string id, int grade)
    {
        this.name = name;
        this.id = id;
        this.grade = grade;
    }
}
```

**After:**

```csharp
public class Manager : Employee
{
    public Manager(string name, string id, int grade) : base(name, id)
    {
        this.grade = grade;
    }
}
```

### Python

**Before:**

```python
class Manager(Employee):
    def __init__(self, name: str, id: str, grade: int):
        self.name = name
        self.id = id
        self.grade = grade
```

**After:**

```python
class Manager(Employee):
    def __init__(self, name: str, id: str, grade: int):
        super().__init__(name, id)
        self.grade = grade
```

### TypeScript

**Before:**

```typescript
class Manager extends Employee {
    constructor(name: string, id: string, grade: number) {
        this.name = name;
        this.id = id;
        this.grade = grade;
    }
}
```

**After:**

```typescript
class Manager extends Employee {
    constructor(name: string, id: string, grade: number) {
        super(name, id);
        this.grade = grade;
    }
}
```

# Pull Up Constructor Body

## Overview

Pull Up Constructor Body moves repeated initialization logic from subclass constructors into a shared superclass constructor. When several subclasses run the same setup steps, such as assigning the same fields or running the same validation, that work belongs in the parent. Each subclass then handles only its own initialization.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+ code)](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Duplicated constructor code across sibling classes causes familiar problems:

- **Synchronized edits**: changing the shared initialization forces updates in every subclass.
- **Consistency gaps**: a fix applied to one constructor is easy to miss in another.
- **Larger codebase**: redundant lines add size to the hierarchy and no value.
- **Hidden commonality**: developers may not notice that the initialization logic is identical across classes.

Moving the shared part into the superclass gives one authoritative version of the common setup. Each subclass can then focus on what makes it different.

## Mechanics

1. **Analyze subclass constructors**: find identical or nearly identical initialization code across subclasses.
2. **Create the superclass constructor**: define a constructor in the parent class that contains the shared logic.
3. **Determine parameters**: include only the parameters the superclass needs. Subclasses may have additional parameters.
4. **Call the parent constructor**: in each subclass constructor, call `parent::__construct()` as the first statement.
5. **Remove duplicate code**: delete the redundant initialization code from the subclass constructors.
6. **Test**: verify that instantiating every subclass behaves as before.

## Before and after (PHP 8.3+ code)

### Before: duplicate constructor logic

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

### After: common logic in the superclass

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

- **One authoritative version**: shared initialization lives in a single place.
- **Consistency**: every subclass initializes inherited properties through the same path.
- **Lighter subclasses**: constructors shrink to the subclass-specific setup.
- **Clearer hierarchy**: the parent-child relationship is explicit in the constructor chain.
- **Easier verification**: testing the common setup means exercising only the parent constructor.

## When not to use

- **Minimal duplication**: if only one or two lines are duplicated, consider keeping them separate.
- **Different initialization**: if subclasses initialize parent properties in very different ways, the duplication may point to a design problem that composition would solve better.
- **Conditional logic complexity**: if pulling up creates complex conditional logic in the parent constructor, that is a code smell.
- **Parameter misalignment**: if subclasses need entirely different parameters, pulling up may hide design issues.
- **Interface contracts**: if the constructors are meant to signal different contracts to clients, keep them separate.

## Related refactorings

- **Pull Up Method**: the same idea applied to regular methods instead of constructors.
- **Extract Superclass**: often used together with this refactoring when you create a new common parent class.
- **Replace Constructor with Factory Method**: an alternative for complex initialization logic.
- **Move Method**: for moving constructor logic to utility classes instead of up the hierarchy.

## Examples in other languages

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

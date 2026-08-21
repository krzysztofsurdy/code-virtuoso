# Pull Up Method

## Overview

Pull Up Method moves identical or nearly identical methods from several subclasses into their shared superclass. When sibling classes carry the same implementation, moving it to the parent removes the redundancy. Every subclass then uses one consistent version.

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after code](#before-and-after-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Motivation

Duplicate methods across subclasses are a maintenance hazard. Each change must be copied to every version, and a missed copy causes inconsistencies that show up as bugs. Pulling the method into the superclass gives one implementation that all children inherit. The codebase gets smaller and later changes are easier.

## Mechanics

1. **Examine similar methods** across subclasses to find candidates for consolidation.
2. **Standardize implementations**: if the methods differ slightly, adjust their logic so one version works for all.
3. **Handle subclass-specific dependencies** with Pull Up Field or abstract getter and setter methods.
4. **Move the method** to the superclass.
5. **Remove the duplicate implementations** from all subclasses.
6. **Test** that behavior is consistent across the class hierarchy.

## Before and after code

### Before (PHP 8.3+)

```php
abstract class Employee {
    protected string $name;

    public function __construct(string $name) {
        $this->name = $name;
    }
}

class Manager extends Employee {
    public function getAnnualBonus(): float {
        return 5000.0;
    }
}

class Developer extends Employee {
    public function getAnnualBonus(): float {
        return 5000.0;
    }
}

class Designer extends Employee {
    public function getAnnualBonus(): float {
        return 5000.0;
    }
}
```

### After (PHP 8.3+)

```php
abstract class Employee {
    protected string $name;

    public function __construct(string $name) {
        $this->name = $name;
    }

    public function getAnnualBonus(): float {
        return 5000.0;
    }
}

class Manager extends Employee {}

class Developer extends Employee {}

class Designer extends Employee {}
```

## Benefits

- **No copies**: one implementation serves the whole hierarchy.
- **Consistency**: all subclasses inherit the same logic with no manual syncing.
- **Lower bug risk**: edits happen in one place, so no copy is missed.
- **Leaner hierarchy**: subclasses shrink and the class tree is easier to scan.
- **Foundation for patterns**: a pulled-up method can become the skeleton of a Template Method.

## When not to use

- The subclass methods have different implementations and only look similar.
- Pulling up the method would make the superclass depend on subclass-specific details.
- The method relies on state that exists only in some subclasses and cannot be abstracted.
- The cost of the abstraction is larger than the benefit of reuse.

## Related refactorings

- **Push Down Method**: the opposite operation. It moves methods from the superclass down to specific subclasses.
- **Pull Up Field**: consolidates fields from subclasses into the superclass.
- **Extract Method**: often used first to isolate duplicate logic before pulling it up.
- **Template Method pattern**: can be formed by pulling up methods and leaving specific steps for subclasses to override.

## Examples in other languages

### Java

**Before:**

```java
class Employee {
    // ...
}

class Salesman extends Employee {
    String getName() {
        // ...
    }
}

class Engineer extends Employee {
    String getName() {
        // ...
    }
}
```

**After:**

```java
class Employee {
    String getName() {
        // ...
    }
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

### C#

**Before:**

```csharp
class Employee
{
    // ...
}

class Salesman : Employee
{
    string GetName()
    {
        // ...
    }
}

class Engineer : Employee
{
    string GetName()
    {
        // ...
    }
}
```

**After:**

```csharp
class Employee
{
    string GetName()
    {
        // ...
    }
}

class Salesman : Employee
{
}

class Engineer : Employee
{
}
```

### Python

**Before:**

```python
class Employee:
    pass

class Salesman(Employee):
    def get_name(self) -> str:
        # ...

class Engineer(Employee):
    def get_name(self) -> str:
        # ...
```

**After:**

```python
class Employee:
    def get_name(self) -> str:
        # ...

class Salesman(Employee):
    pass

class Engineer(Employee):
    pass
```

### TypeScript

**Before:**

```typescript
class Employee {
    // ...
}

class Salesman extends Employee {
    getName(): string {
        // ...
    }
}

class Engineer extends Employee {
    getName(): string {
        // ...
    }
}
```

**After:**

```typescript
class Employee {
    getName(): string {
        // ...
    }
}

class Salesman extends Employee {
}

class Engineer extends Employee {
}
```

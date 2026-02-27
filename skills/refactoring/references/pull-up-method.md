## Overview

Pull Up Method is a refactoring technique that consolidates identical or nearly identical methods found in multiple subclasses into their shared superclass. This eliminates code duplication and ensures changes need to be made in only one location rather than across multiple subclass implementations.

## Motivation

When you have identical or nearly identical methods scattered across subclasses, you create maintenance burdens. Each change must be replicated across every subclass, increasing the risk of inconsistent implementations and bugs. By pulling these methods up to the superclass, you create a single source of truth that benefits all subclasses.

## Mechanics

1. **Examine similar methods** across subclasses to identify candidates for consolidation
2. **Standardize implementations** if methods differ slightly by adjusting their logic to work universally
3. **Handle subclass-specific dependencies** using Pull Up Field or abstract getter/setter methods
4. **Move the method** to the superclass
5. **Remove duplicate implementations** from all subclasses
6. **Test thoroughly** to ensure behavior remains consistent across the class hierarchy

## Before/After Code

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

- **Eliminates code duplication**: Single implementation reduces maintenance burden
- **Improves consistency**: All subclasses automatically use the same logic
- **Reduces bug risk**: Changes happen in one location, preventing inconsistent updates
- **Simplifies the class hierarchy**: Makes the codebase easier to understand
- **Facilitates future refactoring**: Makes it easier to apply patterns like Template Method

## When NOT to Use

- When methods in subclasses have fundamentally different implementations and only appear similar on the surface
- When pulling up a method would require the superclass to know about subclass-specific details
- When the method relies on state that exists only in specific subclasses and cannot be abstracted
- When the overhead of abstraction outweighs the benefit of code reuse

## Related Refactorings

- **Push Down Method**: The opposite operation; moves methods from superclass down to specific subclasses
- **Pull Up Field**: Consolidates fields from subclasses into the superclass
- **Extract Method**: Often used in conjunction to identify and isolate duplicate logic before pulling up
- **Template Method Pattern**: Can be formed by pulling up methods and leaving specific steps to be overridden by subclasses

## Examples in Other Languages

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

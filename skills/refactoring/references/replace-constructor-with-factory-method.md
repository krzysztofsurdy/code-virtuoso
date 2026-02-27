## Overview

Replace Constructor with Factory Method refactoring creates a static factory method to handle object instantiation instead of relying on direct constructor calls. The factory method encapsulates creation logic and can perform additional operations beyond simple initialization, including returning appropriate subclass instances, caching objects, or handling complex initialization sequences.

## Motivation

This refactoring becomes essential in several scenarios:

1. **Subclass-based type handling**: After refactoring type codes into subclasses, factory methods enable returning the correct subclass instance based on parameters—something constructors cannot accomplish.

2. **Complex initialization logic**: When constructors perform operations beyond simple field assignment, a factory method can better express intent and manage this complexity.

3. **Multiple creation modes**: Support different object creation scenarios without cluttering the constructor.

4. **Object caching and reuse**: Return pre-existing cached objects instead of always creating new instances.

## Mechanics

The refactoring follows these steps:

1. Create a static factory method that calls the constructor and handles additional logic
2. Replace all constructor calls with factory method invocations
3. Mark the constructor as private to prevent direct instantiation
4. Extract non-construction logic from the constructor into the factory method

## Before/After: PHP 8.3+ Code

**Before** (Complex constructor with type code):

```php
class Employee
{
    private int $type;
    private string $name;
    private float $salary;

    public function __construct(int $type, string $name, float $salary)
    {
        // Complex initialization logic mixed with simple assignment
        if ($type === 1) {
            $this->type = $type;
            $this->salary = $salary * 1.5;
        } elseif ($type === 2) {
            $this->type = $type;
            $this->salary = $salary * 1.2;
        } else {
            throw new InvalidArgumentException('Invalid employee type');
        }
        $this->name = $name;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }
}

// Usage
$employee = new Employee(1, 'John', 50000);
```

**After** (Factory method with polymorphic returns):

```php
abstract class Employee
{
    public function __construct(
        protected int $type,
        protected string $name,
        protected float $salary
    ) {}

    public static function create(int $type, string $name, float $salary): self
    {
        return match ($type) {
            1 => new Manager($type, $name, $salary * 1.5),
            2 => new Developer($type, $name, $salary * 1.2),
            default => throw new InvalidArgumentException('Invalid employee type')
        };
    }

    abstract public function getSalary(): float;

    private function __construct(int $type, string $name, float $salary) {}
}

class Manager extends Employee
{
    public function getSalary(): float
    {
        return $this->salary;
    }
}

class Developer extends Employee
{
    public function getSalary(): float
    {
        return $this->salary;
    }
}

// Usage
$employee = Employee::create(1, 'John', 50000);
```

**Example with caching**:

```php
class DatabaseConnection
{
    private static array $connections = [];

    private function __construct(
        private string $host,
        private string $database
    ) {}

    public static function create(string $host, string $database): self
    {
        $key = "{$host}:{$database}";

        if (!isset(self::$connections[$key])) {
            self::$connections[$key] = new self($host, $database);
        }

        return self::$connections[$key];
    }

    public function connect(): void
    {
        echo "Connected to {$this->host}/{$this->database}\n";
    }
}

// Usage - returns cached instance on second call
$conn1 = DatabaseConnection::create('localhost', 'mydb');
$conn2 = DatabaseConnection::create('localhost', 'mydb');
// $conn1 === $conn2 is true
```

## Benefits

- **Polymorphic returns**: Factory methods can return subclass instances selected by internal logic
- **Descriptive naming**: Method names like `create()` or `fromString()` clarify purpose better than generic constructors
- **Object reuse**: Can return existing instances instead of always creating new objects
- **Separated concerns**: Construction logic and initialization are properly separated
- **Testability**: Easier to mock and test factory methods compared to constructors

## When NOT to Use

- **Simple constructors**: Avoid this refactoring if the constructor performs only basic field assignment
- **Performance-critical code**: If object instantiation is a bottleneck and factory method overhead matters
- **Immutable value objects**: For simple value objects where direct construction is clearer
- **Framework-managed objects**: Avoid if your framework requires direct constructor access for dependency injection
- **One-time usage**: If factory method is called in only one place, direct construction may be clearer

## Related Refactorings

- **Replace Type Code with Subclasses**: Often used in conjunction with this refactoring
- **Change Value to Reference**: Factory methods help implement object identity and caching
- **Extract Method**: Use to simplify factory method logic
- **Factory Method design pattern**: This refactoring implements this fundamental design pattern

## Examples in Other Languages

### Java

**Before:**
```java
class Employee {
  Employee(int type) {
    this.type = type;
  }
  // ...
}
```

**After:**
```java
class Employee {
  static Employee create(int type) {
    employee = new Employee(type);
    // do some heavy lifting.
    return employee;
  }
  // ...
}
```

### C#

**Before:**
```csharp
public class Employee
{
  public Employee(int type)
  {
    this.type = type;
  }
  // ...
}
```

**After:**
```csharp
public class Employee
{
  public static Employee Create(int type)
  {
    employee = new Employee(type);
    // Do some heavy lifting.
    return employee;
  }
  // ...
}
```

### TypeScript

**Before:**
```typescript
class Employee {
  constructor(type: number) {
    this.type = type;
  }
  // ...
}
```

**After:**
```typescript
class Employee {
  static create(type: number): Employee {
    let employee = new Employee(type);
    // Do some heavy lifting.
    return employee;
  }
  // ...
}
```

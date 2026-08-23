## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After: PHP 8.3+ code](#beforeafter-php-83-code)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Constructor with Factory Method introduces a static creation method that takes over instantiation. A factory method can do things a constructor cannot. It can pick which subclass to return, return a cached instance, or express intent through a descriptive name. The constructor often becomes private, so all creation goes through the factory.

## Motivation

Use this refactoring in these situations:

1. **Subclass-based type handling**: After turning type codes into subclasses, a factory method can return the right subclass for the given parameters. A constructor cannot.

2. **Complex initialization logic**: When a constructor does more than assign fields, a factory method states the intent better and holds the complexity.

3. **Multiple creation modes**: Support different ways of creating an object without cluttering the constructor.

4. **Object caching and reuse**: Return an existing cached object instead of always creating a new one.

## Mechanics

1. Create a static factory method that calls the constructor and handles additional logic
2. Replace all constructor calls with factory method invocations
3. Mark the constructor as private to prevent direct instantiation
4. Extract non-construction logic from the constructor into the factory method

## Before/After: PHP 8.3+ code

**Before** (complex constructor with type code):

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

**After** (factory method with polymorphic returns):

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

**Example with caching:**

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

- **Subclass selection**: The factory can inspect arguments and return the appropriate concrete type
- **Meaningful names**: Methods like `createFromArray()` or `withDefaults()` reveal purpose better than a generic constructor
- **Instance reuse**: The factory can return cached objects instead of allocating new ones
- **Separation of concerns**: Creation decisions live in the factory and the constructor only assigns fields
- **Testability**: Factories are easy to stub or mock in unit tests

## When NOT to use

- **Simple constructors**: Skip it if the constructor only assigns fields
- **Performance-critical code**: Object instantiation is a bottleneck and factory method overhead matters
- **Immutable value objects**: For simple value objects, direct construction is clearer
- **Framework-managed objects**: The framework needs direct constructor access for dependency injection
- **Single call site**: If the factory method would be called in only one place, direct construction may be clearer

## Related Refactorings

- **Replace Type Code with Subclasses**: Often used in conjunction with this refactoring
- **Change Value to Reference**: Factory methods help implement object identity and caching
- **Extract Method**: Use to simplify factory method logic
- **Factory Method design pattern**: This refactoring is an application of that pattern

## Examples in other languages

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

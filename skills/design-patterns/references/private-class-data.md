## Overview

The Private Class Data pattern is a behavioral design pattern that controls write access to class data by encapsulating it within a separate, private data holder object. This pattern restricts data modification to initialization time, ensuring immutability and preventing accidental state changes after object construction.

## Intent

- Separate object data from object behavior
- Control write access to class attributes
- Provide immutable data after construction
- Reduce complexity by isolating data management concerns
- Protect internal state consistency

## Problem/Solution

**Problem:**
When building complex objects, you need to ensure that critical data cannot be modified after initialization. Without proper safeguards, class attributes remain mutable, risking inconsistent state and making the object's contract unclear. Direct access to mutable fields also increases coupling and reduces control over data integrity.

**Solution:**
Create a separate private data holder class that encapsulates all data attributes. Pass this data holder to the main class at construction time, making it immutable. The main class can access data through the private holder, but external entities cannot modify it. This provides:

- Clear separation between data and behavior
- Guaranteed immutability after construction
- Controlled data access patterns
- Reduced complexity in the main class

## Structure

```
┌─────────────────────┐
│   MainClass         │
│─────────────────────│
│ - dataHolder        │
│─────────────────────│
│ + __construct()     │
│ + getData()         │
│ + processData()     │
└──────────┬──────────┘
           │
           ○ contains
           │
┌──────────▼──────────┐
│  DataHolder         │
│─────────────────────│
│ - name: string      │
│ - value: int        │
│ - config: array     │
│─────────────────────│
│ + getName(): string │
│ + getValue(): int   │
│ + getConfig(): array│
└─────────────────────┘
```

## When to Use

- **Immutable Objects**: When you need objects that are effectively immutable after construction
- **Complex Data**: When managing multiple related data attributes that should change together or not at all
- **Value Objects**: For objects that represent values rather than entities with changing behavior
- **Thread Safety**: When building thread-safe objects where data consistency is critical
- **Framework Integration**: When integrating with systems that rely on immutable configuration objects
- **Data Integrity**: When certain data combinations must remain consistent throughout the object's lifetime

## Implementation (PHP 8.3+ Strict Types)

```php
<?php

declare(strict_types=1);

namespace App\Design\PrivateClassData;

/**
 * DataHolder: Encapsulates all class data
 * Made readonly to prevent reassignment
 */
final readonly class EmployeeDataHolder
{
    public function __construct(
        private string $id,
        private string $name,
        private string $department,
        private float $salary,
        private array $benefitsPlan = []
    ) {}

    public function getId(): string
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getDepartment(): string
    {
        return $this->department;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }

    public function getBenefitsPlan(): array
    {
        return $this->benefitsPlan;
    }
}

/**
 * MainClass: Uses DataHolder for immutable data access
 */
final class Employee
{
    private readonly EmployeeDataHolder $dataHolder;

    public function __construct(
        string $id,
        string $name,
        string $department,
        float $salary,
        array $benefitsPlan = []
    ) {
        $this->dataHolder = new EmployeeDataHolder(
            $id,
            $name,
            $department,
            $salary,
            $benefitsPlan
        );
    }

    public function getId(): string
    {
        return $this->dataHolder->getId();
    }

    public function getName(): string
    {
        return $this->dataHolder->getName();
    }

    public function getDepartment(): string
    {
        return $this->dataHolder->getDepartment();
    }

    public function getSalary(): float
    {
        return $this->dataHolder->getSalary();
    }

    public function getAnnualBenefitValue(): float
    {
        $benefits = $this->dataHolder->getBenefitsPlan();
        return array_sum($benefits);
    }

    public function getDisplayInfo(): string
    {
        return sprintf(
            '%s (%s) - %s Department',
            $this->dataHolder->getName(),
            $this->dataHolder->getId(),
            $this->dataHolder->getDepartment()
        );
    }
}

// Usage Example
$employee = new Employee(
    id: 'EMP001',
    name: 'John Doe',
    department: 'Engineering',
    salary: 95000.00,
    benefitsPlan: ['health' => 5000, 'dental' => 1500, '401k' => 3000]
);

echo $employee->getDisplayInfo();
echo "\n";
echo "Annual Benefit Value: $" . number_format($employee->getAnnualBenefitValue(), 2);

// Data is immutable - no setters available
// $employee->setName('Jane Doe'); // TypeError: Cannot initialize readonly property
```

## Real-World Analogies

**Passport/ID Document**: Once issued, a passport contains immutable data (name, number, expiration). While you carry it and reference it, you cannot change the data within it. Modifications require obtaining a new document.

**Birth Certificate**: Contains fixed information that cannot be altered after issuance. Organizations reference it but cannot modify its contents.

**Configuration File**: Once loaded into memory, configuration data is typically immutable. Components read from it but cannot change it, ensuring consistency across the application.

## Pros and Cons

### Advantages
- **Immutability**: Guarantees data consistency after construction
- **Thread Safety**: Immutable objects are inherently thread-safe
- **Predictability**: Objects cannot change state unexpectedly
- **Clear Contracts**: Intent to provide read-only data is explicit
- **Reduced Bugs**: Eliminates class of bugs related to unexpected mutations
- **Easy Testing**: Immutable objects are simpler to test and reason about

### Disadvantages
- **Initialization Cost**: All data must be provided at construction time
- **Flexibility Loss**: Cannot adjust data after creation without creating new instance
- **Memory Overhead**: May require creating new objects for updates
- **Learning Curve**: Team must understand immutability patterns
- **Boilerplate Code**: Additional DataHolder class adds verbosity
- **Refactoring Complexity**: Changing data structure requires class redesign

## Relations with Other Patterns

**Value Object**: Private Class Data is often combined with Value Objects to create fully immutable data carriers.

**Immutable Object**: This pattern is a concrete implementation of the Immutable Object pattern using composition.

**Builder Pattern**: Often paired with Builder to safely construct complex DataHolder objects with validation.

**Adapter Pattern**: DataHolder can serve as an adapter between external data formats and internal object requirements.

**Repository Pattern**: DataHolder objects are frequently returned by repositories as immutable data transfer objects.

**Snapshot Pattern**: Similar in approach but focuses on capturing object state at a point in time.

## Examples in Other Languages

### C#

Before (mutable attributes exposed):

```csharp
public class Circle {
    private double radius;
    private Color color;
    private Point origin;

    public Circle(double radius, Color color, Point origin) {
        this.radius = radius;
        this.color = color;
        this.origin = origin;
    }

    public double Circumference {
        get { return 2 * Math.PI * this.radius; }
    }

    public double Diameter {
        get { return 2 * this.radius; }
    }

    public void Draw(Graphics graphics) {
        //...
    }
}
```

After (data encapsulated in private class):

```csharp
public class CircleData {
    private double radius;
    private Color color;
    private Point origin;

    public CircleData(double radius, Color color, Point origin) {
        this.radius = radius;
        this.color = color;
        this.origin = origin;
    }

    public double Radius {
        get { return this.radius; }
    }

    public Color Color {
        get { return this.color; }
    }

    public Point Origin {
        get { return this.origin; }
    }
}

public class Circle {
    private CircleData circleData;

    public Circle(double radius, Color color, Point origin) {
        this.circleData = new CircleData(radius, color, origin);
    }

    public double Circumference {
        get { return this.circleData.Radius * Math.PI; }
    }

    public double Diameter {
        get { return this.circleData.Radius * 2; }
    }

    public void Draw(Graphics graphics) {
        //...
    }
}
```

### Python

```python
class DataClass:
    """
    Hide all the attributes.
    Uses Python descriptor protocol to enforce write-once semantics.
    """

    def __init__(self):
        self.value = None

    def __get__(self, instance, owner):
        return self.value

    def __set__(self, instance, value):
        if self.value is None:
            self.value = value


class MainClass:
    """
    Initialize data class through the data class's constructor.
    """

    attribute = DataClass()

    def __init__(self, value):
        self.attribute = value


def main():
    m = MainClass(True)
    m.attribute = False  # This assignment is silently ignored (write-once)


if __name__ == "__main__":
    main()
```

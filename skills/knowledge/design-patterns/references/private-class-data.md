## Overview

The Private Class Data pattern is a structural design pattern that safeguards object state by wrapping class attributes inside a dedicated, immutable data holder. Once the object is constructed, its data cannot be changed, which prevents unintended modifications and enforces consistency throughout the object's lifetime.

## Intent

- Isolate an object's data from its behavior into a distinct holder
- Restrict mutation of class fields after construction
- Guarantee post-initialization immutability
- Lower complexity by confining data management to a single place
- Preserve internal state integrity

## Problem/Solution

**Problem:**
Complex objects often expose mutable fields, which makes it possible for any part of the codebase to alter critical data after the object has been created. This leads to unpredictable state, unclear contracts, and tight coupling between the object and anything that touches its internals.

**Solution:**
Introduce a dedicated data holder class that stores all relevant attributes. The main class receives this holder at construction time and exposes only read access. Because the holder is immutable, no external code can tamper with the data once the object exists. This approach delivers:

- A clean boundary between what an object knows and what it does
- Strong immutability guarantees from the moment of creation
- Predictable, read-only data access
- A simpler main class that focuses on behavior

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

- **Immutable Objects**: When objects must not change after they are built
- **Complex Data**: When several related attributes should be frozen as a unit
- **Value Objects**: For objects representing data values rather than mutable entities
- **Thread Safety**: When concurrent access demands that shared data never changes
- **Framework Integration**: When configuration objects consumed by frameworks must remain stable
- **Data Integrity**: When specific field combinations must stay consistent for the object's entire life

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

**Passport/ID Document**: After a passport is issued, the data printed in it - name, number, expiry - cannot be edited. You carry it and present it, but modifying it requires issuing an entirely new document.

**Birth Certificate**: The facts recorded at birth are permanent. Institutions reference the certificate but have no ability to alter its contents.

**Configuration File**: Once application settings are loaded into memory, they typically become read-only. Every component reads from the same snapshot, ensuring uniform behavior across the system.

## Pros and Cons

### Advantages
- **Immutability**: Ensures data remains unchanged after the object is created
- **Thread Safety**: Immutable data eliminates race conditions by design
- **Predictability**: No part of the system can mutate the object's state unexpectedly
- **Clear Contracts**: The read-only nature of data is immediately obvious
- **Fewer Bugs**: Removes an entire category of defects caused by accidental mutation
- **Testability**: Immutable objects are straightforward to construct and verify

### Disadvantages
- **Up-front Initialization**: Every field must be supplied at construction time
- **No In-place Updates**: Changing a single value requires building a new instance
- **Memory Cost**: Frequent updates may produce many short-lived objects
- **Adoption Effort**: Teams unfamiliar with immutability patterns need onboarding
- **Extra Classes**: The separate data holder adds structural verbosity
- **Refactoring Overhead**: Altering the data shape means touching both the holder and the main class

## Relations with Other Patterns

**Value Object**: Private Class Data pairs naturally with Value Objects to produce fully immutable data carriers.

**Immutable Object**: This pattern is one concrete way to achieve the broader Immutable Object principle through composition.

**Builder Pattern**: Builders are often used alongside this pattern to validate and assemble complex data holders step by step.

**Adapter Pattern**: A data holder can serve as a bridge between external data formats and the internal representation the main class expects.

**Repository Pattern**: Repositories frequently return data holder instances as immutable transfer objects to calling code.

**Snapshot Pattern**: Conceptually related, though the Snapshot pattern focuses on capturing an object's state at a particular moment rather than enforcing permanent immutability.

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

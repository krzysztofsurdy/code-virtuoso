## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem/Solution](#problemsolution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+ strict types)](#implementation-php-83-strict-types)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Private Class Data is a structural design pattern that protects object state by moving class attributes into a dedicated, immutable data holder. After construction the data cannot be changed, which prevents accidental modification for the object's whole lifetime.

## Intent

- Separate an object's data from its behavior by putting the data in its own holder
- Restrict mutation of class fields after construction
- Guarantee immutability after initialization
- Reduce complexity by keeping data management in one place
- Keep internal state consistent

## Problem/Solution

**Problem:**
Complex objects often expose mutable fields, so any part of the codebase can change critical data after the object is created. The result is unpredictable state, unclear contracts, and tight coupling between the object and everything that touches its internals.

**Solution:**
Create a data holder class that stores all the relevant attributes. The main class receives the holder at construction time and exposes only read access. Because the holder is immutable, no outside code can alter the data once the object exists. This gives you:

- A clear boundary between what an object knows and what it does
- Immutability from the moment of creation
- Read-only data access
- A simpler main class that only holds behavior

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

## When to use

- **Immutable objects**: when objects must not change after they are built
- **Complex data**: when several related attributes should be frozen as a unit
- **Value objects**: for objects that represent data values rather than mutable entities
- **Thread safety**: when concurrent access requires that shared data never changes
- **Framework integration**: when configuration objects consumed by frameworks must stay stable
- **Data integrity**: when specific field combinations must stay consistent for the object's entire life

## Implementation (PHP 8.3+ strict types)

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

## Real-world analogies

**Passport/ID document**: Once a passport is issued, the data printed in it (name, number, expiry) cannot be edited. You carry it and present it, but changing it means issuing a new document.

**Birth certificate**: The facts recorded at birth are permanent. Institutions refer to the certificate but cannot alter it.

**Configuration file**: Once application settings are loaded into memory, they usually become read-only. Every component reads the same snapshot, so behavior is uniform across the system.

## Pros and cons

### Advantages
- **Immutability**: data stays unchanged after the object is created
- **Thread safety**: immutable data cannot cause race conditions
- **Predictability**: no part of the system can change the object's state unexpectedly
- **Clear contracts**: the read-only nature of the data is obvious
- **Fewer bugs**: removes a whole category of defects caused by accidental mutation
- **Testability**: immutable objects are easy to construct and verify

### Disadvantages
- **Up-front initialization**: every field must be supplied at construction time
- **No in-place updates**: changing a single value means building a new instance
- **Memory cost**: frequent updates can produce many short-lived objects
- **Adoption effort**: teams unfamiliar with immutability need some onboarding
- **Extra classes**: the separate data holder adds boilerplate
- **Refactoring overhead**: changing the data shape means touching both the holder and the main class

## Relations with other patterns

**Value Object**: Private Class Data combines well with Value Objects to produce fully immutable data carriers.

**Immutable Object**: This pattern is one way to get an Immutable Object through composition.

**Builder**: Builders are often used with this pattern to validate and assemble complex data holders step by step.

**Adapter**: A data holder can bridge external data formats and the internal representation the main class expects.

**Repository**: Repositories often return data holder instances as immutable transfer objects.

**Snapshot**: Related, but Snapshot captures an object's state at a point in time and does not enforce permanent immutability.

## Examples in other languages

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

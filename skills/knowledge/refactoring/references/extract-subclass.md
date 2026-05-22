# Extract Subclass Refactoring

## Overview

Extract Subclass moves special-case fields and methods out of a general-purpose class and into a dedicated subclass. When a class carries features that only matter in certain scenarios, those features belong in a subclass that represents that specific variation.

## Motivation

As classes grow, they often accumulate fields and methods that apply only to a subset of their instances. Leaving this special-case logic in the parent class:

- Forces all instances to carry fields they do not use
- Obscures the distinction between general and specialized behavior
- Makes the parent class harder to understand and test
- Limits the ability to add further variations cleanly

Extracting a subclass sharpens both the parent and the child, giving each a clear and focused purpose.

## Mechanics

1. Create a new subclass from the parent class
2. Move the specialized fields and methods into the subclass
3. Remove the specialized code from the parent
4. Update creation sites to instantiate the subclass where the special behavior is needed
5. Run the tests to confirm behavior is preserved

## Before/After Examples

### Before: Employee Class with Manager-Specific Logic

```php
<?php
declare(strict_types=1);

class Employee
{
    public function __construct(
        private string $name,
        private float $salary,
        private ?string $managedDepartment = null,
        private float $responsibilityBonus = 0.0,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }

    public function getManagedDepartment(): ?string
    {
        return $this->managedDepartment;
    }

    public function getResponsibilityBonus(): float
    {
        return $this->responsibilityBonus;
    }

    public function setManagedDepartment(string $department): void
    {
        $this->managedDepartment = $department;
    }

    public function setResponsibilityBonus(float $bonus): void
    {
        $this->responsibilityBonus = $bonus;
    }
}
```

### After: Separate Manager Subclass

```php
<?php
declare(strict_types=1);

class Employee
{
    public function __construct(
        private readonly string $name,
        private readonly float $salary,
    ) {}

    public function getName(): string
    {
        return $this->name;
    }

    public function getSalary(): float
    {
        return $this->salary;
    }
}

class Manager extends Employee
{
    public function __construct(
        string $name,
        float $salary,
        private readonly string $managedDepartment,
        private readonly float $responsibilityBonus = 0.0,
    ) {
        parent::__construct($name, $salary);
    }

    public function getManagedDepartment(): string
    {
        return $this->managedDepartment;
    }

    public function getResponsibilityBonus(): float
    {
        return $this->responsibilityBonus;
    }
}

// Usage
$employee = new Employee('Alice', 50000);
$manager = new Manager('Bob', 75000, 'Engineering', 5000);
```

## Benefits

- **Lighter Parent Class**: The parent sheds fields and methods that only mattered to the special case
- **Explicit Variation**: A dedicated subclass makes the distinction between general and specialized behavior unmistakable
- **Type Safety**: PHP 8.3 readonly properties on the subclass enforce immutability and provide clarity
- **Extensibility**: Additional variations can be introduced as further subclasses without bloating the parent
- **Focused Responsibility**: Each class has a single, well-defined reason to change

## When NOT to Use

- **Multiple orthogonal dimensions**: If the class varies along two or more independent axes (e.g., role AND employment type), composition or the Strategy pattern is a better fit than inheritance
- **Shallow difference**: When the subclass would add only a trivial field and no meaningful behavior, the complexity of a new class may not be justified
- **Deep inheritance chains**: Avoid creating subclasses that extend already-deep hierarchies

## Related Refactorings

- **Pull Up Method**: Move shared methods from the subclass back into the parent
- **Push Down Method**: Move specialized methods from the parent into the subclass
- **Extract Superclass**: The reverse direction - creating a shared parent for classes that already exist
- **Replace Type Code with Subclasses**: Use subclasses to replace a type field and its conditional logic
- **Replace Conditional with Polymorphism**: Eliminate conditionals by distributing behavior across subclasses

## Examples in Other Languages

### Java

**Before:**

```java
class JobItem {
    private int unitPrice;
    private int quantity;
    private boolean isLabor;
    private Employee employee;

    int getTotalPrice() {
        return getUnitPrice() * quantity;
    }

    int getUnitPrice() {
        return isLabor ? employee.getRate() : unitPrice;
    }

    Employee getEmployee() {
        return employee;
    }
}
```

**After:**

```java
class JobItem {
    private int unitPrice;
    private int quantity;

    int getTotalPrice() {
        return getUnitPrice() * quantity;
    }

    int getUnitPrice() {
        return unitPrice;
    }
}

class LaborItem extends JobItem {
    private Employee employee;

    int getUnitPrice() {
        return employee.getRate();
    }

    Employee getEmployee() {
        return employee;
    }
}
```

### C#

**Before:**

```csharp
class JobItem
{
    private int unitPrice;
    private int quantity;
    private bool isLabor;
    private Employee employee;

    int GetTotalPrice()
    {
        return GetUnitPrice() * quantity;
    }

    int GetUnitPrice()
    {
        return isLabor ? employee.GetRate() : unitPrice;
    }
}
```

**After:**

```csharp
class JobItem
{
    private int unitPrice;
    private int quantity;

    int GetTotalPrice()
    {
        return GetUnitPrice() * quantity;
    }

    virtual int GetUnitPrice()
    {
        return unitPrice;
    }
}

class LaborItem : JobItem
{
    private Employee employee;

    override int GetUnitPrice()
    {
        return employee.GetRate();
    }
}
```

### Python

**Before:**

```python
class JobItem:
    def __init__(self, unit_price: int, quantity: int,
                 is_labor: bool, employee: Employee = None):
        self.unit_price = unit_price
        self.quantity = quantity
        self.is_labor = is_labor
        self.employee = employee

    def get_total_price(self) -> int:
        return self.get_unit_price() * self.quantity

    def get_unit_price(self) -> int:
        if self.is_labor:
            return self.employee.get_rate()
        return self.unit_price
```

**After:**

```python
class JobItem:
    def __init__(self, unit_price: int, quantity: int):
        self.unit_price = unit_price
        self.quantity = quantity

    def get_total_price(self) -> int:
        return self.get_unit_price() * self.quantity

    def get_unit_price(self) -> int:
        return self.unit_price

class LaborItem(JobItem):
    def __init__(self, quantity: int, employee: Employee):
        super().__init__(0, quantity)
        self.employee = employee

    def get_unit_price(self) -> int:
        return self.employee.get_rate()
```

### TypeScript

**Before:**

```typescript
class JobItem {
    private unitPrice: number;
    private quantity: number;
    private isLabor: boolean;
    private employee: Employee;

    getTotalPrice(): number {
        return this.getUnitPrice() * this.quantity;
    }

    getUnitPrice(): number {
        return this.isLabor ? this.employee.getRate() : this.unitPrice;
    }
}
```

**After:**

```typescript
class JobItem {
    constructor(
        private unitPrice: number,
        private quantity: number,
    ) {}

    getTotalPrice(): number {
        return this.getUnitPrice() * this.quantity;
    }

    getUnitPrice(): number {
        return this.unitPrice;
    }
}

class LaborItem extends JobItem {
    constructor(
        quantity: number,
        private employee: Employee,
    ) {
        super(0, quantity);
    }

    getUnitPrice(): number {
        return this.employee.getRate();
    }
}
```

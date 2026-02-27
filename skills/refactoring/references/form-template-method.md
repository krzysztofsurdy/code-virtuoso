# Form Template Method

## Overview

Form Template Method is a refactoring technique that eliminates code duplication occurring at the algorithmic level. When multiple classes implement similar algorithms that differ only in specific steps, you extract the common algorithm structure into a base class as a template method, leaving implementation details to subclasses.

This addresses high-level duplication that extends beyond simple copy-paste scenarios and strengthens adherence to the Open/Closed Principle.

## Motivation

Code duplication occurs at different levels. Sometimes it's copying identical code blocks; other times it's similar algorithms that differ only in comparison logic or processing steps. The latter type often goes unnoticed but creates significant maintenance issues.

When changes to the algorithm structure are needed, you must modify every subclass that implements it. The Form Template Method consolidates this shared logic, making the codebase easier to maintain and extend.

## Mechanics

The refactoring process follows these steps:

1. **Extract Method** - Break down the algorithm in each subclass into discrete, named methods
2. **Pull Up Identical Methods** - Move methods that are identical across subclasses to the base class
3. **Standardize Method Names** - Rename methods so similar steps have consistent names across subclasses
4. **Pull Up Abstract Method Signatures** - Define abstract methods in the base class for steps that vary
5. **Move Template Method** - Move the main algorithm orchestration to the base class where it calls both concrete and abstract methods

## Before/After

### Before

Multiple subclasses implement similar CSV and JSON export processes with duplicated algorithm structure:

```php
<?php

declare(strict_types=1);

class CSVExporter
{
    public function export(array $data): string
    {
        $lines = [];
        $lines[] = $this->buildHeader($data);

        foreach ($data as $record) {
            $lines[] = $this->buildRecord($record);
        }

        return implode("\n", $lines);
    }

    private function buildHeader(array $data): string
    {
        return implode(',', array_keys($data[0]));
    }

    private function buildRecord(array $record): string
    {
        return implode(',', array_values($record));
    }
}

class JSONExporter
{
    public function export(array $data): string
    {
        $lines = [];
        $lines[] = $this->buildHeader($data);

        foreach ($data as $record) {
            $lines[] = $this->buildRecord($record);
        }

        return implode("\n", $lines);
    }

    private function buildHeader(array $data): string
    {
        return json_encode(['columns' => array_keys($data[0])]);
    }

    private function buildRecord(array $record): string
    {
        return json_encode($record);
    }
}
```

### After

Common algorithm consolidated into base template method:

```php
<?php

declare(strict_types=1);

abstract readonly class Exporter
{
    abstract protected function buildHeader(array $data): string;
    abstract protected function buildRecord(array $record): string;

    public function export(array $data): string
    {
        $lines = [];
        $lines[] = $this->buildHeader($data);

        foreach ($data as $record) {
            $lines[] = $this->buildRecord($record);
        }

        return implode("\n", $lines);
    }
}

final readonly class CSVExporter extends Exporter
{
    protected function buildHeader(array $data): string
    {
        return implode(',', array_keys($data[0]));
    }

    protected function buildRecord(array $record): string
    {
        return implode(',', array_values($record));
    }
}

final readonly class JSONExporter extends Exporter
{
    protected function buildHeader(array $data): string
    {
        return json_encode(['columns' => array_keys($data[0])]);
    }

    protected function buildRecord(array $record): string
    {
        return json_encode($record);
    }
}
```

## Benefits

- **Eliminates Algorithmic Duplication** - Removes duplicate algorithm structure that extends beyond simple copy-paste
- **Single Point of Change** - Modify the algorithm once in the base class instead of updating every subclass
- **Supports Open/Closed Principle** - New algorithm variations require only new subclasses; existing code stays unchanged
- **Improves Code Clarity** - The template method makes the algorithm's structure explicit and easy to understand
- **Easier Testing** - Test the template logic once; focus subclass tests on specific implementations

## When NOT to Use

- **Trivial Algorithms** - If the shared algorithm is very simple, the abstraction overhead may outweigh benefits
- **Fundamentally Different Implementations** - When subclasses have completely different approaches, forcing them into a template creates artificial constraints
- **Single Implementation** - If only one class currently uses the algorithm, defer this refactoring until duplication actually occurs
- **Dynamic Behavior Changes** - When algorithm steps need to be swapped or reordered at runtime, consider Strategy pattern instead

## Related Refactorings

- **Strategy Pattern** - Use when algorithm variations need to be selected at runtime rather than via inheritance
- **Extract Method** - Often a prerequisite step to identify discrete algorithm steps
- **Pull Up Method** - Used to move identical methods to the base class during this refactoring
- **Template Method Design Pattern** - The pattern this refactoring helps implement

## Examples in Other Languages

### Java

**Before:**

```java
class ResidentialSite {
    double getBillableAmount() {
        double base = units * rate;
        double tax = base * Site.TAX_RATE;
        return base + tax;
    }
}

class LifelineSite {
    double getBillableAmount() {
        double base = units * rate * 0.5;
        double tax = base * Site.TAX_RATE * 0.2;
        return base + tax;
    }
}
```

**After:**

```java
abstract class Site {
    double getBillableAmount() {
        return getBaseAmount() + getTaxAmount();
    }

    abstract double getBaseAmount();
    abstract double getTaxAmount();
}

class ResidentialSite extends Site {
    double getBaseAmount() { return units * rate; }
    double getTaxAmount() { return getBaseAmount() * TAX_RATE; }
}

class LifelineSite extends Site {
    double getBaseAmount() { return units * rate * 0.5; }
    double getTaxAmount() { return getBaseAmount() * TAX_RATE * 0.2; }
}
```

### C#

**Before:**

```csharp
class ResidentialSite
{
    double GetBillableAmount()
    {
        double baseAmount = units * rate;
        double tax = baseAmount * Site.TaxRate;
        return baseAmount + tax;
    }
}

class LifelineSite
{
    double GetBillableAmount()
    {
        double baseAmount = units * rate * 0.5;
        double tax = baseAmount * Site.TaxRate * 0.2;
        return baseAmount + tax;
    }
}
```

**After:**

```csharp
abstract class Site
{
    double GetBillableAmount()
    {
        return GetBaseAmount() + GetTaxAmount();
    }

    abstract double GetBaseAmount();
    abstract double GetTaxAmount();
}

class ResidentialSite : Site
{
    override double GetBaseAmount() => units * rate;
    override double GetTaxAmount() => GetBaseAmount() * TaxRate;
}

class LifelineSite : Site
{
    override double GetBaseAmount() => units * rate * 0.5;
    override double GetTaxAmount() => GetBaseAmount() * TaxRate * 0.2;
}
```

### Python

**Before:**

```python
class ResidentialSite:
    def get_billable_amount(self) -> float:
        base = self.units * self.rate
        tax = base * self.TAX_RATE
        return base + tax

class LifelineSite:
    def get_billable_amount(self) -> float:
        base = self.units * self.rate * 0.5
        tax = base * self.TAX_RATE * 0.2
        return base + tax
```

**After:**

```python
from abc import ABC, abstractmethod

class Site(ABC):
    def get_billable_amount(self) -> float:
        return self.get_base_amount() + self.get_tax_amount()

    @abstractmethod
    def get_base_amount(self) -> float:
        pass

    @abstractmethod
    def get_tax_amount(self) -> float:
        pass

class ResidentialSite(Site):
    def get_base_amount(self) -> float:
        return self.units * self.rate

    def get_tax_amount(self) -> float:
        return self.get_base_amount() * self.TAX_RATE

class LifelineSite(Site):
    def get_base_amount(self) -> float:
        return self.units * self.rate * 0.5

    def get_tax_amount(self) -> float:
        return self.get_base_amount() * self.TAX_RATE * 0.2
```

### TypeScript

**Before:**

```typescript
class ResidentialSite {
    getBillableAmount(): number {
        const base = this.units * this.rate;
        const tax = base * Site.TAX_RATE;
        return base + tax;
    }
}

class LifelineSite {
    getBillableAmount(): number {
        const base = this.units * this.rate * 0.5;
        const tax = base * Site.TAX_RATE * 0.2;
        return base + tax;
    }
}
```

**After:**

```typescript
abstract class Site {
    getBillableAmount(): number {
        return this.getBaseAmount() + this.getTaxAmount();
    }

    abstract getBaseAmount(): number;
    abstract getTaxAmount(): number;
}

class ResidentialSite extends Site {
    getBaseAmount(): number { return this.units * this.rate; }
    getTaxAmount(): number { return this.getBaseAmount() * Site.TAX_RATE; }
}

class LifelineSite extends Site {
    getBaseAmount(): number { return this.units * this.rate * 0.5; }
    getTaxAmount(): number { return this.getBaseAmount() * Site.TAX_RATE * 0.2; }
}
```

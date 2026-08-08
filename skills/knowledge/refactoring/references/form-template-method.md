# Form Template Method

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after](#before-and-after)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Form Template Method removes duplication at the algorithm level instead of the code-block level. When several classes implement the same overall algorithm but differ in specific steps, you extract the shared skeleton into a base class method and let subclasses supply the varying steps.

It supports the Open/Closed Principle: a new algorithm variant needs only a new subclass, with no changes to existing code.

## Motivation

Not all duplication is obvious copy-paste. Sometimes two classes follow the same sequence of steps (initialize, process, finalize) but each step is implemented a little differently. This structural duplication is harder to spot but just as costly. Every change to the algorithm flow must be repeated in each class that implements it.

Moving the flow into a single template method removes that risk and puts the algorithm's structure in one visible place.

## Mechanics

1. **Break the algorithm into steps** - use Extract Method in each subclass to isolate individual steps
2. **Identify identical steps** - move methods that are the same in every subclass up to the base class
3. **Unify naming** - rename steps so that corresponding methods share the same name across subclasses
4. **Declare abstract methods** - define abstract method signatures in the base class for steps that vary
5. **Move the algorithm** - place the template method in the base class, calling both concrete and abstract step methods

## Before and after

### Before

Two exporters implement the same export process with a duplicated algorithm structure:

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

The common algorithm moves into a base template method:

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

- **Centralized algorithm structure** - the flow is defined once in the base class, not repeated in every subclass
- **Single edit point** - changes to the algorithm sequence happen in one place
- **Open/Closed compliance** - adding a new format means adding a subclass, not modifying existing ones
- **Visible structure** - the template method shows the algorithm's shape at a glance
- **Focused subclass tests** - test the flow once in the base; test only the varying steps in each subclass

## When not to use

- **Simple algorithms** - if the shared structure is trivial, the abstraction costs more than it saves
- **Radically different implementations** - when subclasses do not share a common sequence, forcing a template adds artificial constraints
- **Single implementation** - delay this refactoring until duplication appears in a second class
- **Runtime flexibility needed** - if the algorithm steps must be swapped or reordered dynamically, the Strategy pattern is a better choice

## Related refactorings

- **Strategy Pattern** - preferred when algorithm selection happens at runtime rather than through inheritance
- **Extract Method** - a prerequisite step for identifying the discrete steps of the algorithm
- **Pull Up Method** - used to move identical step methods into the base class
- **Template Method Design Pattern** - the design pattern this refactoring produces

## Examples in other languages

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

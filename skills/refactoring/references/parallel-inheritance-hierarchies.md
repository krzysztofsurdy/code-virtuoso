# Parallel Inheritance Hierarchies

## Overview

Parallel Inheritance Hierarchies is a code smell where you maintain multiple class hierarchies that mirror each other's structure. Whenever you need to create a subclass in one hierarchy, you find yourself creating a matching subclass in another hierarchy. This creates unnecessary duplication and tight coupling between seemingly independent class structures.

## Why It's a Problem

Parallel hierarchies increase maintenance burden as changes must be propagated across multiple structures. The dependencies between hierarchies become implicit and fragile, making code harder to understand and modify. As both hierarchies grow, the duplication becomes increasingly difficult to manage and increases the risk of inconsistencies.

## Signs and Symptoms

- Creating a new subclass in one hierarchy forces you to create a corresponding subclass in another
- Class hierarchies grow in lockstep with identical or very similar structures
- Multiple abstract base classes with mirrored method signatures
- Changes to one hierarchy's structure require parallel changes elsewhere
- High cohesion between nominally independent class hierarchies

## Before/After Examples

**Before: Parallel Hierarchies**

```php
<?php
declare(strict_types=1);

abstract class ReportGenerator
{
    abstract public function generate(): string;
}

class PDFReportGenerator extends ReportGenerator
{
    public function generate(): string
    {
        return "Generating PDF...";
    }
}

class HTMLReportGenerator extends ReportGenerator
{
    public function generate(): string
    {
        return "Generating HTML...";
    }
}

// Parallel hierarchy - mirrors ReportGenerator
abstract class ReportExporter
{
    abstract public function export(): string;
}

class PDFReportExporter extends ReportExporter
{
    public function export(): string
    {
        return "Exporting to PDF...";
    }
}

class HTMLReportExporter extends ReportExporter
{
    public function export(): string
    {
        return "Exporting to HTML...";
    }
}
```

**After: Using Composition**

```php
<?php
declare(strict_types=1);

readonly class Report
{
    public function __construct(
        private ReportFormatter $formatter,
    ) {}

    public function generate(): string
    {
        return $this->formatter->format();
    }

    public function export(): string
    {
        return $this->formatter->export();
    }
}

interface ReportFormatter
{
    public function format(): string;
    public function export(): string;
}

readonly class PDFFormatter implements ReportFormatter
{
    public function format(): string
    {
        return "Generating PDF...";
    }

    public function export(): string
    {
        return "Exporting to PDF...";
    }
}

readonly class HTMLFormatter implements ReportFormatter
{
    public function format(): string
    {
        return "Generating HTML...";
    }

    public function export(): string
    {
        return "Exporting to HTML...";
    }
}
```

## Recommended Refactorings

**1. Create References (Composition)**
Replace inheritance relationships with composition by injecting instances of one hierarchy into the other. This decouples the structures and eliminates the need to maintain parallel subclasses.

**2. Move Methods and Fields**
Extract common behavior into shared classes that both hierarchies can use. Use Move Method and Move Field techniques to consolidate functionality.

**3. Use Strategy Pattern**
Replace parallel hierarchies with a single class that delegates to strategy implementations. This simplifies the class structure significantly.

**4. Apply Decorator Pattern**
When parallel hierarchies represent different concerns (e.g., export format vs. report type), use decorators to compose behaviors independently.

## Exceptions

- **True Parallel Requirements**: If two domains genuinely require parallel structures with different evolution paths, maintaining them may be acceptable.
- **Legacy Systems**: Complete refactoring may be impractical; consider gradual migration using adapters.
- **Performance-Critical Code**: In rare cases, explicit hierarchies may outperform composition; benchmark before refactoring.

## Related Smells

- **Duplicate Code**: Parallel hierarchies are a manifestation of systematic duplication across multiple classes.
- **Feature Envy**: When methods in one hierarchy frequently reference another hierarchy's structure.
- **God Class**: Parallel hierarchies sometimes emerge when a single domain concept is split incorrectly.
- **Middle Man**: Composition can introduce unnecessary delegation if not designed carefully.

## Refactoring.guru Guidance

### Signs and Symptoms
Whenever you create a subclass for a class, you find yourself needing to create a subclass for another class. Class hierarchies grow in tandem, creating unnecessary structural coupling.

### Reasons for the Problem
While small hierarchies pose no issues, problems emerge as new classes accumulate. The difficulty in implementing changes increases proportionally with hierarchy expansion.

### Treatment
- First, establish references between instances of one hierarchy to instances of another
- Then eliminate the redundant hierarchy by employing **Move Method** and **Move Field** refactoring techniques

### Payoff
- Reduces code duplication
- Can improve overall code organization and structure

Note: If deduplication attempts produce messier code, abandoning the refactoring may be the pragmatic choice.

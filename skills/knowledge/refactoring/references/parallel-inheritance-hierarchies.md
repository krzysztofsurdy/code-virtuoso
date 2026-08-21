# Parallel Inheritance Hierarchies

Parallel Inheritance Hierarchies appear when two or more class hierarchies mirror each other. Adding a subclass to one hierarchy forces you to add a matching subclass to the other. This is a small annoyance at first. As the hierarchies grow, it becomes systematic duplication and fragile coupling between structures that should be independent.

## Contents

- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after examples](#before-and-after-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Why it's a problem

Every new class in one hierarchy needs a matching class in the other, which doubles the maintenance effort. The hidden dependencies between the two structures are easy to miss and hard to keep in sync. As the hierarchies grow, inconsistencies become more likely and the whole picture is harder to understand. Refactoring one hierarchy without breaking the other gets harder over time.

## Signs and symptoms

- Adding a subclass in one hierarchy always requires a matching subclass elsewhere
- Two hierarchies grow together with nearly identical structures
- Abstract base classes in separate hierarchies have mirrored method signatures
- Structural changes in one hierarchy force matching changes in the other
- Strong coupling between hierarchies that are supposed to be independent

## Before and after examples

**Before: parallel hierarchies**

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

**After: using composition**

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

## Recommended refactorings

**1. Create references (composition)**
Replace inheritance with composition by injecting instances of one hierarchy into the other. This decouples the structures and removes the need to maintain parallel subclasses.

**2. Move Method and Move Field**
Extract common behavior into shared classes that both hierarchies can use. Use Move Method and Move Field to consolidate it.

**3. Use the Strategy pattern**
Replace the parallel hierarchies with one class that delegates to strategy implementations. This simplifies the class structure.

**4. Apply the Decorator pattern**
When the hierarchies represent different concerns (e.g., export format and report type), use decorators to compose behaviors independently.

## Exceptions

- **True parallel requirements**: if two domains need parallel structures that evolve differently, keeping them may be acceptable.
- **Legacy systems**: a full refactoring may be impractical. Consider a gradual migration using adapters.
- **Performance-critical code**: in rare cases, explicit hierarchies may outperform composition. Benchmark before refactoring.

## Related smells

- **Duplicate Code**: parallel hierarchies are a structural form of duplication spread across several classes.
- **Feature Envy**: methods in one hierarchy that keep referencing the other hierarchy's data suggest the logic belongs elsewhere.
- **God Class**: parallel hierarchies sometimes come from wrongly splitting a single domain concept.
- **Middle Man**: consolidating with composition can add pointless delegation if the design is careless.

Small parallel hierarchies may cause little pain, but the cost grows with each new subclass pair. If consolidating them produces messier code than the duplication, leaving them as they are can be the practical choice.

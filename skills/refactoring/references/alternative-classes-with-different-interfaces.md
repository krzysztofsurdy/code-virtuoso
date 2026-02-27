# Alternative Classes with Different Interfaces

## Overview

This code smell occurs when two or more classes perform identical functions but expose different method names and signatures. It typically results from developers being unaware that functionally equivalent classes already exist in the codebase, leading to unnecessary duplication and inconsistent APIs.

## Why It's a Problem

- **Code Duplication**: Multiple implementations of the same logic increase maintenance burden
- **Inconsistent API**: Different method names for identical operations confuse users and reduce intuitiveness
- **Cognitive Load**: Developers must understand why multiple implementations exist
- **Maintenance Nightmare**: Changes must be applied to multiple locations, risking bugs and inconsistencies
- **Testing Overhead**: More code to test and maintain without functional benefit

## Signs and Symptoms

- Classes with identical functionality but different method names
- Similar algorithms implemented multiple times with slight variations
- Developers wondering which class to use for a particular operation
- Documentation explaining differences between functionally equivalent classes
- Similar logic scattered across codebase with different naming conventions

## Before/After

### Before: Inconsistent Interfaces

```php
<?php

declare(strict_types=1);

class XMLExporter
{
    public function exportToXml(object $data): string
    {
        return '<root>' . json_encode($data) . '</root>';
    }
}

class JsonSerializer
{
    public function serialize(object $data): string
    {
        return json_encode($data);
    }
}

class CSVFormatter
{
    public function formatAsCSV(object $data): string
    {
        return implode(',', (array) $data);
    }
}
```

### After: Unified Interface

```php
<?php

declare(strict_types=1);

enum ExportFormat
{
    case XML;
    case JSON;
    case CSV;
}

interface DataExporter
{
    public function export(object $data): string;
}

readonly class XMLExporter implements DataExporter
{
    public function export(object $data): string
    {
        return '<root>' . json_encode($data) . '</root>';
    }
}

readonly class JsonExporter implements DataExporter
{
    public function export(object $data): string
    {
        return json_encode($data);
    }
}

readonly class CSVExporter implements DataExporter
{
    public function export(object $data): string
    {
        return implode(',', (array) $data);
    }
}
```

## Recommended Refactorings

### 1. Extract Common Interface
Create a shared interface that all related classes implement, standardizing method signatures and making intent explicit.

### 2. Rename Methods
If unifying under one interface, rename methods to provide consistent naming across all implementations. Prefer semantic names like `export()`, `serialize()`, or `transform()` based on purpose.

### 3. Use Enums for Variants
When dealing with multiple implementations of the same behavior, use PHP enums to explicitly define variants and make selections type-safe.

### 4. Consolidate with Factory Pattern
Implement a factory that instantiates the correct class, allowing clients to request formatters by type rather than knowing specific class names.

```php
<?php

declare(strict_types=1);

readonly class ExporterFactory
{
    public function create(ExportFormat $format): DataExporter
    {
        return match ($format) {
            ExportFormat::XML => new XMLExporter(),
            ExportFormat::JSON => new JsonExporter(),
            ExportFormat::CSV => new CSVExporter(),
        };
    }
}
```

### 5. Extract Superclass
If only partial functionality overlaps, extract a readonly base class with shared logic and let subclasses override specific methods.

## Exceptions

### When It's Acceptable

- **Third-party Classes**: When integrating external libraries with different APIs, creating adapter classes is appropriate
- **Intentional Variation**: When different interfaces serve fundamentally different use cases (not just naming differences)
- **Legacy System Integration**: Temporary adapters while migrating legacy code are acceptable
- **Domain-Specific Requirements**: When business logic demands genuinely different method names for semantic clarity in different contexts

## Related Smells

- **Duplicate Code**: Often appears alongside alternative classes
- **Data Clumps**: Multiple classes operating on similar data structures
- **Inappropriate Intimacy**: Classes may be too similar to remain separate
- **Lazy Class**: One of the alternatives may be truly unnecessary

## Refactoring.guru Guidance

### Signs and Symptoms
Two classes perform identical functions but have different method names.

### Reasons for the Problem
The programmer who created one of the classes probably did not know that a functionally equivalent class already existed. This typically arises from insufficient communication between team members or lack of code review processes.

### Treatment
- **Rename Methods** to make them identical in all alternative classes
- **Move Method**, **Add Parameter**, and **Parameterize Method** to make the signature and implementation of methods the same
- **Extract Superclass** when only partial functionality is duplicated, converting existing classes into subclasses
- Delete one of the redundant classes after standardizing interfaces

### Payoff
- Eliminates unnecessary duplicated code, making the resulting code less bulky
- Code becomes more readable and understandable as developers no longer need to determine why duplicate classes exist

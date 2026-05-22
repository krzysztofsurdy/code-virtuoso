# Alternative Classes with Different Interfaces

## Overview

This smell arises when two or more classes do essentially the same thing but expose their functionality through different method names and signatures. It usually happens because a developer creates a new class without realizing that an equivalent one already exists - different naming conventions, different file locations, or simply lack of communication between team members. The result is redundant implementations behind inconsistent APIs.

## Why It's a Problem

- **Redundant Logic**: The same behavior is implemented multiple times, multiplying maintenance effort
- **Confusing API Surface**: Different method names for identical operations force users to guess which class to use
- **Cognitive Overhead**: Developers waste time determining whether functionally similar classes actually differ in behavior
- **Divergent Maintenance**: Bug fixes and enhancements must be applied to each copy, and missed copies introduce inconsistencies
- **Unnecessary Test Burden**: Each implementation requires its own test coverage despite providing no unique functionality

## Signs and Symptoms

- Classes with different method names that perform the same operation
- Nearly identical algorithms implemented independently with minor variations
- Developers unsure which class to choose for a given task
- Documentation that attempts to explain the distinction between functionally equivalent classes
- Similar logic appearing under different naming conventions in different parts of the codebase

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

- **Duplicate Code**: Naturally accompanies alternative classes, since each implements the same logic independently
- **Data Clumps**: Multiple classes operating on similar data structures often hints at a shared abstraction waiting to be extracted
- **Inappropriate Intimacy**: Classes that are too similar to justify existing separately
- **Lazy Class**: After unifying interfaces, one of the alternatives may turn out to be entirely redundant

The first step is standardizing the method names across all alternatives. Then use Move Method, Add Parameter, or Parameterize Method to align signatures and implementations. When only partial overlap exists, Extract Superclass lets both classes inherit shared behavior. Once the interfaces are unified, delete the redundant class - the codebase becomes smaller, more consistent, and easier to navigate.

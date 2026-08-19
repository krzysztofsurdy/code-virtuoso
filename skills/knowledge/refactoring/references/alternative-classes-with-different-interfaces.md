# Alternative Classes with Different Interfaces

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and Symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

This smell appears when two or more classes do the same thing but use different method names and signatures. It usually happens when a developer adds a class without knowing an equivalent one exists. Causes include different naming conventions, different file locations, or poor communication in the team. The result is redundant implementations behind inconsistent APIs.

## Why it's a problem

- **Redundant logic**: The same behavior is implemented multiple times, multiplying maintenance effort
- **Confusing API surface**: Different method names for identical operations force users to guess which class to use
- **Cognitive overhead**: Developers waste time working out whether similar classes actually differ in behavior
- **Divergent maintenance**: Bug fixes and enhancements must be applied to each copy, and missed copies introduce inconsistencies
- **Extra tests**: Each implementation needs its own test coverage even though it adds no unique functionality

## Signs and symptoms

- Classes with different method names that perform the same operation
- Nearly identical algorithms implemented independently with minor variations
- Developers unsure which class to choose for a given task
- Documentation that tries to explain the difference between functionally equivalent classes
- Similar logic appearing under different naming conventions in different parts of the codebase

## Before and after

### Before: inconsistent interfaces

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

### After: unified interface

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

## Recommended refactorings

### 1. Extract Interface
Create a shared interface that all related classes implement. It standardizes method signatures and makes intent explicit.

### 2. Rename Methods
When unifying under one interface, rename methods so naming is consistent across all implementations. Prefer names like `export()`, `serialize()`, or `transform()` based on purpose.

### 3. Use enums for variants
When several implementations share the same behavior, use PHP enums to define the variants explicitly and make selection type-safe.

### 4. Consolidate with a factory
Add a factory that instantiates the correct class, so clients request formatters by type instead of by class name.

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

### When it's acceptable

- **Third-party classes**: When integrating external libraries with different APIs, creating adapter classes is appropriate
- **Intentional variation**: The interfaces serve different use cases, not just different names
- **Legacy system integration**: Temporary adapters are acceptable while migrating legacy code
- **Domain-specific requirements**: The business logic calls for different method names in different contexts

## Related smells

- **Duplicate Code**: Often comes with alternative classes, since each implements the same logic on its own
- **Data Clumps**: Multiple classes operating on similar data structures often points to a shared abstraction that can be extracted
- **Inappropriate Intimacy**: Classes that are too similar to justify existing separately
- **Lazy Class**: After unifying interfaces, one of the alternatives may turn out to be entirely redundant

Start by standardizing the method names across all alternatives. Then use Move Method, Add Parameter, or Parameterize Method to align signatures and implementations. When only part of the functionality overlaps, Extract Superclass lets both classes inherit the shared behavior. Once the interfaces match, delete the redundant class.

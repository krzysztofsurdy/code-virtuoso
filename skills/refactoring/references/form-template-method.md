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

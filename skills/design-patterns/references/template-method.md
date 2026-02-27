## Overview

The Template Method pattern is a behavioral design pattern that defines the program skeleton of an algorithm in a base class but lets subclasses override specific steps without changing the algorithm's structure. It allows you to reuse the invariant parts of an algorithm and vary only the parts that change, reducing code duplication while maintaining control over the algorithm flow.

## Intent

- Define the skeleton of an algorithm in a method, deferring some steps to subclasses
- Let subclasses redefine certain steps of an algorithm without changing its structure
- Promote code reuse by extracting common algorithm structure into a base class
- Enforce a template that subclasses must follow
- Invert the control flow (Hollywood Principle: "Don't call us, we'll call you")

## Problem

In applications requiring similar algorithms with minor variations:
- Code duplication occurs when implementing similar algorithms in multiple classes
- Changing the algorithm structure requires modifications in many places
- It's unclear which parts of the algorithm are customizable vs. fixed
- Subclasses might implement algorithms inconsistently
- Business logic and framework logic become intertwined

## Solution

Extract the common algorithm structure into a base class as a template method. Define abstract or empty methods for the steps that vary. Subclasses implement these methods to provide specific behavior while the template method orchestrates the overall flow. This enforces consistency and promotes code reuse.

## Structure

```
┌─────────────────────┐
│   AbstractClass     │
├─────────────────────┤
│ + templateMethod()  │ (defines algorithm skeleton)
│ # primitiveOp1()    │ (abstract - to be overridden)
│ # primitiveOp2()    │ (abstract - to be overridden)
│ # primitiveOp3()    │ (hook method - optional override)
└──────────┬──────────┘
           ▲
           │ inherits
     ┌─────┴─────────────────────┐
     │                           │
┌────┴───────────────┐    ┌──────┴──────────────┐
│ ConcreteClassA     │    │ ConcreteClassB      │
├────────────────────┤    ├─────────────────────┤
│ # primitiveOp1()   │    │ # primitiveOp1()    │
│ # primitiveOp2()   │    │ # primitiveOp2()    │
│ # primitiveOp3()   │    │ # primitiveOp3()    │
└────────────────────┘    └─────────────────────┘
```

**Key Components:**
- **AbstractClass:** Defines the template method and abstract primitive operations
- **ConcreteClass:** Implements the abstract methods (primitive operations)
- **Hook Method:** Optional methods that subclasses may override (default behavior provided)
- **Template Method:** Controls the algorithm flow by calling primitive operations

## When to Use

- Implementing multiple algorithms with a similar structure
- Extracting common code from similar classes
- Framework design where framework controls the flow
- Algorithms with multiple variants (document processing, data export formats)
- Implementing lifecycle hooks (initialization, processing, cleanup)
- Data transformation pipelines with standard steps
- Test fixtures with setup/teardown patterns

## Implementation

### PHP 8.3+ Strict Types

```php
<?php

declare(strict_types=1);

namespace DesignPatterns\TemplateMethod;

/**
 * Abstract base class defining the template algorithm skeleton
 */
abstract class DataProcessor
{
    /**
     * Template Method - defines the algorithm structure
     * This method is the template that subclasses follow
     */
    final public function process(string $data): string
    {
        // Step 1: Validate input
        $this->validate($data);

        // Step 2: Transform data
        $transformed = $this->transform($data);

        // Step 3: Optional hook - before export
        $this->beforeExport($transformed);

        // Step 4: Export/Format result
        $result = $this->export($transformed);

        // Step 5: Optional hook - after export
        $this->afterExport($result);

        return $result;
    }

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function validate(string $data): void;

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function transform(string $data): string;

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function export(string $data): string;

    /**
     * Hook Method - optional, can be overridden by subclasses
     * Default implementation does nothing
     */
    protected function beforeExport(string $data): void
    {
        // Hook: subclasses may override for pre-export logic
    }

    /**
     * Hook Method - optional, can be overridden by subclasses
     */
    protected function afterExport(string $result): void
    {
        // Hook: subclasses may override for post-export logic
    }
}

/**
 * Concrete implementation for CSV format
 */
class CsvProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        $lines = explode("\n", trim($data));
        return implode('|', $lines); // Transform to pipe-separated format
    }

    protected function export(string $data): string
    {
        return "CSV:\n" . str_replace('|', ',', $data);
    }

    protected function beforeExport(string $data): void
    {
        echo "Preparing CSV export...\n";
    }
}

/**
 * Concrete implementation for JSON format
 */
class JsonProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        return json_encode(
            array_map('trim', explode("\n", $data)),
            JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR
        );
    }

    protected function export(string $data): string
    {
        return json_decode($data, associative: true) !== null
            ? "JSON:\n" . $data
            : throw new \RuntimeException('Invalid JSON data');
    }

    protected function afterExport(string $result): void
    {
        echo "JSON export completed successfully.\n";
    }
}

/**
 * Concrete implementation for XML format
 */
class XmlProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        $lines = array_map('trim', explode("\n", $data));
        $items = array_map(
            fn($line) => "<item>{$line}</item>",
            $lines
        );
        return implode("\n", $items);
    }

    protected function export(string $data): string
    {
        return "<?xml version=\"1.0\"?>\n<root>\n$data\n</root>";
    }
}

// Usage
$data = "item1\nitem2\nitem3";

$csvProcessor = new CsvProcessor();
echo $csvProcessor->process($data);
echo "\n---\n";

$jsonProcessor = new JsonProcessor();
echo $jsonProcessor->process($data);
echo "\n---\n";

$xmlProcessor = new XmlProcessor();
echo $xmlProcessor->process($data);
```

## Real-World Analogies

**Document Generation Pipeline:** A document generator defines a template method that outlines: load template → fill placeholders → apply formatting → export to file. Different document types (PDF, Word, HTML) override the formatting and export steps while following the same overall process.

**Cooking Recipe:** A recipe is a template method. The basic structure is: gather ingredients → prepare → cook → season → serve. Individual dishes override specific steps (cooking temperature, seasoning type) but follow the same general process.

**Software Build Process:** A build system defines steps: checkout code → compile → run tests → package → deploy. Different projects override specific steps but follow the identical pipeline structure.

**Web Request Lifecycle:** Frameworks like Symfony use template methods in middleware/controllers: receive request → authenticate → validate → process → format response. Developers override process() while the framework controls the overall flow.

## Pros and Cons

### Pros
- Reduces code duplication through code reuse
- Defines a stable algorithm structure for subclasses to extend
- Enforces consistent algorithm implementation across variations
- Follows the Hollywood Principle (inversion of control)
- Easy to add new variations without modifying existing code
- Separates invariant code from variable code
- Improves maintainability by centralizing algorithm logic

### Cons
- Requires careful design to identify invariant vs. variable parts
- Inheritance-based approach (rigid compared to composition)
- Can lead to complex inheritance hierarchies
- Subclasses limited to overriding predefined hook methods
- Difficult to handle algorithm changes affecting multiple subclasses
- Code visibility issues (protected methods can be fragile)
- May violate Liskov Substitution Principle if subclasses don't respect contract

## Relations with Other Patterns

- **Strategy:** Both allow varying algorithm behavior; Strategy uses composition, Template Method uses inheritance
- **Factory Method:** Often used within template methods to create objects
- **Hook Method:** Part of Template Method pattern for optional customization points
- **Decorator:** Can wrap template method classes but doesn't define algorithm skeleton
- **Abstract Factory:** Can work together; factory creates template method instances
- **State:** Can be combined where state changes trigger different algorithm paths
- **Observer:** Can notify observers at key template method steps
- **Chain of Responsibility:** Can implement steps as a chain in template methods

## Key Takeaways

The Template Method pattern is essential for managing code reuse and algorithm variations. It's particularly valuable in framework design and when you have multiple classes implementing similar algorithms with minor variations. Use hook methods liberally to provide extension points without requiring subclass implementation. Be cautious of inheritance depth and consider refactoring to composition-based approaches (Strategy pattern) if hierarchies become complex.

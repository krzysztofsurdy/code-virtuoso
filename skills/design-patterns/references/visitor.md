# Visitor Design Pattern

## Overview

The Visitor pattern is a behavioral design pattern that lets you separate algorithms from the objects on which they operate. It enables you to add new operations to existing object structures without modifying those structures. This is achieved by defining a visitor interface with methods for each type of element in the structure.

## Intent

- Represent an operation to be performed on elements of an object structure
- Let you define a new operation without changing the classes of the elements on which it operates
- Collect related operations into a single visitor object

## Problem/Solution

**Problem:** You have a complex object structure (like an AST, document tree, or report model) and need to perform various operations on it. Adding operations by modifying the element classes violates the Open/Closed Principle and creates tightly coupled code.

**Solution:** Define a Visitor interface with a method for each element type. Each element implements an `accept()` method that takes a visitor and calls the appropriate visit method. New operations are added by creating new visitor implementations without touching the element classes.

## Structure

```
┌─────────────┐
│  Visitor    │
├─────────────┤
│ +visit()    │ (abstract)
└─────────────┘
      △
      │ implements
      │
┌─────────────────────┐
│  ConcreteVisitor    │
├─────────────────────┤
│ +visit(ElementA)    │
│ +visit(ElementB)    │
└─────────────────────┘

┌──────────────┐
│   Element    │
├──────────────┤
│ +accept()    │
└──────────────┘
      △
      │ implements
      │
┌──────────────────┐
│  ConcreteElement │
├──────────────────┤
│ +accept(visitor) │
└──────────────────┘
```

## When to Use

- Complex object structures with many different element types requiring different operations
- Need to perform many distinct operations on elements without polluting their classes
- Object structure rarely changes but operations change frequently
- Multiple unrelated operations on the same structure
- Processing ASTs, XML documents, or domain models
- Implementing interpreters, compilers, or code generators

## Implementation (PHP 8.3+ Strict Types)

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\Behavioral\Visitor;

// Visitor Interface
interface Visitor
{
    public function visitBook(Book $book): string;
    public function visitPDF(PDF $pdf): string;
}

// Element Interface
interface Element
{
    public function accept(Visitor $visitor): string;
}

// Concrete Elements
readonly class Book implements Element
{
    public function __construct(
        public string $title,
        public string $author,
        public float $price,
    ) {}

    public function accept(Visitor $visitor): string
    {
        return $visitor->visitBook($this);
    }
}

readonly class PDF implements Element
{
    public function __construct(
        public string $filename,
        public int $pages,
        public float $filesize,
    ) {}

    public function accept(Visitor $visitor): string
    {
        return $visitor->visitPDF($this);
    }
}

// Concrete Visitor - Export to CSV
class ExportVisitor implements Visitor
{
    public function visitBook(Book $book): string
    {
        return sprintf(
            'Book,"%s","%s",%.2f',
            $book->title,
            $book->author,
            $book->price,
        );
    }

    public function visitPDF(PDF $pdf): string
    {
        return sprintf(
            'PDF,"%s",%d,%.2f',
            $pdf->filename,
            $pdf->pages,
            $pdf->filesize,
        );
    }
}

// Concrete Visitor - Calculate Price
class PricingVisitor implements Visitor
{
    private float $total = 0.0;

    public function visitBook(Book $book): string
    {
        $this->total += $book->price;
        return '';
    }

    public function visitPDF(PDF $pdf): string
    {
        $this->total += $pdf->filesize * 0.01;
        return '';
    }

    public function getTotal(): float
    {
        return $this->total;
    }
}

// Usage
$elements = [
    new Book('Clean Code', 'Robert Martin', 49.99),
    new PDF('design-patterns.pdf', 500, 2048.50),
    new Book('Design Patterns', 'Gang of Four', 54.99),
];

$exporter = new ExportVisitor();
foreach ($elements as $element) {
    echo $element->accept($exporter) . "\n";
}

$pricer = new PricingVisitor();
foreach ($elements as $element) {
    $element->accept($pricer);
}
echo "Total: " . $pricer->getTotal() . "\n";
```

## Real-World Analogies

- **Tax System:** Different tax rules (visitors) applied to different product types (elements) without modifying the products
- **Museum Tour Guide:** A tour guide (visitor) describes different exhibits (elements) in specific ways, with different guides having different perspectives
- **Compiler:** Different compiler phases (visitors) process the same AST without modifying the node classes
- **Travel Agency:** Different travel itineraries (visitors) can be created for the same set of destinations (elements)

## Pros and Cons

**Pros:**
- Adds new operations without modifying element classes (Open/Closed Principle)
- Groups related operations in a single visitor class
- Simplifies element classes by removing operation logic
- Easier to add multiple unrelated operations
- Works well with polymorphic structures

**Cons:**
- Adding new element types requires modifying all visitor classes
- Can introduce tight coupling between visitors and elements
- May lead to violation of encapsulation if elements expose implementation details
- Complex for simple object structures
- Performance overhead from dynamic dispatch

## Relations with Other Patterns

- **Composite:** Visitor is often used with Composite to operate on element hierarchies
- **Iterator:** Similar traversal benefits; Iterator focuses on sequential access
- **Strategy:** Both encapsulate algorithms; Visitor is better for complex structures with multiple types
- **Double Dispatch:** Visitor is an implementation of double dispatch pattern
- **Template Method:** Can work together; Visitor for operation logic, Template Method for algorithm structure
- **Interpreter:** Visitor pattern processes the parse tree generated by Interpreter

## Key Takeaways

The Visitor pattern is powerful for scenarios where you have a stable object structure but frequently need to add new operations. By separating operations from the objects themselves, it maintains clean separation of concerns and adheres to SOLID principles. However, it's most effective when element types are stable, as adding new types requires updating all visitors.

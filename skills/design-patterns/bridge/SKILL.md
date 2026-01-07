---
name: Bridge Design Pattern
description: Decouple an abstraction from its implementation so the two can vary independently, enabling flexible class hierarchies.
---

## Overview

The Bridge design pattern is a structural pattern that decouples abstraction from implementation by creating a bridge between them. It allows multiple abstractions and implementations to coexist without creating a combinatorial explosion of classes.

## Intent

The pattern's intent is to:
- Separate abstraction from implementation so they can vary independently
- Avoid a permanent binding between abstraction and implementation
- Reduce the number of classes in a hierarchy by using composition instead of inheritance
- Allow runtime selection of implementations

## Problem & Solution

### Problem

When you have an abstraction (e.g., Shape) with multiple implementations (e.g., Circle, Rectangle) and multiple variants of each implementation (e.g., Windows rendering, Linux rendering), using inheritance creates a combinatorial explosion:
- Shape (base)
  - Circle (abstraction)
    - CircleWindows (implementation)
    - CircleLinux (implementation)
  - Rectangle (abstraction)
    - RectangleWindows (implementation)
    - RectangleLinux (implementation)

This hierarchy becomes unmaintainable as new dimensions of variation are added.

### Solution

The Bridge pattern solves this by:
1. Creating two separate hierarchies: one for abstraction, one for implementation
2. Connecting them via composition rather than inheritance
3. Using a bridge interface/abstraction that the high-level classes depend on

Instead of inheritance, the abstraction holds a reference to an implementation object and delegates work to it.

## Structure

**Key Components:**

- **Abstraction**: Defines the high-level interface and holds a reference to an implementor
- **RefinedAbstraction**: Extends the abstraction with more specific operations
- **Implementor**: Defines the interface for implementation classes
- **ConcreteImplementor**: Implements the implementor interface with specific logic

**Relationship:** Abstraction → (has-a) → Implementor ← ConcreteImplementor

## When to Use

Use the Bridge pattern when:
- You want to avoid permanent binding between abstraction and implementation
- Changes to the implementation shouldn't affect clients
- You want to share an implementation among multiple objects
- You need to reduce class hierarchies (multiple inheritance of type)
- You want to vary both abstraction and implementation at runtime
- You have platforms/graphics renderers, UI themes, databases, or drivers

## Implementation

### PHP 8.3+ Example with Strict Types

```php
<?php

declare(strict_types=1);

namespace DesignPatterns\Bridge;

// Implementor interface
interface DrawingImplementor
{
    public function drawCircle(int $x, int $y, int $radius): void;
    public function drawRectangle(int $x, int $y, int $width, int $height): void;
}

// Concrete implementors
final class WindowsDrawingImplementor implements DrawingImplementor
{
    public function drawCircle(int $x, int $y, int $radius): void
    {
        echo "Drawing circle on Windows at ($x, $y) with radius $radius\n";
    }

    public function drawRectangle(int $x, int $y, int $width, int $height): void
    {
        echo "Drawing rectangle on Windows at ($x, $y) {$width}x{$height}\n";
    }
}

final class LinuxDrawingImplementor implements DrawingImplementor
{
    public function drawCircle(int $x, int $y, int $radius): void
    {
        echo "Drawing circle on Linux (X11) at ($x, $y) with radius $radius\n";
    }

    public function drawRectangle(int $x, int $y, int $width, int $height): void
    {
        echo "Drawing rectangle on Linux (X11) at ($x, $y) {$width}x{$height}\n";
    }
}

// Abstraction
abstract readonly class Shape
{
    public function __construct(private DrawingImplementor $implementor)
    {
    }

    protected function getImplementor(): DrawingImplementor
    {
        return $this->implementor;
    }

    abstract public function draw(): void;
}

// Refined abstractions
final class Circle extends Shape
{
    public function __construct(
        private readonly int $x,
        private readonly int $y,
        private readonly int $radius,
        DrawingImplementor $implementor
    ) {
        parent::__construct($implementor);
    }

    public function draw(): void
    {
        $this->getImplementor()->drawCircle($this->x, $this->y, $this->radius);
    }
}

final class Rectangle extends Shape
{
    public function __construct(
        private readonly int $x,
        private readonly int $y,
        private readonly int $width,
        private readonly int $height,
        DrawingImplementor $implementor
    ) {
        parent::__construct($implementor);
    }

    public function draw(): void
    {
        $this->getImplementor()->drawRectangle(
            $this->x,
            $this->y,
            $this->width,
            $this->height
        );
    }
}

// Usage
$windowsRenderer = new WindowsDrawingImplementor();
$linuxRenderer = new LinuxDrawingImplementor();

$circle = new Circle(100, 100, 50, $windowsRenderer);
$circle->draw(); // Output: Drawing circle on Windows...

$circle2 = new Circle(200, 200, 75, $linuxRenderer);
$circle2->draw(); // Output: Drawing circle on Linux...

$rect = new Rectangle(0, 0, 200, 100, $windowsRenderer);
$rect->draw(); // Output: Drawing rectangle on Windows...
?>
```

## Real-World Analogies

1. **Vehicle Remote Controls**: The abstraction is the remote interface (buttons), implementations are Bluetooth, IR, or RF protocols. Changing the protocol doesn't affect the remote's interface.

2. **Database Adapters**: The abstraction is your application (queries), implementations are MySQL, PostgreSQL, SQLite drivers. Switching databases requires no application changes.

3. **Payment Gateways**: The abstraction is your checkout interface, implementations are Stripe, PayPal, Square API integrations.

4. **UI Rendering**: The abstraction is your UI components (buttons, dialogs), implementations are native platform renderers (Windows, macOS, Linux).

## Pros & Cons

### Pros
- Decouples abstraction from implementation
- Reduces class hierarchies (no combinatorial explosion)
- Improves flexibility and maintainability
- Enables runtime selection of implementations
- Open/Closed Principle: open for extension, closed for modification
- Single Responsibility: each class has one reason to change

### Cons
- Increased complexity with more classes and abstraction layers
- Can be overkill for simple use cases
- Slight performance overhead from extra indirection
- Requires upfront planning to identify abstraction boundaries

## Relations with Other Patterns

- **Adapter**: Connects incompatible interfaces after design; Bridge connects them during design
- **Abstract Factory**: Often used together to create families of objects that work with Bridge
- **Strategy**: Similar structure, but different intent (algorithms vs. implementations)
- **Decorator**: Both use composition, but for different purposes (adding features vs. varying implementation)
- **Facade**: Provides simplified interface; Bridge provides abstraction-implementation separation

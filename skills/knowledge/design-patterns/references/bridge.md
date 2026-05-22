## Overview

The Bridge is a structural pattern that decomposes a monolithic class hierarchy into two orthogonal dimensions - abstraction and implementation - joined by composition instead of inheritance. By separating what an object does from how it does it, the pattern avoids the combinatorial class explosion that occurs when both dimensions evolve independently, and allows each side to vary without disturbing the other.

## Intent

The pattern aims to:
- Sever the tight coupling between an abstraction and its implementation so neither constrains the other's evolution
- Substitute rigid inheritance trees with a flexible composition-based link
- Keep the total class count linear rather than multiplicative when two dimensions of variation exist
- Permit implementations to be selected or replaced at runtime without touching the abstraction layer

## Problem & Solution

### Problem

When a design involves two independent axes of variation (for example, Shape and RenderingEngine), encoding both through inheritance produces a Cartesian product of subclasses:
- Shape (base)
  - Circle (abstraction)
    - CircleWindows (implementation)
    - CircleLinux (implementation)
  - Rectangle (abstraction)
    - RectangleWindows (implementation)
    - RectangleLinux (implementation)

Each additional shape or rendering platform multiplies the total number of classes, quickly making the hierarchy unwieldy.

### Solution

The Bridge pattern resolves this by:
1. Factoring the hierarchy into two separate trees: one for the abstraction, one for the implementation
2. Connecting them via composition - the abstraction holds a reference to an implementor object
3. Letting each tree grow at its own pace without creating cross-product classes

The abstraction forwards platform-dependent work to the implementor, keeping both hierarchies focused and independent.

## Structure

**Key Components:**

- **Abstraction**: High-level interface that holds a reference to an implementor and defines domain-oriented operations
- **RefinedAbstraction**: Extends the abstraction with more specialized behavior
- **Implementor**: Low-level interface that defines the platform or technology-specific operations
- **ConcreteImplementor**: Provides the actual platform-specific logic

**Relationship:** Abstraction → (has-a) → Implementor ← ConcreteImplementor

## When to Use

Apply the Bridge pattern when:
- You need to avoid a permanent lock between an abstraction and its implementation
- Implementation changes should be invisible to consuming code
- You want to share a single implementation across multiple abstraction instances
- Class hierarchies are growing in two dimensions simultaneously
- You need to select or swap implementations at runtime
- You are dealing with platform renderers, UI themes, database drivers, or similar multi-dimensional concerns

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

1. **Remote Controls and Devices**: The remote defines the user-facing buttons (abstraction), while the communication protocol - Bluetooth, IR, or RF - handles signal transmission (implementation). Swapping protocols requires no redesign of the remote's button layout.

2. **Application Code and Database Drivers**: Business logic (the abstraction) formulates queries, while MySQL, PostgreSQL, or SQLite drivers (the implementations) translate them into vendor-specific calls. Switching database engines leaves the application layer unchanged.

3. **Checkout Flow and Payment Gateways**: The checkout interface (abstraction) gathers payment details, while Stripe, PayPal, or Square integrations (implementations) carry out the actual transaction. Adding a new payment provider requires no changes to the checkout flow.

4. **UI Widgets and Platform Renderers**: Buttons and dialogs (abstractions) declare what to display, while OS-specific renderers (implementations) control how those elements appear on Windows, macOS, or Linux.

## Pros & Cons

### Pros
- Draws a clear boundary between what an object does and how it accomplishes it
- Keeps the class count linear instead of multiplicative as dimensions grow
- Simplifies extension and maintenance on both the abstraction and implementation sides
- Supports hot-swapping implementations at runtime
- Naturally adheres to the Open/Closed and Single Responsibility principles

### Cons
- Introduces additional classes and indirection layers, raising architectural complexity
- Feels disproportionate when the design involves only a single dimension of variation
- Delegation through the bridge adds a minor runtime cost
- Requires deliberate upfront analysis to correctly identify the two orthogonal dimensions

## Relations with Other Patterns

- **Adapter**: Adapter is applied retroactively to make incompatible interfaces work together; Bridge is an intentional upfront separation of abstraction from implementation
- **Abstract Factory**: Often paired with Bridge - Abstract Factory can supply the correct implementor objects for a given abstraction
- **Strategy**: Structurally alike (both vary behavior via composition), but Strategy swaps interchangeable algorithms while Bridge decouples an abstraction from its implementation
- **Decorator**: Both leverage composition, but toward different ends - Decorator stacks additional behavior, Bridge partitions two independent dimensions of variation
- **Facade**: Facade conceals subsystem complexity behind a simplified interface; Bridge provides a principled separation between abstraction and implementation layers

## Examples in Other Languages

### Java

Decoupling stack abstraction from implementation (array-based vs linked-list storage):

```java
class Node {
    public int value;
    public Node prev, next;
    public Node(int value) { this.value = value; }
}

class StackArray {
    private int[] items;
    private int size = -1;

    public StackArray() { this.items = new int[12]; }
    public StackArray(int cells) { this.items = new int[cells]; }

    public void push(int i) {
        if (!isFull()) { items[++size] = i; }
    }
    public boolean isEmpty() { return size == -1; }
    public boolean isFull() { return size == items.length - 1; }
    public int top() { return isEmpty() ? -1 : items[size]; }
    public int pop() { return isEmpty() ? -1 : items[size--]; }
}

class StackList {
    private Node last;

    public void push(int i) {
        if (last == null) {
            last = new Node(i);
        } else {
            last.next = new Node(i);
            last.next.prev = last;
            last = last.next;
        }
    }
    public boolean isEmpty() { return last == null; }
    public boolean isFull() { return false; }
    public int top() { return isEmpty() ? -1 : last.value; }
    public int pop() {
        if (isEmpty()) return -1;
        int ret = last.value;
        last = last.prev;
        return ret;
    }
}

class StackFIFO extends StackArray {
    private StackArray stackArray = new StackArray();
    public int pop() {
        while (!isEmpty()) { stackArray.push(super.pop()); }
        int ret = stackArray.pop();
        while (!stackArray.isEmpty()) { push(stackArray.pop()); }
        return ret;
    }
}

class StackHanoi extends StackArray {
    private int totalRejected = 0;
    public int reportRejected() { return totalRejected; }
    public void push(int in) {
        if (!isEmpty() && in > top()) { totalRejected++; }
        else { super.push(in); }
    }
}
```

### C++

Bridge pattern with time display: separating time abstraction from civilian/military formatting:

```cpp
#include <iostream>
#include <iomanip>
#include <cstring>
using namespace std;

class TimeImp {
  public:
    TimeImp(int hr, int min) : hr_(hr), min_(min) {}
    virtual void tell() {
        cout << "time is " << setw(2) << setfill('0') << hr_ << min_ << endl;
    }
  protected:
    int hr_, min_;
};

class CivilianTimeImp: public TimeImp {
  public:
    CivilianTimeImp(int hr, int min, int pm) : TimeImp(hr, min) {
        if (pm) strcpy(whichM_, " PM");
        else strcpy(whichM_, " AM");
    }
    void tell() {
        cout << "time is " << hr_ << ":" << min_ << whichM_ << endl;
    }
  protected:
    char whichM_[4];
};

class ZuluTimeImp: public TimeImp {
  public:
    ZuluTimeImp(int hr, int min, int zone) : TimeImp(hr, min) {
        if (zone == 5) strcpy(zone_, " Eastern Standard Time");
        else if (zone == 6) strcpy(zone_, " Central Standard Time");
    }
    void tell() {
        cout << "time is " << setw(2) << setfill('0') << hr_ << min_ << zone_ << endl;
    }
  protected:
    char zone_[30];
};

class Time {
  public:
    Time() {}
    Time(int hr, int min) { imp_ = new TimeImp(hr, min); }
    virtual void tell() { imp_->tell(); }
  protected:
    TimeImp *imp_;
};

class CivilianTime: public Time {
  public:
    CivilianTime(int hr, int min, int pm) { imp_ = new CivilianTimeImp(hr, min, pm); }
};

class ZuluTime: public Time {
  public:
    ZuluTime(int hr, int min, int zone) { imp_ = new ZuluTimeImp(hr, min, zone); }
};

int main() {
    Time *times[3];
    times[0] = new Time(14, 30);
    times[1] = new CivilianTime(2, 30, 1);
    times[2] = new ZuluTime(14, 30, 6);
    for (int i = 0; i < 3; i++)
        times[i]->tell();
}
```

### Python

```python
import abc


class Abstraction:
    """
    Define the abstraction's interface.
    Maintain a reference to an object of type Implementor.
    """
    def __init__(self, imp):
        self._imp = imp

    def operation(self):
        self._imp.operation_imp()


class Implementor(metaclass=abc.ABCMeta):
    """
    Define the interface for implementation classes. This interface
    doesn't have to correspond exactly to Abstraction's interface;
    in fact the two interfaces can be quite different.
    """
    @abc.abstractmethod
    def operation_imp(self):
        pass


class ConcreteImplementorA(Implementor):
    def operation_imp(self):
        pass


class ConcreteImplementorB(Implementor):
    def operation_imp(self):
        pass


def main():
    concrete_implementor_a = ConcreteImplementorA()
    abstraction = Abstraction(concrete_implementor_a)
    abstraction.operation()


if __name__ == "__main__":
    main()
```

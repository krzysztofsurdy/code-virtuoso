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

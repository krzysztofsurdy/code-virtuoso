## Overview

The Decorator design pattern is a structural pattern that enables you to dynamically add new functionality to objects without modifying their original structure. Instead of using inheritance to extend behavior, it uses composition to wrap objects with additional responsibilities. This pattern provides a more flexible and maintainable way to extend functionality compared to subclassing.

## Intent

The Decorator pattern solves the problem of adding responsibilities to individual objects dynamically. It allows you to:

- Add new functionality to objects at runtime without changing their implementation
- Avoid creating large families of subclasses for every possible combination of features
- Keep objects' core functionality separate from optional enhancements
- Apply multiple decorators in any combination to achieve desired behavior
- Follow the Open/Closed Principle by remaining open for extension but closed for modification

## Problem and Solution

**Problem:** You have a base object that provides core functionality, but you need to add optional features or behaviors to specific instances. Using inheritance creates an explosion of subclasses for every possible combination of features (e.g., `PlainCoffee`, `CoffeeWithMilk`, `CoffeeWithMilkAndSugar`, `CoffeeWithCinnamonAndMilk`, etc.). This approach becomes unmaintainable.

**Solution:** Create decorator classes that wrap the original object and implement the same interface. Each decorator adds a specific responsibility and delegates other operations to the wrapped object. Multiple decorators can be stacked to combine features dynamically at runtime.

## Structure

The Decorator pattern involves these participants:

- **Component:** Interface defining the operations both concrete objects and decorators must implement
- **ConcreteComponent:** The original object to which responsibilities can be added
- **Decorator:** Abstract class implementing the Component interface and maintaining a reference to the wrapped component
- **ConcreteDecorator:** Extends Decorator and adds specific responsibilities to the wrapped component

The key characteristic is that decorators implement the same interface as the component they wrap, allowing them to be treated identically by client code.

## When to Use

Use the Decorator pattern when:

- You need to add responsibilities to individual objects dynamically without affecting others
- Inheritance would create too many subclasses (combinatorial explosion)
- You want to extend functionality without permanently modifying the original class
- Building extensible frameworks where features can be mixed and matched
- You need to temporarily add or remove features from objects
- Avoiding tight coupling between core functionality and optional enhancements

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Structural\Decorator;

// Component: Interface for both concrete objects and decorators
interface TextProcessor {
    public function format(string $text): string;
    public function process(string $text): string;
}

// ConcreteComponent: Original object with base functionality
readonly class PlainTextProcessor implements TextProcessor {
    public function format(string $text): string {
        return $text;
    }

    public function process(string $text): string {
        return $this->format($text);
    }
}

// Abstract Decorator: Base class for all decorators
abstract readonly class TextProcessorDecorator implements TextProcessor {
    public function __construct(
        protected TextProcessor $processor
    ) {}

    public function format(string $text): string {
        return $this->processor->format($text);
    }

    public function process(string $text): string {
        return $this->processor->process($text);
    }
}

// ConcreteDecorator: Adds uppercase transformation
readonly class UppercaseDecorator extends TextProcessorDecorator {
    public function format(string $text): string {
        return strtoupper(parent::format($text));
    }
}

// ConcreteDecorator: Adds HTML escaping
readonly class HtmlEscapeDecorator extends TextProcessorDecorator {
    public function format(string $text): string {
        return htmlspecialchars(parent::format($text), ENT_QUOTES);
    }
}

// ConcreteDecorator: Adds markdown bold formatting
readonly class BoldDecorator extends TextProcessorDecorator {
    public function format(string $text): string {
        return '**' . parent::format($text) . '**';
    }
}

// Client code demonstrating dynamic decoration
$processor = new PlainTextProcessor();
echo $processor->process('hello world') . PHP_EOL;
// Output: hello world

// Stack decorators dynamically
$processor = new BoldDecorator(
    new UppercaseDecorator(
        new PlainTextProcessor()
    )
);
echo $processor->process('hello world') . PHP_EOL;
// Output: **HELLO WORLD**

// Different combination
$processor = new HtmlEscapeDecorator(
    new UppercaseDecorator(
        new PlainTextProcessor()
    )
);
echo $processor->process('<script>alert("xss")</script>') . PHP_EOL;
// Output: &lt;SCRIPT&gt;ALERT(&quot;XSS&quot;)&lt;/SCRIPT&gt;
```

## Real-World Analogies

- **Coffee Shop Orders:** A base coffee can be decorated with milk, sugar, cinnamon, or cream in any combination, creating different variations without modifying the base coffee.
- **Gift Wrapping:** You can wrap a gift with different types of paper, ribbons, and decorations without changing the gift itself.
- **GUI Frameworks:** UI components can be decorated with scrollbars, borders, shadows, or animation effects independently.
- **Stream I/O:** Input/output streams can be decorated with compression, encryption, or buffering layers.
- **Pizza Customization:** A base pizza can be decorated with various toppings, each adding to the price and properties without altering the fundamental pizza structure.

## Pros and Cons

**Pros:**
- Single Responsibility: Separates core functionality from optional features
- Open/Closed Principle: Extend functionality without modifying existing code
- Flexible Composition: Mix and match decorators in any combination at runtime
- Cleaner Code: Avoids subclass explosion with multiple combinations
- Dynamic Behavior: Add or remove features without creating new classes
- Easier Maintenance: Changes to decorators don't affect the component

**Cons:**
- Complexity: Multiple decorator layers can make code harder to understand
- Performance Overhead: Each decorator adds a layer of indirection
- Order Matters: Decorator order affects behavior (e.g., uppercase then bold differs from bold then uppercase)
- Debugging Difficulty: Stack traces become deeper with multiple decorators
- Boilerplate Code: Requires implementing full interface for simple decorators
- Memory Usage: Each decorator instance consumes memory

## Relations with Other Patterns

- **Adapter:** Similar structure (wrapping), but Adapter converts interfaces while Decorator adds responsibilities to the same interface
- **Proxy:** Both wrap objects, but Proxy controls access while Decorator adds functionality
- **Strategy:** Both allow behavior changes; Strategy typically replaces behavior entirely while Decorator adds to it
- **Factory Method:** Often used together to create appropriate decorator combinations
- **Composite:** Often works with Decorator; components can be decorated leaves or composite nodes
- **Facade:** Decorator enhances single objects while Facade simplifies entire subsystems

## Additional Considerations

**Design Tips:**
- Keep decorators lightweight with a single responsibility
- Make the Component interface as minimal as practical
- Consider using composition over inheritance for better flexibility
- Use readonly properties for immutability when appropriate
- Chain decorators declaratively for clarity

**Performance Optimization:**
- Cache decorator chains if they're frequently reused
- Consider using composition over stacking many decorators
- Be mindful of decorator order for performance-critical code

**Common Pitfall:**
Don't use Decorator if the object doesn't need dynamic extension. Inheritance may be simpler for fixed functionality hierarchies. Decorator shines when you need runtime flexibility with multiple optional features.

## Examples in Other Languages

### Java

Before and after example showing how decoration replaces inheritance explosion:

```java
// Common interface
interface I {
    void doIt();
}

// Concrete component
class A implements I {
    public void doIt() { System.out.print('A'); }
}

// Abstract decorator
abstract class D implements I {
    private I core;
    public D(I inner) { core = inner; }
    public void doIt() { core.doIt(); }
}

// Concrete decorators
class X extends D {
    public X(I inner) { super(inner); }
    public void doIt() { super.doIt(); doX(); }
    private void doX() { System.out.print('X'); }
}

class Y extends D {
    public Y(I inner) { super(inner); }
    public void doIt() { super.doIt(); doY(); }
    private void doY() { System.out.print('Y'); }
}

class Z extends D {
    public Z(I inner) { super(inner); }
    public void doIt() { super.doIt(); doZ(); }
    private void doZ() { System.out.print('Z'); }
}

public class DecoratorDemo {
    public static void main(String[] args) {
        I[] array = {new X(new A()), new Y(new X(new A())),
                new Z(new Y(new X(new A())))};
        for (I anArray : array) {
            anArray.doIt();
            System.out.print("  ");
        }
    }
}
// Output: AX  AXY  AXYZ
```

### C++

Decorator pattern replacing multiple inheritance with wrapping and delegation:

```cpp
#include <iostream>
using namespace std;

class I {
  public:
    virtual ~I() {}
    virtual void do_it() = 0;
};

class A: public I {
  public:
    ~A() { cout << "A dtor" << '\n'; }
    void do_it() { cout << 'A'; }
};

class D: public I {
  public:
    D(I *inner) { m_wrappee = inner; }
    ~D() { delete m_wrappee; }
    void do_it() { m_wrappee->do_it(); }
  private:
    I *m_wrappee;
};

class X: public D {
  public:
    X(I *core): D(core) {}
    ~X() { cout << "X dtor" << "   "; }
    void do_it() { D::do_it(); cout << 'X'; }
};

class Y: public D {
  public:
    Y(I *core): D(core) {}
    ~Y() { cout << "Y dtor" << "   "; }
    void do_it() { D::do_it(); cout << 'Y'; }
};

class Z: public D {
  public:
    Z(I *core): D(core) {}
    ~Z() { cout << "Z dtor" << "   "; }
    void do_it() { D::do_it(); cout << 'Z'; }
};

int main() {
    I *anX = new X(new A);
    I *anXY = new Y(new X(new A));
    I *anXYZ = new Z(new Y(new X(new A)));
    anX->do_it();   cout << '\n';
    anXY->do_it();  cout << '\n';
    anXYZ->do_it(); cout << '\n';
    delete anX;
    delete anXY;
    delete anXYZ;
}
// Output: AX  AXY  AXYZ
```

### Python

```python
import abc


class Component(metaclass=abc.ABCMeta):
    """
    Define the interface for objects that can have responsibilities
    added to them dynamically.
    """
    @abc.abstractmethod
    def operation(self):
        pass


class Decorator(Component, metaclass=abc.ABCMeta):
    """
    Maintain a reference to a Component object and define an interface
    that conforms to Component's interface.
    """
    def __init__(self, component):
        self._component = component

    @abc.abstractmethod
    def operation(self):
        pass


class ConcreteDecoratorA(Decorator):
    def operation(self):
        self._component.operation()


class ConcreteDecoratorB(Decorator):
    def operation(self):
        self._component.operation()


class ConcreteComponent(Component):
    """
    Define an object to which additional responsibilities can be attached.
    """
    def operation(self):
        pass


def main():
    concrete_component = ConcreteComponent()
    concrete_decorator_a = ConcreteDecoratorA(concrete_component)
    concrete_decorator_b = ConcreteDecoratorB(concrete_decorator_a)
    concrete_decorator_b.operation()


if __name__ == "__main__":
    main()
```

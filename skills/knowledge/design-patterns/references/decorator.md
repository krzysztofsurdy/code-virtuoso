## Overview

The Decorator pattern is a structural design pattern that augments objects at runtime by enclosing them in lightweight wrappers that conform to the same interface. Instead of relying on deep inheritance hierarchies to account for every feature combination, it builds behavior through nested composition, with each wrapper contributing a single, well-defined enhancement.

## Intent

The Decorator pattern meets the need to enhance individual objects dynamically. It enables you to:

- Attach new behavior to objects without modifying their existing source code
- Avoid the combinatorial explosion of subclasses that results from freely mixable features
- Keep core logic and optional extensions in separate classes so each evolves on its own timeline
- Compose multiple decorators in any sequence to assemble precisely the behavior a caller requires
- Uphold the Open/Closed Principle - existing classes stay closed for modification while remaining open for extension via wrapping

## Problem and Solution

**Problem:** A core object performs its primary job correctly, but different callers need different mixes of supplementary features on top of it. Subclassing every permutation - `PlainCoffee`, `CoffeeWithMilk`, `CoffeeWithMilkAndSugar`, `CoffeeWithCinnamonAndMilk` - spawns an unmanageable number of classes that multiplies with every new option.

**Solution:** Create decorator classes that implement the same interface as the object they enclose. Each decorator adds one focused enhancement and delegates all other calls to the wrapped object. At runtime, decorators stack around the core like concentric shells, and any combination of features emerges naturally from the nesting order - no new subclasses required.

## Structure

The Decorator pattern involves these participants:

- **Component:** Interface defining the operations both concrete objects and decorators must implement
- **ConcreteComponent:** The original object to which responsibilities can be added
- **Decorator:** Abstract class implementing the Component interface and maintaining a reference to the wrapped component
- **ConcreteDecorator:** Extends Decorator and adds specific responsibilities to the wrapped component

The key characteristic is that decorators implement the same interface as the component they wrap, allowing them to be treated identically by client code.

## When to Use

Use the Decorator pattern when:

- Individual objects need additional behavior at runtime while others of the same type remain unchanged
- Subclassing would produce a combinatorial explosion of variants
- You want to enhance functionality without permanently altering the original class
- You are building a framework where users should be able to mix and match optional features
- Features need to be attached or removed dynamically during the object's lifetime
- Core logic and optional extras should be maintained and tested independently

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

- **Layered Clothing**: A base shirt gains warmth from a vest, wind resistance from a jacket, and waterproofing from a raincoat. Each layer adds a distinct property without replacing the ones underneath.
- **Photo Editing Filters**: An image editor stacks filters - contrast, saturation, vignette - one atop another. Each filter transforms the output of the previous one, and the user can reorder or strip any filter independently.
- **I/O Stream Wrappers**: A raw byte stream can be enclosed in a buffering layer, then a compression layer, then an encryption layer. Each wrapper manages one concern and forwards data to the next.

## Pros and Cons

**Pros:**
- Every decorator carries a single enhancement, preserving clear separation of responsibilities
- Behavior grows through composition rather than through modifications to existing classes
- Decorators can be mixed in any arrangement and quantity at runtime
- Eliminates the exponential proliferation of subclass variants
- Enhancements can be attached or stripped during the object's lifetime
- Changes to one decorator are isolated from the core component and from other decorators

**Cons:**
- A deeply nested wrapper stack can obscure execution flow and complicate debugging
- Each decorator layer introduces a delegation hop with a minor performance penalty
- The stacking order influences the final result, which can produce subtle, order-dependent bugs
- Stack traces lengthen with each wrapper, making error diagnosis more laborious
- Every decorator must implement the full component interface even when it only alters one method
- Each wrapper instance consumes its own memory allocation

## Relations with Other Patterns

- **Adapter:** Both wrap objects, but Adapter translates one interface into another while Decorator enriches behavior behind the same interface
- **Proxy:** Proxy governs access to the wrapped object; Decorator extends its capabilities
- **Strategy:** Strategy replaces an entire algorithm at once; Decorator incrementally layers enhancements onto existing behavior
- **Factory Method:** Frequently used to assemble the correct combination of decorators for a given context
- **Composite:** Both support recursive composition, but Composite models containment hierarchies while Decorator stacks additional behavior
- **Facade:** Facade unifies a subsystem behind a simpler interface; Decorator augments a single object's functionality

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

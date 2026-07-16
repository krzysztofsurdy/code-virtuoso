# Decorator Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+)](#implementation-php-83)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Additional considerations](#additional-considerations)
- [Examples in other languages](#examples-in-other-languages)

## Overview

The Decorator pattern is a structural design pattern that adds behavior to objects at runtime by wrapping them in lightweight wrappers that implement the same interface. Instead of a deep inheritance hierarchy covering every feature combination, behavior is built through nested composition, with each wrapper adding one enhancement.

## Intent

The Decorator pattern is for enhancing individual objects dynamically. It lets you:

- Attach new behavior to objects without modifying their existing source code
- Avoid the combinatorial explosion of subclasses that results from freely mixable features
- Keep core logic and optional extensions in separate classes so each evolves on its own timeline
- Compose multiple decorators in any order to get the behavior a caller needs
- Follow the Open/Closed Principle: existing classes stay closed for modification and open for extension via wrapping

## Problem and solution

**Problem:** A core object performs its primary job correctly, but different callers need different mixes of supplementary features on top of it. Subclassing every permutation - `PlainCoffee`, `CoffeeWithMilk`, `CoffeeWithMilkAndSugar`, `CoffeeWithCinnamonAndMilk` - produces an unmanageable number of classes that grows with every new option.

**Solution:** Create decorator classes that implement the same interface as the object they enclose. Each decorator adds one focused enhancement and delegates all other calls to the wrapped object. At runtime, decorators stack around the core like concentric shells, and any combination of features comes from the nesting order, with no new subclasses.

## Structure

The Decorator pattern involves these participants:

- **Component:** Interface defining the operations both concrete objects and decorators must implement
- **ConcreteComponent:** The original object to which responsibilities can be added
- **Decorator:** Abstract class implementing the Component interface and maintaining a reference to the wrapped component
- **ConcreteDecorator:** Extends Decorator and adds specific responsibilities to the wrapped component

Decorators implement the same interface as the component they wrap, so client code treats them identically.

## When to use

Use the Decorator pattern when:

- Individual objects need additional behavior at runtime while others of the same type remain unchanged
- Subclassing would produce a combinatorial explosion of variants
- You want to extend functionality without permanently altering the original class
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

## Real-world analogies

- **Layered Clothing**: A base shirt gets warmth from a vest, wind resistance from a jacket, and waterproofing from a raincoat. Each layer adds a property without replacing the ones underneath.
- **Photo Editing Filters**: An image editor stacks filters - contrast, saturation, vignette - one atop another. Each filter transforms the output of the previous one, and any filter can be reordered or removed independently.
- **I/O Stream Wrappers**: A raw byte stream can be enclosed in a buffering layer, then a compression layer, then an encryption layer. Each wrapper manages one concern and forwards data to the next.

## Pros and cons

**Pros:**
- Each decorator carries a single enhancement, so responsibilities stay separate
- Behavior grows through composition, not by modifying existing classes
- Decorators can be combined in any order and quantity at runtime
- Avoids the exponential growth of subclass variants
- Enhancements can be attached or removed during the object's lifetime
- Changes to one decorator do not affect the core component or other decorators

**Cons:**
- A deeply nested wrapper stack obscures execution flow and complicates debugging
- Each decorator layer adds a delegation hop with a small performance cost
- The stacking order affects the result, which can cause subtle order-dependent bugs
- Stack traces get longer with each wrapper, which makes errors harder to diagnose
- Every decorator must implement the full component interface even when it only changes one method
- Each wrapper instance uses its own memory

## Relations with other patterns

- **Adapter:** Both wrap objects, but Adapter translates one interface into another while Decorator adds behavior behind the same interface
- **Proxy:** Proxy governs access to the wrapped object; Decorator extends its capabilities
- **Strategy:** Strategy replaces an entire algorithm at once; Decorator layers enhancements onto existing behavior
- **Factory Method:** Often used to assemble the right combination of decorators for a given context
- **Composite:** Both support recursive composition, but Composite models containment hierarchies while Decorator stacks additional behavior
- **Facade:** Facade unifies a subsystem behind a simpler interface; Decorator augments a single object's functionality

## Additional considerations

**Design Tips:**
- Keep decorators lightweight with a single responsibility
- Make the Component interface as minimal as practical
- Prefer composition over inheritance
- Use readonly properties for immutability when appropriate
- Chain decorators declaratively for clarity

**Performance Optimization:**
- Cache decorator chains if they're frequently reused
- Consider using composition over stacking many decorators
- Be mindful of decorator order for performance-critical code

**Common Pitfall:**
Don't use Decorator if the object doesn't need dynamic extension. Inheritance may be simpler for fixed functionality hierarchies. Decorator pays off when you need runtime flexibility with multiple optional features.

## Examples in other languages

### Java

Before and after example showing how decoration replaces an inheritance explosion:

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

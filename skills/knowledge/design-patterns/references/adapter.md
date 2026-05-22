## Overview

The Adapter is a structural pattern that reconciles two interfaces that were never designed to work together. It places a thin wrapper around an existing class, exposing a new interface that matches what the client expects. The wrapper acts as a translator - converting calls, parameters, and return values so that both sides communicate without either needing to change.

## Intent

The Adapter pattern targets scenarios where a class has the right behavior but the wrong interface for your context. It enables you to:

- Make independently developed interfaces cooperate without modifying either one
- Integrate third-party or legacy libraries into an application through a stable internal contract
- Insulate client code from the details and quirks of external APIs
- Reuse proven classes whose method signatures differ from what your system demands

## Problem and Solution

**Problem:** A class or library provides exactly the functionality you need, but its interface does not match the contract your application relies on. Modifying the library is either impractical or out of your control.

**Solution:** Create an adapter class that satisfies the interface your application depends on and internally delegates every call to the incompatible class. The adapter absorbs all the translation work - mapping method names, reshaping parameters, and converting return values - so both the client and the adaptee remain unaware of each other.

## Structure

The Adapter pattern involves these participants:

- **Client:** Code that depends on a specific interface
- **Target Interface:** The contract the client depends on
- **Adapter:** Bridges the gap by implementing the target interface and wrapping the adaptee
- **Adaptee:** The pre-existing class with a different interface

Two main flavors:
1. **Class Adapter:** Leverages inheritance (requires multiple inheritance support)
2. **Object Adapter:** Leverages composition (the standard approach in PHP)

## When to Use

Use the Adapter pattern when:

- You need to integrate legacy code or third-party libraries whose interfaces differ from your application's expectations
- You want to repurpose existing classes without altering them
- You are building a common abstraction over multiple systems with varying APIs
- Connecting disparate subsystems that were developed independently
- You want to honor the Open/Closed Principle by extending behavior without modifying source

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Structural\Adapter;

// Target interface expected by the client
interface PaymentProcessor {
    public function process(float $amount): bool;
    public function getTransactionId(): string;
}

// Adaptee: Third-party payment gateway with different interface
class LegacyPaymentGateway {
    private string $transactionId = '';

    public function executePayment(float $sum): array {
        $this->transactionId = 'TXN_' . time();
        return [
            'success' => true,
            'transaction' => $this->transactionId,
            'amount' => $sum
        ];
    }

    public function getLastTransaction(): string {
        return $this->transactionId;
    }
}

// Adapter: Wraps the legacy gateway and implements the target interface
class PaymentGatewayAdapter implements PaymentProcessor {
    public function __construct(
        private readonly LegacyPaymentGateway $gateway
    ) {}

    public function process(float $amount): bool {
        $result = $this->gateway->executePayment($amount);
        return $result['success'] ?? false;
    }

    public function getTransactionId(): string {
        return $this->gateway->getLastTransaction();
    }
}

// Client code
$gateway = new LegacyPaymentGateway();
$adapter = new PaymentGatewayAdapter($gateway);

if ($adapter->process(99.99)) {
    echo "Payment processed: {$adapter->getTransactionId()}";
}
```

## Real-World Analogies

- **Travel Power Adapter:** An international plug adapter reshapes your device's prongs to fit a foreign socket. The electricity is identical - only the physical interface differs.
- **Conference Interpreter:** A human interpreter translates between two speakers with different native languages, enabling a conversation that neither could hold directly.
- **Database Abstraction Libraries:** ORMs and DBAL layers normalize vendor-specific SQL dialects behind a single query interface that the application uses uniformly across database engines.
- **Video Codecs:** A media player relies on codecs to bridge different encoding formats with its internal rendering pipeline, playing any file through the same playback API.

## Pros and Cons

**Pros:**
- Interface translation lives in a dedicated class, isolated from business logic (Single Responsibility)
- Additional adapters can be introduced without altering existing code (Open/Closed)
- Implementations become interchangeable behind a stable contract
- Original classes remain untouched and fully reusable elsewhere
- Client code programs against abstractions rather than concrete dependencies

**Cons:**
- Each adapted interface requires at least one new class, expanding the project's file count
- The extra delegation layer introduces a small runtime cost
- For trivial integrations, a full adapter adds ceremony that a simple wrapper would avoid
- Deeper call stacks make stack traces harder to follow during debugging

## Relations with Other Patterns

- **Decorator:** Both wrap an object, but Decorator layers new behavior onto it while Adapter converts its interface to a different one.
- **Facade:** Facade presents a simplified view of a complex subsystem; Adapter makes an incompatible interface conform to an expected contract.
- **Bridge:** Both separate abstraction from implementation, but Bridge is an intentional upfront design choice while Adapter is applied after the fact to fix a mismatch.
- **Strategy:** Both allow swappable behavior behind an interface; Adapter is frequently paired with Strategy for pluggable third-party integrations.
- **Factory Method:** A factory can choose and instantiate the correct adapter at runtime based on configuration or context.

## Additional Considerations

**When Designing Adapters:**
- Keep adapters thin - avoid adding business logic
- Use type hints and strict types for clarity
- Consider using inheritance for minimal adapters
- Document the adapted interface clearly
- Use dependency injection for flexibility

**Common Pitfall:**
Don't use Adapter to patch poor design. If you need adapters everywhere, reconsider your architecture design.

## Examples in Other Languages

### Java

Before and after example showing how adapters provide a common interface to legacy-specific interfaces:

```java
// Legacy classes with incompatible interfaces
class Line {
    public void draw(int x1, int y1, int x2, int y2) {
        System.out.println("Line from point A(" + x1 + ";" + y1 + "), to point B(" + x2 + ";" + y2 + ")");
    }
}

class Rectangle {
    public void draw(int x, int y, int width, int height) {
        System.out.println("Rectangle with coordinate left-down point (" + x + ";" + y + "), width: " + width
                + ", height: " + height);
    }
}

// Common target interface
interface Shape {
    void draw(int x, int y, int z, int j);
}

class LineAdapter implements Shape {
    private Line adaptee;
    public LineAdapter(Line line) { this.adaptee = line; }
    @Override
    public void draw(int x1, int y1, int x2, int y2) {
        adaptee.draw(x1, y1, x2, y2);
    }
}

class RectangleAdapter implements Shape {
    private Rectangle adaptee;
    public RectangleAdapter(Rectangle rectangle) { this.adaptee = rectangle; }
    @Override
    public void draw(int x1, int y1, int x2, int y2) {
        int x = Math.min(x1, x2);
        int y = Math.min(y1, y2);
        int width = Math.abs(x2 - x1);
        int height = Math.abs(y2 - y1);
        adaptee.draw(x, y, width, height);
    }
}

public class AdapterDemo {
    public static void main(String[] args) {
        Shape[] shapes = {new RectangleAdapter(new Rectangle()),
                          new LineAdapter(new Line())};
        int x1 = 10, y1 = 20, x2 = 30, y2 = 60;
        for (Shape shape : shapes) {
            shape.draw(x1, y1, x2, y2);
        }
    }
}
```

Square peg / round hole example:

```java
class SquarePeg {
    private double width;
    public SquarePeg(double width) { this.width = width; }
    public double getWidth() { return width; }
    public void setWidth(double width) { this.width = width; }
}

class RoundHole {
    private final int radius;
    public RoundHole(int radius) {
        this.radius = radius;
        System.out.println("RoundHole: max SquarePeg is " + radius * Math.sqrt(2));
    }
    public int getRadius() { return radius; }
}

class SquarePegAdapter {
    private final SquarePeg squarePeg;
    public SquarePegAdapter(double w) { squarePeg = new SquarePeg(w); }

    public void makeFit(RoundHole roundHole) {
        double amount = squarePeg.getWidth() - roundHole.getRadius() * Math.sqrt(2);
        System.out.println("reducing SquarePeg " + squarePeg.getWidth() + " by " +
            ((amount < 0) ? 0 : amount) + " amount");
        if (amount > 0) {
            squarePeg.setWidth(squarePeg.getWidth() - amount);
            System.out.println("   width is now " + squarePeg.getWidth());
        }
    }
}
```

### C++

Class adapter using multiple inheritance to adapt a legacy rectangle interface:

```cpp
#include <iostream>

typedef int Coordinate;
typedef int Dimension;

// Desired interface
class Rectangle {
  public:
    virtual void draw() = 0;
};

// Legacy component
class LegacyRectangle {
  public:
    LegacyRectangle(Coordinate x1, Coordinate y1, Coordinate x2, Coordinate y2)
    {
        x1_ = x1; y1_ = y1; x2_ = x2; y2_ = y2;
        std::cout << "LegacyRectangle: create. (" << x1_ << "," << y1_
                  << ") => (" << x2_ << "," << y2_ << ")" << std::endl;
    }
    void oldDraw() {
        std::cout << "LegacyRectangle: oldDraw. (" << x1_ << "," << y1_
                  << ") => (" << x2_ << "," << y2_ << ")" << std::endl;
    }
  private:
    Coordinate x1_, y1_, x2_, y2_;
};

// Adapter wrapper
class RectangleAdapter: public Rectangle, private LegacyRectangle {
  public:
    RectangleAdapter(Coordinate x, Coordinate y, Dimension w, Dimension h)
      : LegacyRectangle(x, y, x + w, y + h) {
        std::cout << "RectangleAdapter: create. (" << x << "," << y
                  << "), width = " << w << ", height = " << h << std::endl;
    }
    virtual void draw() {
        std::cout << "RectangleAdapter: draw." << std::endl;
        oldDraw();
    }
};

int main() {
    Rectangle *r = new RectangleAdapter(120, 200, 60, 40);
    r->draw();
}
```

### Python

```python
import abc


class Target(metaclass=abc.ABCMeta):
    """
    Define the domain-specific interface that Client uses.
    """
    def __init__(self):
        self._adaptee = Adaptee()

    @abc.abstractmethod
    def request(self):
        pass


class Adapter(Target):
    """
    Adapt the interface of Adaptee to the Target interface.
    """
    def request(self):
        self._adaptee.specific_request()


class Adaptee:
    """
    Define an existing interface that needs adapting.
    """
    def specific_request(self):
        pass


def main():
    adapter = Adapter()
    adapter.request()


if __name__ == "__main__":
    main()
```

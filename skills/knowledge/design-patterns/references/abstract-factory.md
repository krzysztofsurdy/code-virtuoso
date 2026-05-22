# Abstract Factory Pattern

## Overview

The Abstract Factory is a creational pattern that provides an interface for manufacturing entire families of related objects without specifying their concrete classes. Rather than scattering `new` calls throughout the codebase, it channels all instantiation through a factory abstraction, so replacing one product family with another requires changing only the factory instance - not the code that consumes the products.

## Intent

- Define a creation contract that produces cohesive sets of related objects in lockstep
- Centralize variant management behind a factory hierarchy, keeping product details out of client code
- Shield consuming code from knowing which concrete product classes it operates on
- Enforce compatibility within a product family by construction, preventing accidental cross-family mixing

## Problem & Solution

### Problem

Applications that must support several product families face a recurring set of difficulties:

1. **Scattered instantiation logic**: When client code creates products directly with `new`, it becomes tightly bound to specific implementations and hard to redirect
2. **Cross-family contamination**: Without a coordinating mechanism, nothing prevents one part of the system from mixing products that were never designed to work together
3. **Costly family additions**: Each new product family forces a sweep through every call site that constructs objects, risking regressions and inconsistencies

### Solution

Introduce an abstract factory interface declaring one creation method per product type. For every product family, implement a concrete factory that returns the correct set of objects. Client code programs against the factory and product abstractions exclusively, so swapping families reduces to injecting a different factory at the composition root.

## Structure

```
AbstractFactory (interface)
├── ConcreteFactoryA
├── ConcreteFactoryB
└── ...

AbstractProductA (interface)
├── ConcreteProductA1
└── ConcreteProductA2

AbstractProductB (interface)
├── ConcreteProductB1
└── ConcreteProductB2
```

## When to Use

- Your application needs to work with several distinct families of related objects
- You want to ship a toolkit of products while hiding their concrete implementations
- Consistency within a family is essential and must be enforced at the structural level
- You anticipate adding new families later and want to avoid touching existing client code
- Client code should never reference concrete product classes directly

## Implementation

### PHP 8.3+ Example: UI Theme Factory

```php
<?php
declare(strict_types=1);

// Abstract Products
interface Button {
    public function render(): string;
}

interface Checkbox {
    public function render(): string;
}

// Concrete Products - Light Theme
readonly class LightButton implements Button {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<button class='light-theme'>{$this->label}</button>";
    }
}

readonly class LightCheckbox implements Checkbox {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<input type='checkbox' class='light-theme'/><label>{$this->label}</label>";
    }
}

// Concrete Products - Dark Theme
readonly class DarkButton implements Button {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<button class='dark-theme'>{$this->label}</button>";
    }
}

readonly class DarkCheckbox implements Checkbox {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<input type='checkbox' class='dark-theme'/><label>{$this->label}</label>";
    }
}

// Abstract Factory
interface ThemeFactory {
    public function createButton(string $label): Button;
    public function createCheckbox(string $label): Checkbox;
}

// Concrete Factories
class LightThemeFactory implements ThemeFactory {
    public function createButton(string $label): Button {
        return new LightButton($label);
    }

    public function createCheckbox(string $label): Checkbox {
        return new LightCheckbox($label);
    }
}

class DarkThemeFactory implements ThemeFactory {
    public function createButton(string $label): Button {
        return new DarkButton($label);
    }

    public function createCheckbox(string $label): Checkbox {
        return new DarkCheckbox($label);
    }
}

// Client Code
class Application {
    public function __construct(private ThemeFactory $factory) {}

    public function render(): string {
        $button = $this->factory->createButton('Submit');
        $checkbox = $this->factory->createCheckbox('Remember me');

        return $button->render() . '<br>' . $checkbox->render();
    }
}

// Usage
$theme = 'dark'; // Could come from user preferences or config
$factory = match($theme) {
    'light' => new LightThemeFactory(),
    'dark' => new DarkThemeFactory(),
    default => throw new InvalidArgumentException("Unknown theme: $theme"),
};

$app = new Application($factory);
echo $app->render();
```

### Database Connection Factory Example

```php
<?php
declare(strict_types=1);

// Abstract Products
interface DatabaseConnection {
    public function connect(string $dsn): void;
    public function query(string $sql): array;
}

interface DatabaseMigration {
    public function createTable(string $name): string;
}

// Concrete Products - PostgreSQL
class PostgreSQLConnection implements DatabaseConnection {
    public function connect(string $dsn): void {
        // PostgreSQL connection logic
    }

    public function query(string $sql): array {
        return ['postgresql_results'];
    }
}

class PostgreSQLMigration implements DatabaseMigration {
    public function createTable(string $name): string {
        return "CREATE TABLE IF NOT EXISTS {$name} ...";
    }
}

// Concrete Products - MySQL
class MySQLConnection implements DatabaseConnection {
    public function connect(string $dsn): void {
        // MySQL connection logic
    }

    public function query(string $sql): array {
        return ['mysql_results'];
    }
}

class MySQLMigration implements DatabaseMigration {
    public function createTable(string $name): string {
        return "CREATE TABLE IF NOT EXISTS {$name} ...";
    }
}

// Abstract Factory
interface DatabaseFactory {
    public function createConnection(): DatabaseConnection;
    public function createMigration(): DatabaseMigration;
}

// Concrete Factories
class PostgreSQLFactory implements DatabaseFactory {
    public function createConnection(): DatabaseConnection {
        return new PostgreSQLConnection();
    }

    public function createMigration(): DatabaseMigration {
        return new PostgreSQLMigration();
    }
}

class MySQLFactory implements DatabaseFactory {
    public function createConnection(): DatabaseConnection {
        return new MySQLConnection();
    }

    public function createMigration(): DatabaseMigration {
        return new MySQLMigration();
    }
}

// Instantiation
$dbType = getenv('DB_TYPE') ?: 'mysql';
$factory = match($dbType) {
    'postgresql' => new PostgreSQLFactory(),
    'mysql' => new MySQLFactory(),
    default => throw new InvalidArgumentException("Unknown DB type: $dbType"),
};

$connection = $factory->createConnection();
$migration = $factory->createMigration();
```

## Real-World Analogies

**Furniture Showroom by Style**: Picture a showroom organized into curated collections - Mid-Century Modern, Industrial, Scandinavian. Choosing a collection determines every piece you receive (sofa, table, lamp), and the showroom guarantees aesthetic coherence across the set.

**Operating System Widget Toolkits**: Each desktop OS bundles its own control library. The same "create dialog" call yields Windows-native widgets on Windows and macOS-native widgets on macOS, while the application logic remains identical on both platforms.

## Pros and Cons

### Advantages
- **Isolates client code from concrete classes**: All instantiation flows through abstract interfaces, so business logic never references specific product implementations
- **Enforces family coherence**: A single factory produces every related product, eliminating accidental mismatches between incompatible parts
- **Simplifies family extension**: Supporting a new product family means adding one factory class - existing client code stays untouched
- **Localizes construction logic**: Object creation is consolidated in factory implementations rather than spread across consumers
- **Respects the Open/Closed Principle**: Growth happens by introducing new classes, not by editing existing ones

### Disadvantages
- **Increases class count**: Every new family requires a factory class plus one concrete class per product type
- **Overkill for single-family systems**: When only one product family exists, the abstraction layer adds complexity without payoff
- **Painful to expand the product set**: Adding a new product type to the family means modifying every existing factory implementation
- **Limited configuration flexibility**: When individual products need multi-step setup, Abstract Factory alone falls short - Builder is the better companion

## Relations with Other Patterns

- **Factory Method**: Abstract Factory commonly delegates each creation call to an internal Factory Method
- **Singleton**: Concrete factories are frequently singletons, since a single instance per family is usually sufficient
- **Prototype**: Factories can clone pre-configured template objects instead of invoking constructors, combining both patterns
- **Builder**: Builder handles complex, multi-step construction; Abstract Factory handles coordinated creation of simple products across a family
- **Strategy**: Both swap implementations behind an interface, but at different scales - Strategy replaces algorithms, Abstract Factory replaces entire object families

## Examples in Other Languages

### Java

**Example 1: Hardware Architecture Factory**

```java
abstract class CPU {}
abstract class MMU {}

class EmberCPU extends CPU {}
class EmberMMU extends MMU {}
class EnginolaCPU extends CPU {}
class EnginolaMMU extends MMU {}

enum Architecture {
    ENGINOLA, EMBER
}

abstract class AbstractFactory {
    private static final EmberToolkit EMBER_TOOLKIT = new EmberToolkit();
    private static final EnginolaToolkit ENGINOLA_TOOLKIT = new EnginolaToolkit();

    static AbstractFactory getFactory(Architecture architecture) {
        AbstractFactory factory = null;
        switch (architecture) {
            case ENGINOLA:
                factory = ENGINOLA_TOOLKIT;
                break;
            case EMBER:
                factory = EMBER_TOOLKIT;
                break;
        }
        return factory;
    }

    public abstract CPU createCPU();
    public abstract MMU createMMU();
}

class EmberToolkit extends AbstractFactory {
    @Override
    public CPU createCPU() {
        return new EmberCPU();
    }

    @Override
    public MMU createMMU() {
        return new EmberMMU();
    }
}

class EnginolaToolkit extends AbstractFactory {
    @Override
    public CPU createCPU() {
        return new EnginolaCPU();
    }

    @Override
    public MMU createMMU() {
        return new EnginolaMMU();
    }
}

public class Client {
    public static void main(String[] args) {
        AbstractFactory factory = AbstractFactory.getFactory(Architecture.EMBER);
        CPU cpu = factory.createCPU();
    }
}
```

### C++

```cpp
#include <iostream.h>

class Shape {
  public:
    Shape() {
      id_ = total_++;
    }
    virtual void draw() = 0;
  protected:
    int id_;
    static int total_;
};
int Shape::total_ = 0;

class Circle : public Shape {
  public:
    void draw() {
      cout << "circle " << id_ << ": draw" << endl;
    }
};
class Square : public Shape {
  public:
    void draw() {
      cout << "square " << id_ << ": draw" << endl;
    }
};
class Ellipse : public Shape {
  public:
    void draw() {
      cout << "ellipse " << id_ << ": draw" << endl;
    }
};
class Rectangle : public Shape {
  public:
    void draw() {
      cout << "rectangle " << id_ << ": draw" << endl;
    }
};

class Factory {
  public:
    virtual Shape* createCurvedInstance() = 0;
    virtual Shape* createStraightInstance() = 0;
};

class SimpleShapeFactory : public Factory {
  public:
    Shape* createCurvedInstance() {
      return new Circle;
    }
    Shape* createStraightInstance() {
      return new Square;
    }
};
class RobustShapeFactory : public Factory {
  public:
    Shape* createCurvedInstance() {
      return new Ellipse;
    }
    Shape* createStraightInstance() {
      return new Rectangle;
    }
};

int main() {
#ifdef SIMPLE
  Factory* factory = new SimpleShapeFactory;
#elif ROBUST
  Factory* factory = new RobustShapeFactory;
#endif
  Shape* shapes[3];

  shapes[0] = factory->createCurvedInstance();
  shapes[1] = factory->createStraightInstance();
  shapes[2] = factory->createCurvedInstance();

  for (int i=0; i < 3; i++) {
    shapes[i]->draw();
  }
}
```

### Python

```python
import abc


class AbstractFactory(metaclass=abc.ABCMeta):

    @abc.abstractmethod
    def create_product_a(self):
        pass

    @abc.abstractmethod
    def create_product_b(self):
        pass


class ConcreteFactory1(AbstractFactory):

    def create_product_a(self):
        return ConcreteProductA1()

    def create_product_b(self):
        return ConcreteProductB1()


class ConcreteFactory2(AbstractFactory):

    def create_product_a(self):
        return ConcreteProductA2()

    def create_product_b(self):
        return ConcreteProductB2()


class AbstractProductA(metaclass=abc.ABCMeta):

    @abc.abstractmethod
    def interface_a(self):
        pass


class ConcreteProductA1(AbstractProductA):
    def interface_a(self):
        pass


class ConcreteProductA2(AbstractProductA):
    def interface_a(self):
        pass


class AbstractProductB(metaclass=abc.ABCMeta):

    @abc.abstractmethod
    def interface_b(self):
        pass


class ConcreteProductB1(AbstractProductB):
    def interface_b(self):
        pass


class ConcreteProductB2(AbstractProductB):
    def interface_b(self):
        pass


def main():
    for factory in (ConcreteFactory1(), ConcreteFactory2()):
        product_a = factory.create_product_a()
        product_b = factory.create_product_b()
        product_a.interface_a()
        product_b.interface_b()


if __name__ == "__main__":
    main()
```

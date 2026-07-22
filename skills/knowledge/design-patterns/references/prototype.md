# Prototype Design Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem/Solution](#problemsolution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+)](#implementation-php-83)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Prototype is a creational design pattern that creates new objects by copying an existing instance instead of constructing them from scratch. It is most useful when creation is expensive, setup is complex, or you want a catalog of ready-made object templates.

## Intent

- Create new objects by cloning an existing prototype instance
- Avoid the cost of expensive or elaborate construction
- Configure objects by copying a prototype
- Duplicate objects without depending on their concrete class

## Problem/Solution

### Problem
Direct instantiation becomes impractical when:
- Building an object takes significant computation or I/O
- The object has many configuration properties
- You need many slight variations of the same base object
- The concrete type to create is known only at runtime

### Solution
Instead of calling constructors, keep a prototype instance and clone it whenever you need a new object. Client code no longer contains the creation logic, and constructor calls become copy operations.

## Structure

```
Client
  └─ uses ──→ Prototype (interface)
                  ↑
              cloned by
                  │
         ┌────────┴────────┐
         │                 │
    ConcretePrototypeA  ConcretePrototypeB
         │                 │
      clones()           clones()
```

Key participants:
- **Prototype**: Interface declaring the clone method
- **ConcretePrototype**: Implements the clone method
- **Client**: Creates new objects by cloning the prototype

## When to use

- Object construction is costly or involves multi-step initialization
- You want to avoid parallel hierarchies of factory subclasses
- Client code should stay independent of concrete product classes
- Objects must be configured and varied at runtime
- You do not want to expose the internal structure of objects to callers

## Implementation (PHP 8.3+)

### Basic Prototype example

```php
declare(strict_types=1);

namespace DesignPatterns\Creational\Prototype;

interface Shape
{
    public function clone(): self;
    public function __clone(): void;
}

class Circle implements Shape
{
    private float $radius = 0.0;
    private string $color = '';

    public function __construct(float $radius = 0.0, string $color = '')
    {
        $this->radius = $radius;
        $this->color = $color;
    }

    public function clone(): self
    {
        return clone $this;
    }

    public function __clone(): void
    {
        // Deep copy if needed
    }

    public function setRadius(float $radius): void
    {
        $this->radius = $radius;
    }

    public function setColor(string $color): void
    {
        $this->color = $color;
    }

    public function describe(): string
    {
        return "Circle: radius={$this->radius}, color={$this->color}";
    }
}

class Rectangle implements Shape
{
    private float $width = 0.0;
    private float $height = 0.0;
    private string $color = '';

    public function __construct(float $width = 0.0, float $height = 0.0, string $color = '')
    {
        $this->width = $width;
        $this->height = $height;
        $this->color = $color;
    }

    public function clone(): self
    {
        return clone $this;
    }

    public function __clone(): void
    {
        // Deep copy if needed
    }

    public function setWidth(float $width): void
    {
        $this->width = $width;
    }

    public function setHeight(float $height): void
    {
        $this->height = $height;
    }

    public function setColor(string $color): void
    {
        $this->color = $color;
    }

    public function describe(): string
    {
        return "Rectangle: width={$this->width}, height={$this->height}, color={$this->color}";
    }
}

// Usage
$originalCircle = new Circle(5.0, 'red');
$clonedCircle = $originalCircle->clone();
$clonedCircle->setRadius(10.0);

echo $originalCircle->describe(); // Circle: radius=5, color=red
echo $clonedCircle->describe();   // Circle: radius=10, color=red
```

### Advanced example with a prototype registry

```php
declare(strict_types=1);

namespace DesignPatterns\Creational\Prototype;

class PrototypeRegistry
{
    /** @var array<string, Shape> */
    private array $prototypes = [];

    public function register(string $key, Shape $prototype): void
    {
        $this->prototypes[$key] = $prototype;
    }

    public function create(string $key): ?Shape
    {
        return isset($this->prototypes[$key]) ? $this->prototypes[$key]->clone() : null;
    }

    public function getAll(): array
    {
        return array_keys($this->prototypes);
    }
}

// Usage with Registry
$registry = new PrototypeRegistry();

$blueCircle = new Circle(5.0, 'blue');
$redRectangle = new Rectangle(10.0, 20.0, 'red');

$registry->register('small_blue_circle', $blueCircle);
$registry->register('large_red_rectangle', $redRectangle);

// Create clones from registry
$newCircle = $registry->create('small_blue_circle');
$newRectangle = $registry->create('large_red_rectangle');

if ($newCircle) {
    $newCircle->setColor('green');
    echo $newCircle->describe();
}
```

### Complex object with deep cloning

```php
declare(strict_types=1);

namespace DesignPatterns\Creational\Prototype;

class Document implements Shape
{
    private string $title = '';
    /** @var array<string, mixed> */
    private array $content = [];
    private ?Author $author = null;

    public function __construct(string $title = '', ?Author $author = null)
    {
        $this->title = $title;
        $this->author = $author;
    }

    public function setAuthor(?Author $author): void
    {
        $this->author = $author;
    }

    public function addContent(string $key, mixed $value): void
    {
        $this->content[$key] = $value;
    }

    public function clone(): self
    {
        return clone $this;
    }

    public function __clone(): void
    {
        // Deep copy of nested objects
        if ($this->author !== null) {
            $this->author = clone $this->author;
        }
        $this->content = array_map(function (mixed $item): mixed {
            return is_object($item) ? clone $item : $item;
        }, $this->content);
    }

    public function describe(): string
    {
        $authorName = $this->author?->getName() ?? 'Unknown';
        return "Document: title={$this->title}, author={$authorName}";
    }
}

class Author
{
    public function __construct(private string $name) {}

    public function getName(): string
    {
        return $this->name;
    }
}

// Usage
$author = new Author('John Doe');
$doc1 = new Document('Report', $author);
$doc1->addContent('section1', 'Introduction');

$doc2 = $doc1->clone();
echo $doc1->describe(); // Document: title=Report, author=John Doe
echo $doc2->describe(); // Document: title=Report, author=John Doe
```

## Real-world analogies

- **Photocopier**: You place an original on the glass and the machine produces identical copies on demand
- **DNA replication**: Before a cell divides, it copies its genetic material
- **Application templates**: Deployment tools create identical installations from a golden image
- **Game asset cloning**: Game engines duplicate enemy or item prototypes at runtime instead of rebuilding each one
- **Database snapshots**: A snapshot captures the current state of a database so it can be reproduced elsewhere

## Pros and cons

### Advantages
- Cuts the cost of creating complex, heavily initialized objects
- No need for parallel factory subclass hierarchies
- Simpler initialization when configuration is elaborate
- New object types can appear at runtime through cloning
- Pre-built object templates are reused
- Client code stays independent of concrete product classes

### Disadvantages
- Implementing clone() correctly is hard when objects contain circular references
- Deep copying can cost more than fresh construction
- Every clone() method must be updated whenever the object's internal structure changes
- Can hide the real dependencies between objects
- Confusing shallow and deep copy semantics causes bugs

## Relations with other patterns

- **Abstract Factory**: Both hide creation, but Prototype copies while Abstract Factory calls constructors
- **Factory Method**: Both hide creation details; Factory Method builds new instances, Prototype duplicates existing ones
- **Singleton**: Opposite goals: Singleton restricts a class to one instance, Prototype produces many copies
- **Builder**: Both deal with complex object assembly; Builder works step by step, Prototype in a single copy
- **Composite**: Often combined with Prototype to clone whole tree structures
- **Decorator**: Can be paired with Prototype to clone decorated objects

## Examples in other languages

### Java

```java
interface Person {
    Person clone();
}

class Tom implements Person {
    private final String NAME = "Tom";

    @Override
    public Person clone() {
        return new Tom();
    }

    @Override
    public String toString() {
        return NAME;
    }
}

class Dick implements Person {
    private final String NAME = "Dick";

    @Override
    public Person clone() {
        return new Dick();
    }

    @Override
    public String toString() {
        return NAME;
    }
}

class Harry implements Person {
    private final String NAME = "Harry";

    @Override
    public Person clone() {
        return new Harry();
    }

    @Override
    public String toString() {
        return NAME;
    }
}

class Factory {
    private static final Map<String, Person> prototypes = new HashMap<>();

    static {
        prototypes.put("tom", new Tom());
        prototypes.put("dick", new Dick());
        prototypes.put("harry", new Harry());
    }

    public static Person getPrototype(String type) {
        try {
            return prototypes.get(type).clone();
        } catch (NullPointerException ex) {
            System.out.println("Prototype with name: " + type + ", doesn't exist");
            return null;
        }
    }
}

public class PrototypeFactory {
    public static void main(String[] args) {
        if (args.length > 0) {
            for (String type : args) {
                Person prototype = Factory.getPrototype(type);
                if (prototype != null) {
                    System.out.println(prototype);
                }
            }
        } else {
            System.out.println("Run again with arguments of command string ");
        }
    }
}
```

### C++

**Before: client depends on concrete classes**

```cpp
class Stooge {
  public:
    virtual void slap_stick() = 0;
};

class Larry: public Stooge {
  public:
    void slap_stick() {
        cout << "Larry: poke eyes\n";
    }
};
class Moe: public Stooge {
  public:
    void slap_stick() {
        cout << "Moe: slap head\n";
    }
};
class Curly: public Stooge {
  public:
    void slap_stick() {
        cout << "Curly: suffer abuse\n";
    }
};

int main() {
  vector roles;
  int choice;
  while (true) {
    cout << "Larry(1) Moe(2) Curly(3) Go(0): ";
    cin >> choice;
    if (choice == 0) break;
    else if (choice == 1) roles.push_back(new Larry);
    else if (choice == 2) roles.push_back(new Moe);
    else roles.push_back(new Curly);
  }
  for (int i = 0; i < roles.size(); i++)
    roles[i]->slap_stick();
  for (int i = 0; i < roles.size(); i++)
    delete roles[i];
}
```

**After: prototype-based creation with clone()**

```cpp
class Stooge {
public:
   virtual Stooge* clone() = 0;
   virtual void slap_stick() = 0;
};

class Factory {
public:
   static Stooge* make_stooge(int choice);
private:
   static Stooge* s_prototypes[4];
};

class Larry : public Stooge {
public:
   Stooge* clone() { return new Larry; }
   void slap_stick() {
      cout << "Larry: poke eyes\n"; }
};

class Moe : public Stooge {
public:
   Stooge* clone() { return new Moe; }
   void slap_stick() {
      cout << "Moe: slap head\n"; }
};

class Curly : public Stooge {
public:
   Stooge* clone() { return new Curly; }
   void slap_stick() {
      cout << "Curly: suffer abuse\n"; }
};

Stooge* Factory::s_prototypes[] = {
   0, new Larry, new Moe, new Curly
};

Stooge* Factory::make_stooge(int choice) {
   return s_prototypes[choice]->clone();
}

int main() {
   vector roles;
   int choice;
   while (true) {
      cout << "Larry(1) Moe(2) Curly(3) Go(0): ";
      cin >> choice;
      if (choice == 0) break;
      roles.push_back(Factory::make_stooge(choice));
   }
   for (int i=0; i < roles.size(); ++i)
      roles[i]->slap_stick();
   for (int i=0; i < roles.size(); ++i)
      delete roles[i];
}
```

### Python

```python
import copy

class Prototype:
    """
    Example class to be copied.
    """
    pass

def main():
    prototype = Prototype()
    prototype_copy = copy.deepcopy(prototype)

if __name__ == "__main__":
    main()
```

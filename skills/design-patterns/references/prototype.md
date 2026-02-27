# Prototype Design Pattern

## Overview

The Prototype pattern is a creational design pattern that allows you to create new objects by copying an existing object (the prototype) rather than creating them from scratch. This is particularly useful when object creation is expensive, complex, or when you need to maintain a registry of pre-configured objects.

## Intent

- Create new objects by cloning an existing prototype object
- Reduce the cost of creating new objects when instantiation is expensive
- Allow configuration of objects through prototypical inheritance
- Provide a way to create a copy of an object without relying on its concrete class

## Problem/Solution

### Problem
Creating objects directly can be costly when:
- Object initialization is computationally expensive
- The object has many configuration properties
- You need to create multiple similar variations of an object
- The exact type of object isn't known at runtime

### Solution
Instead of creating objects through their constructors, define a prototype object and clone it. This separates object creation logic from the client code and enables creating objects through copying rather than instantiation.

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

## When to Use

- Creating objects through direct instantiation is expensive or complex
- You need to avoid subclasses of an abstract class
- You want to decouple object creation from their concrete classes
- Runtime configuration of objects is required
- You need to copy objects while maintaining type safety
- Avoiding deep knowledge of object structure is important

## Implementation (PHP 8.3+)

### Basic Prototype Example

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

### Advanced Example with Prototype Registry

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

### Complex Object with Deep Cloning

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

## Real-World Analogies

- **Photocopier**: Making copies of documents - you provide an original, the copier creates duplicates
- **DNA Replication**: Cells duplicate their DNA before division, creating copies of genetic information
- **Application Templates**: Software installers that clone a template installation to multiple machines
- **Game Asset Cloning**: Video games cloning enemy/object prototypes rather than recreating from scratch
- **Database Snapshots**: Creating database snapshots by copying the prototype configuration

## Pros and Cons

### Advantages
- Reduces object creation cost for complex objects
- Avoids subclassing to support different object variations
- Simplifies object initialization when configuration is complex
- Allows runtime creation of new object types
- Efficient copying of pre-configured objects
- Decouples clients from concrete classes

### Disadvantages
- Implementing clone() correctly can be complex, especially with circular references
- Deep cloning can be more expensive than object creation
- All clone() methods must be maintained when object structure changes
- Can hide actual object dependencies and coupling
- May introduce subtle bugs if shallow vs. deep copy semantics aren't clear

## Relations with Other Patterns

- **Abstract Factory**: Both abstract object creation, but Prototype uses copying while Abstract Factory uses direct instantiation
- **Factory Method**: Similar intent but Prototype clones existing objects while Factory Method creates new ones
- **Singleton**: Opposite approach - Singleton ensures one instance, Prototype creates many
- **Builder**: Both handle complex object creation; Builder constructs step-by-step, Prototype copies
- **Composite**: Often used with Prototype to clone tree structures
- **Decorator**: Can be combined with Prototype for object composition

---

*Last updated: February 2026*

## Examples in Other Languages

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

*Source: [sourcemaking.com/design_patterns/prototype](https://sourcemaking.com/design_patterns/prototype)*

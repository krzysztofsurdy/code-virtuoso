# Prototype Design Pattern

## Overview

The Prototype pattern is a creational design pattern that produces new objects by duplicating an existing instance rather than constructing them from scratch. It is especially valuable when object creation is resource-intensive, involves complex setup, or when you want to maintain a catalog of ready-made object templates.

## Intent

- Generate new objects by cloning a pre-existing prototype instance
- Avoid the overhead of expensive or elaborate construction processes
- Support configuring objects through prototype-based copying
- Enable object duplication without depending on the concrete class

## Problem/Solution

### Problem
Direct instantiation becomes impractical when:
- Building an object requires significant computation or I/O
- The object carries numerous configuration properties
- You need many slight variations of the same base object
- The concrete type to create is determined only at runtime

### Solution
Rather than invoking constructors directly, designate a prototype instance and clone it whenever a new object is needed. This decouples the creation logic from client code and replaces constructor calls with copy operations.

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

- Object construction is costly or involves multi-step initialization
- You want to sidestep creating parallel hierarchies of factory subclasses
- Client code should remain independent of concrete product classes
- Objects need to be configured and varied at runtime
- Type-safe copying of objects is required
- You prefer not to expose the internal structure of objects to callers

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

- **Photocopier**: You place an original document on the glass and the machine produces identical duplicates on demand
- **DNA Replication**: Before a cell divides, it creates a full copy of its genetic material to pass along
- **Application Templates**: Software deployment tools stamp out identical installations from a golden image
- **Game Asset Cloning**: Game engines duplicate enemy or item prototypes at runtime instead of rebuilding each one from scratch
- **Database Snapshots**: A snapshot captures the current configuration of a database so it can be reproduced elsewhere

## Pros and Cons

### Advantages
- Cuts down the cost of creating complex, heavily initialized objects
- Eliminates the need for parallel factory subclass hierarchies
- Streamlines initialization when configuration is elaborate
- Permits new object types to appear at runtime through cloning
- Efficient reuse of pre-built object templates
- Keeps client code independent of concrete product classes

### Disadvantages
- Correctly implementing clone() is difficult when objects contain circular references
- Deep copying can sometimes be more expensive than fresh construction
- Every clone() method must be updated whenever the object's internal structure changes
- May obscure the true dependencies between objects
- Bugs can creep in when shallow and deep copy semantics are confused

## Relations with Other Patterns

- **Abstract Factory**: Both abstract away creation, but Prototype relies on copying while Abstract Factory calls constructors
- **Factory Method**: Shares the goal of hiding creation details; Factory Method builds new instances, Prototype duplicates existing ones
- **Singleton**: Conceptually opposite - Singleton restricts to one instance, Prototype encourages many copies
- **Builder**: Both tackle complex object assembly; Builder does it step by step, Prototype does it in a single copy
- **Composite**: Frequently combined with Prototype to clone entire tree structures
- **Decorator**: Can be paired with Prototype to clone decorated objects

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

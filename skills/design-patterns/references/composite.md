## Overview

The Composite pattern is a structural design pattern that lets you compose objects into tree structures to represent part-whole hierarchies. It allows clients to treat individual objects and compositions of objects uniformly, simplifying client code when working with tree-like structures.

## Intent

- Compose objects into tree structures to represent part-whole hierarchies
- Let clients treat individual objects and compositions of objects uniformly
- Simplify client code by enabling recursive composition

## Problem and Solution

**Problem:** When building hierarchical structures (file systems, organizational charts, UI component trees), client code must distinguish between leaf nodes and container nodes. This creates complexity and makes it difficult to work with the hierarchy uniformly.

**Solution:** The Composite pattern defines a common interface for both leaf objects and container objects. Container objects can hold both leaf and other container objects, creating a recursive tree structure. All objects in the tree implement the same interface, allowing uniform treatment.

## Structure

### Key Components

- **Component**: Abstract interface defining common operations for both leaf and composite objects
- **Leaf**: Represents leaf objects with no children; implements component operations
- **Composite**: Represents container objects that can hold children (leaves or other composites); implements component operations by delegating to children
- **Client**: Works with objects through the component interface

## When to Use

1. **Hierarchical structures** - File systems, organizational charts, menu systems
2. **Tree representations** - DOM trees, widget hierarchies, menu trees
3. **Recursive composition** - Objects composed of similar objects in tree structure
4. **Uniform treatment** - Need to treat single objects and compositions identically
5. **Reduce client complexity** - Avoid if-else logic to determine object type

## Implementation (PHP 8.3+)

```php
<?php

declare(strict_types=1);

namespace DesignPatterns\Structural\Composite;

/**
 * Component - Common interface for leaves and composites
 */
readonly interface Component
{
    public function getOperation(): string;
}

/**
 * Leaf - Represents leaf objects with no children
 */
final readonly class Leaf implements Component
{
    public function __construct(private string $name)
    {
    }

    public function getOperation(): string
    {
        return "Leaf({$this->name})";
    }
}

/**
 * Composite - Represents container objects that hold children
 */
final class Composite implements Component
{
    /** @var list<Component> */
    private array $children = [];

    public function __construct(private readonly string $name)
    {
    }

    public function add(Component $component): void
    {
        $this->children[] = $component;
    }

    public function remove(Component $component): void
    {
        $this->children = array_filter(
            $this->children,
            fn(Component $child) => $child !== $component
        );
    }

    public function getOperation(): string
    {
        $childResults = array_map(
            fn(Component $child) => $child->getOperation(),
            $this->children
        );

        $result = "Composite({$this->name}";
        if (!empty($childResults)) {
            $result .= ": " . implode(", ", $childResults);
        }
        $result .= ")";

        return $result;
    }

    /**
     * Returns count of all children recursively
     */
    public function getChildCount(): int
    {
        $count = count($this->children);

        foreach ($this->children as $child) {
            if ($child instanceof self) {
                $count += $child->getChildCount();
            }
        }

        return $count;
    }
}

// Usage Example
$root = new Composite("root");
$root->add(new Leaf("leaf-1"));
$root->add(new Leaf("leaf-2"));

$branch = new Composite("branch");
$branch->add(new Leaf("leaf-3"));
$branch->add(new Leaf("leaf-4"));

$root->add($branch);

echo $root->getOperation();
// Output: Composite(root: Leaf(leaf-1), Leaf(leaf-2), Composite(branch: Leaf(leaf-3), Leaf(leaf-4)))

echo "Total children: " . $root->getChildCount(); // Output: Total children: 4
```

## Real-World Analogies

- **File System**: Directories can contain files and other directories recursively
- **Organizational Structure**: Departments contain employees and sub-departments
- **UI Components**: Panels contain buttons, text fields, and other panels
- **HTML DOM**: Elements can contain other elements forming a tree
- **Menu Systems**: Menus contain menu items and sub-menus

## Advantages

- Simplifies client code by treating single and composite objects uniformly
- Makes adding new component types easy (Open/Closed Principle)
- Enables elegant representation of tree hierarchies
- Allows recursive composition for arbitrary depth
- Simplifies algorithms that operate on tree structures

## Disadvantages

- Can make the design overly general; leaf nodes may not need all operations
- Type safety is reduced; client cannot restrict what types are added to composites
- Performance overhead for operations on large trees
- May violate Single Responsibility Principle if component interface is too broad

## Relations with Other Patterns

- **Iterator**: Often used to traverse composite structures without exposing internal structure
- **Visitor**: Enables performing operations on composite trees without modifying structures
- **Factory Method**: Creates complex composite trees
- **Singleton**: Root nodes are often singletons
- **Decorator**: Both allow recursive composition, but Decorator adds responsibilities while Composite represents part-whole hierarchies
- **Strategy**: Can encapsulate different composition algorithms

## Variations

- **Type-Safe Composite**: Generic composite restricting child types
- **File System Model**: With operations like `getSize()`, `getPath()`
- **UI Component Model**: With rendering operations and event handling
- **Tree Iterator**: Integrated iteration strategies (preorder, postorder, levelorder)

## Examples in Other Languages

### Java

Before and after example using a file system hierarchy:

```java
// Common interface for leaves and composites
interface AbstractFile {
    void ls();
}

class File implements AbstractFile {
    private String name;
    public File(String name) { this.name = name; }
    public void ls() {
        System.out.println(CompositeDemo.compositeBuilder + name);
    }
}

class Directory implements AbstractFile {
    private String name;
    private ArrayList includedFiles = new ArrayList();

    public Directory(String name) { this.name = name; }
    public void add(Object obj) { includedFiles.add(obj); }

    public void ls() {
        System.out.println(CompositeDemo.compositeBuilder + name);
        CompositeDemo.compositeBuilder.append("   ");
        for (Object includedFile : includedFiles) {
            AbstractFile obj = (AbstractFile) includedFile;
            obj.ls();
        }
        CompositeDemo.compositeBuilder.setLength(
            CompositeDemo.compositeBuilder.length() - 3);
    }
}

public class CompositeDemo {
    public static StringBuffer compositeBuilder = new StringBuffer();

    public static void main(String[] args) {
        Directory music = new Directory("MUSIC");
        Directory scorpions = new Directory("SCORPIONS");
        Directory dio = new Directory("DIO");
        File track1 = new File("Don't wary, be happy.mp3");
        File track2 = new File("track2.m3u");
        File track3 = new File("Wind of change.mp3");
        File track4 = new File("Big city night.mp3");
        File track5 = new File("Rainbow in the dark.mp3");
        music.add(track1);
        music.add(scorpions);
        music.add(track2);
        scorpions.add(track3);
        scorpions.add(track4);
        scorpions.add(dio);
        dio.add(track5);
        music.ls();
    }
}
```

### C++

```cpp
#include <iostream>
#include <vector>
using namespace std;

class Component {
  public:
    virtual void traverse() = 0;
};

class Leaf: public Component {
    int value;
  public:
    Leaf(int val) { value = val; }
    void traverse() { cout << value << ' '; }
};

class Composite: public Component {
    vector<Component*> children;
  public:
    void add(Component *ele) { children.push_back(ele); }
    void traverse() {
        for (int i = 0; i < children.size(); i++)
            children[i]->traverse();
    }
};

int main() {
    Composite containers[4];
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 3; j++)
            containers[i].add(new Leaf(i * 3 + j));

    for (int i = 1; i < 4; i++)
        containers[0].add(&(containers[i]));

    for (int i = 0; i < 4; i++) {
        containers[i].traverse();
        cout << endl;
    }
}
```

### Python

```python
import abc


class Component(metaclass=abc.ABCMeta):
    """
    Declare the interface for objects in the composition.
    """
    @abc.abstractmethod
    def operation(self):
        pass


class Composite(Component):
    """
    Define behavior for components having children.
    Store child components.
    """
    def __init__(self):
        self._children = set()

    def operation(self):
        for child in self._children:
            child.operation()

    def add(self, component):
        self._children.add(component)

    def remove(self, component):
        self._children.discard(component)


class Leaf(Component):
    """
    Represent leaf objects in the composition. A leaf has no children.
    """
    def operation(self):
        pass


def main():
    leaf = Leaf()
    composite = Composite()
    composite.add(leaf)
    composite.operation()


if __name__ == "__main__":
    main()
```

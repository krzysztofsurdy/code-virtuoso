# Composite Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+)](#implementation-php-83)
- [Real-world analogies](#real-world-analogies)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Relations with other patterns](#relations-with-other-patterns)
- [Variations](#variations)
- [Examples in other languages](#examples-in-other-languages)

## Overview

The Composite pattern is a structural design pattern that organizes objects into tree hierarchies where leaves and branches conform to a shared interface. Because individual elements and groups of elements expose the same operations, client code treats both uniformly and never needs to ask whether a node is a single item or a whole subtree.

## Intent

- Model whole-part relationships as recursive tree structures with a uniform component interface
- Allow clients to handle individual objects and nested collections through identical method calls
- Remove type-checking conditionals from client code by making leaf and composite nodes interchangeable

## Problem and solution

**Problem:** Tree-shaped data (file systems, organizational hierarchies, nested UI menus) forces client code to distinguish individual items from containers in every operation. That type-checking spreads as the hierarchy deepens and becomes a maintenance burden whenever the structure changes.

**Solution:** Define a common component interface that both leaf and container classes implement. Containers forward operations to their children recursively, so clients traverse and manipulate the whole tree through one API without inspecting node types.

## Structure

### Key components

- **Component**: Abstract interface defining common operations for both leaf and composite objects
- **Leaf**: Represents leaf objects with no children; implements component operations
- **Composite**: Represents container objects that can hold children (leaves or other composites); implements component operations by delegating to children
- **Client**: Works with objects through the component interface

## When to use

1. **Hierarchical structures**: file systems, organizational charts, menu systems
2. **Tree representations**: DOM trees, widget hierarchies, menu trees
3. **Recursive composition**: objects composed of similar objects in a tree
4. **Uniform treatment**: single objects and compositions must be handled identically
5. **Simpler clients**: avoid if-else logic that checks object type

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

## Real-world analogies

- **Military Chain of Command**: A division comprises brigades, brigades comprise battalions, and battalions comprise soldiers. An order issued at division level cascades down through every tier, and each level acts on it through the same command interface.
- **Nested Shipping Containers**: A cargo ship carries containers, some filled with individual crates and others holding smaller containers packed with goods. Computing total weight follows the same recursive logic regardless of nesting depth.
- **Corporate Budget Aggregation**: Each department totals the budgets of its teams, each team totals the budgets of its projects, and each project carries a fixed amount. The summation operation is identical at every level of the hierarchy.

## Advantages

- Clients operate on the tree through a single interface, whether they reach a leaf or a whole subtree
- New node types need no changes to existing traversal or processing logic
- Maps directly onto recursive, tree-shaped data with little boilerplate
- Handles arbitrarily deep nesting without extra branching in client code
- Tree-wide algorithms reduce to simple recursive calls

## Disadvantages

- The shared interface may force leaves to expose methods that mean nothing for them
- Compile-time safety is weaker, because the component interface cannot restrict which child types a composite accepts
- Full traversals of deep or wide trees add up in cost
- An overly broad component interface can mix unrelated responsibilities into one contract

## Relations with other patterns

- **Iterator**: Commonly used to traverse composite trees without exposing their internal structure
- **Visitor**: Introduces new operations to composite hierarchies without touching existing node classes
- **Factory Method**: Helps construct complex composite trees programmatically
- **Singleton**: The root node of a globally shared composite tree is sometimes a singleton
- **Decorator**: Both use recursive composition, but Decorator adds behavior to a single object while Composite models containment
- **Strategy**: Alternate traversal or aggregation algorithms can be plugged in via Strategy

## Variations

- **Type-safe composite**: generic composite that restricts child types
- **File system model**: operations like `getSize()` and `getPath()`
- **UI component model**: rendering operations and event handling
- **Tree iterator**: built-in iteration strategies (preorder, postorder, levelorder)

## Examples in other languages

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

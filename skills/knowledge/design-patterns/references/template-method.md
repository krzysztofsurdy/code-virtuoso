## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem](#problem)
- [Solution](#solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Key takeaways](#key-takeaways)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Template Method is a behavioral design pattern that defines the skeleton of an algorithm in a base class and lets subclasses override specific steps without changing the algorithm's structure. The invariant parts are written once and only the varying parts are overridden, which reduces duplication while the base class keeps control of the flow.

## Intent

- Define the skeleton of an algorithm in a method, deferring some steps to subclasses
- Let subclasses redefine certain steps without changing the algorithm's structure
- Reuse code by moving the common algorithm structure into a base class
- Enforce a template that subclasses must follow
- Invert the control flow (Hollywood Principle: "Don't call us, we'll call you")

## Problem

Several classes need similar algorithms with minor variations:
- Implementing similar algorithms in multiple classes duplicates code
- Changing the algorithm structure means changes in many places
- It is unclear which parts of the algorithm are customizable and which are fixed
- Subclasses may implement the algorithm inconsistently
- Business logic and framework logic become intertwined

## Solution

Move the common algorithm structure into a base class as a template method. Declare abstract or empty methods for the steps that vary. Subclasses implement those methods, and the template method runs the overall flow, which keeps implementations consistent and shares the common code.

## Structure

```
┌─────────────────────┐
│   AbstractClass     │
├─────────────────────┤
│ + templateMethod()  │ (defines algorithm skeleton)
│ # primitiveOp1()    │ (abstract - to be overridden)
│ # primitiveOp2()    │ (abstract - to be overridden)
│ # primitiveOp3()    │ (hook method - optional override)
└──────────┬──────────┘
           ▲
           │ inherits
     ┌─────┴─────────────────────┐
     │                           │
┌────┴───────────────┐    ┌──────┴──────────────┐
│ ConcreteClassA     │    │ ConcreteClassB      │
├────────────────────┤    ├─────────────────────┤
│ # primitiveOp1()   │    │ # primitiveOp1()    │
│ # primitiveOp2()   │    │ # primitiveOp2()    │
│ # primitiveOp3()   │    │ # primitiveOp3()    │
└────────────────────┘    └─────────────────────┘
```

**Key components:**
- **AbstractClass:** Defines the template method and abstract primitive operations
- **ConcreteClass:** Implements the abstract methods (primitive operations)
- **Hook Method:** Optional methods that subclasses may override (default behavior provided)
- **Template Method:** Controls the algorithm flow by calling primitive operations

## When to use

- Implementing multiple algorithms with a similar structure
- Extracting common code from similar classes
- Framework design where the framework controls the flow
- Algorithms with multiple variants (document processing, data export formats)
- Implementing lifecycle hooks (initialization, processing, cleanup)
- Data transformation pipelines with standard steps
- Test fixtures with setup/teardown patterns

## Implementation

### PHP 8.3+ strict types

```php
<?php

declare(strict_types=1);

namespace DesignPatterns\TemplateMethod;

/**
 * Abstract base class defining the template algorithm skeleton
 */
abstract class DataProcessor
{
    /**
     * Template Method - defines the algorithm structure
     * This method is the template that subclasses follow
     */
    final public function process(string $data): string
    {
        // Step 1: Validate input
        $this->validate($data);

        // Step 2: Transform data
        $transformed = $this->transform($data);

        // Step 3: Optional hook - before export
        $this->beforeExport($transformed);

        // Step 4: Export/Format result
        $result = $this->export($transformed);

        // Step 5: Optional hook - after export
        $this->afterExport($result);

        return $result;
    }

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function validate(string $data): void;

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function transform(string $data): string;

    /**
     * Primitive operation - must be implemented by subclasses
     */
    abstract protected function export(string $data): string;

    /**
     * Hook Method - optional, can be overridden by subclasses
     * Default implementation does nothing
     */
    protected function beforeExport(string $data): void
    {
        // Hook: subclasses may override for pre-export logic
    }

    /**
     * Hook Method - optional, can be overridden by subclasses
     */
    protected function afterExport(string $result): void
    {
        // Hook: subclasses may override for post-export logic
    }
}

/**
 * Concrete implementation for CSV format
 */
class CsvProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        $lines = explode("\n", trim($data));
        return implode('|', $lines); // Transform to pipe-separated format
    }

    protected function export(string $data): string
    {
        return "CSV:\n" . str_replace('|', ',', $data);
    }

    protected function beforeExport(string $data): void
    {
        echo "Preparing CSV export...\n";
    }
}

/**
 * Concrete implementation for JSON format
 */
class JsonProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        return json_encode(
            array_map('trim', explode("\n", $data)),
            JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR
        );
    }

    protected function export(string $data): string
    {
        return json_decode($data, associative: true) !== null
            ? "JSON:\n" . $data
            : throw new \RuntimeException('Invalid JSON data');
    }

    protected function afterExport(string $result): void
    {
        echo "JSON export completed successfully.\n";
    }
}

/**
 * Concrete implementation for XML format
 */
class XmlProcessor extends DataProcessor
{
    protected function validate(string $data): void
    {
        if (empty($data)) {
            throw new \InvalidArgumentException('Data cannot be empty');
        }
    }

    protected function transform(string $data): string
    {
        $lines = array_map('trim', explode("\n", $data));
        $items = array_map(
            fn($line) => "<item>{$line}</item>",
            $lines
        );
        return implode("\n", $items);
    }

    protected function export(string $data): string
    {
        return "<?xml version=\"1.0\"?>\n<root>\n$data\n</root>";
    }
}

// Usage
$data = "item1\nitem2\nitem3";

$csvProcessor = new CsvProcessor();
echo $csvProcessor->process($data);
echo "\n---\n";

$jsonProcessor = new JsonProcessor();
echo $jsonProcessor->process($data);
echo "\n---\n";

$xmlProcessor = new XmlProcessor();
echo $xmlProcessor->process($data);
```

## Real-world analogies

**Document generation pipeline:** A document generator defines a template method with these steps: load template → fill placeholders → apply formatting → export to file. Document types (PDF, Word, HTML) override the formatting and export steps and follow the same process.

**Cooking recipe:** A recipe is a template method. The basic structure is: gather ingredients → prepare → cook → season → serve. Individual dishes override specific steps (cooking temperature, seasoning) and keep the same general process.

**Software build process:** A build system defines the steps: checkout code → compile → run tests → package → deploy. Projects override specific steps but keep the same pipeline structure.

**Web request lifecycle:** Frameworks such as Symfony use template methods in middleware and controllers: receive request → authenticate → validate → process → format response. Developers override process() while the framework controls the flow.

## Pros and cons

### Pros
- Less code duplication through reuse
- A stable algorithm structure for subclasses to extend
- Consistent algorithm implementation across variations
- Follows the Hollywood Principle (inversion of control)
- New variations can be added without modifying existing code
- Invariant code is separated from variable code
- Algorithm logic lives in one place, which helps maintenance

### Cons
- Needs careful design to tell invariant parts from variable ones
- Inheritance-based, so more rigid than composition
- Can lead to deep inheritance hierarchies
- Subclasses can only override the predefined steps and hooks
- Algorithm changes that affect several subclasses are hard to handle
- Protected methods can be fragile
- Can violate the Liskov Substitution Principle if subclasses do not respect the contract

## Relations with other patterns

- **Strategy:** Both allow varying algorithm behavior; Strategy uses composition, Template Method uses inheritance
- **Factory Method:** Often used within template methods to create objects
- **Hook Method:** Part of Template Method pattern for optional customization points
- **Decorator:** Can wrap template method classes but does not define an algorithm skeleton
- **Abstract Factory:** Can work together; factory creates template method instances
- **State:** Can be combined where state changes trigger different algorithm paths
- **Observer:** Can notify observers at key template method steps
- **Chain of Responsibility:** Can implement steps as a chain in template methods

## Key takeaways

Template Method is the standard way to share an algorithm skeleton, and it fits framework design and groups of classes with similar algorithms. Use hook methods to add extension points that do not force subclasses to implement anything. Watch inheritance depth, and move to a composition-based approach (Strategy) if the hierarchy gets complex.

## Examples in other languages

### Java

```java
abstract class Generalization {
    // Template method - defines algorithm skeleton
    void findSolution() {
        stepOne();
        stepTwo();
        stepThr();
        stepFor();
    }

    private void stepOne() {
        System.out.println("Generalization.stepOne");
    }

    abstract void stepTwo();
    abstract void stepThr();

    void stepFor() {
        System.out.println("Generalization.stepFor");
    }
}

abstract class Specialization extends Generalization {
    protected void stepThr() {
        step3_1();
        step3_2();
        step3_3();
    }

    private void step3_1() {
        System.out.println("Specialization.step3_1");
    }

    abstract protected void step3_2();

    private void step3_3() {
        System.out.println("Specialization.step3_3");
    }
}

class Realization extends Specialization {
    protected void stepTwo() {
        System.out.println("Realization.stepTwo");
    }

    protected void step3_2() {
        System.out.println("Realization.step3_2");
    }

    protected void stepFor() {
        System.out.println("Realization.stepFor");
        super.stepFor();
    }
}

public class TemplateMethodDemo {
    public static void main(String[] args) {
        Generalization algorithm = new Realization();
        algorithm.findSolution();
    }
}
```

### Python

```python
import abc

class AbstractClass(metaclass=abc.ABCMeta):
    """
    Define abstract primitive operations that concrete subclasses define
    to implement steps of an algorithm.
    Implement a template method defining the skeleton of an algorithm.
    """

    def template_method(self):
        self._primitive_operation_1()
        self._primitive_operation_2()

    @abc.abstractmethod
    def _primitive_operation_1(self):
        pass

    @abc.abstractmethod
    def _primitive_operation_2(self):
        pass

class ConcreteClass(AbstractClass):
    """
    Implement the primitive operations to carry out
    subclass-specific steps of the algorithm.
    """

    def _primitive_operation_1(self):
        pass

    def _primitive_operation_2(self):
        pass

def main():
    concrete_class = ConcreteClass()
    concrete_class.template_method()

if __name__ == "__main__":
    main()
```

### C++

#### Example 1: Basic Template Method

```cpp
#include <iostream>
using namespace std;

class Base {
    void a() { cout << "a  "; }
    void c() { cout << "c  "; }
    void e() { cout << "e  "; }
    virtual void ph1() = 0;
    virtual void ph2() = 0;
  public:
    void execute() {
        a();
        ph1();
        c();
        ph2();
        e();
    }
};

class One: public Base {
    void ph1() { cout << "b  "; }
    void ph2() { cout << "d  "; }
};

class Two: public Base {
    void ph1() { cout << "2  "; }
    void ph2() { cout << "4  "; }
};

int main() {
    Base *array[] = { new One(), new Two() };
    for (int i = 0; i < 2; i++) {
        array[i]->execute();
        cout << '\n';
    }
}
```

Output:
```
a  b  c  d  e
a  2  c  4  e
```

#### Example 2: Before and after refactoring

Before - duplicated sort logic:

```cpp
class SortUp {
public:
    void sort(int v[], int n) {
        for (int g = n / 2; g > 0; g /= 2)
          for (int i = g; i < n; i++)
            for (int j = i - g; j >= 0; j -= g)
              if (v[j] > v[j + g])
                doSwap(v[j], v[j + g]);
    }
private:
    void doSwap(int &a, int &b) { int t = a; a = b; b = t; }
};

class SortDown {
public:
    void sort(int v[], int n) {
        for (int g = n / 2; g > 0; g /= 2)
          for (int i = g; i < n; i++)
            for (int j = i - g; j >= 0; j -= g)
              if (v[j] < v[j + g])
                doSwap(v[j], v[j + g]);
    }
private:
    void doSwap(int &a, int &b) { int t = a; a = b; b = t; }
};
```

After - template method extracts the common algorithm:

```cpp
class AbstractSort {
public:
    void sort(int v[], int n) {
        for (int g = n / 2; g > 0; g /= 2)
          for (int i = g; i < n; i++)
            for (int j = i - g; j >= 0; j -= g)
              if (needSwap(v[j], v[j + g]))
                doSwap(v[j], v[j + g]);
    }
private:
    virtual int needSwap(int, int) = 0;
    void doSwap(int &a, int &b) { int t = a; a = b; b = t; }
};

class SortUp: public AbstractSort {
    int needSwap(int a, int b) { return (a > b); }
};

class SortDown: public AbstractSort {
    int needSwap(int a, int b) { return (a < b); }
};
```

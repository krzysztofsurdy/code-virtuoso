# Iterator Pattern

## Overview

The Iterator pattern is a behavioral design pattern that provides a way to access elements of a collection sequentially without exposing its underlying representation. It defines a common interface for traversing different data structures, allowing clients to iterate through collections without understanding their internal architecture.

## Intent

- Provide a way to access elements of a collection sequentially
- Encapsulate the traversal logic within an iterator object
- Enable different iteration strategies without modifying the collection
- Decouple collection implementation from client traversal code
- Support multiple simultaneous iterations over the same collection
- Hide the internal structure of the collection from clients

## Problem & Solution

### Problem

1. **Hidden Structure Coupling**: Clients directly coupled to collection internal structures (arrays, linked lists, trees)
2. **Multiple Traversal Strategies**: Different iteration patterns require repeated, complex logic in client code
3. **Collection Contamination**: Mixing traversal logic with collection management violates separation of concerns
4. **Inconsistent Access**: Different collections force clients to learn different access patterns
5. **Simultaneous Iterations**: Multiple iterations over the same collection interfere with state management

### Solution

Create an iterator object that handles the traversal logic independently:
1. Define an Iterator interface with common traversal methods
2. Implement concrete iterators for each collection type
3. Implement a collection method to create and return iterators
4. Clients use the iterator interface regardless of collection type
5. Collections remain focused on element management, not traversal

## Structure

```
Client Code
    ↓
Iterator Interface (hasNext(), next(), current(), key(), valid())
    ↑
    ├─ ConcreteIteratorA
    └─ ConcreteIteratorB
         ↑
    Aggregate Interface (createIterator())
         ↑
    ├─ ConcreteCollectionA
    └─ ConcreteCollectionB
```

## When to Use

- **Multiple Collection Types**: Need uniform access to different data structures
- **Complex Traversals**: Support various iteration strategies (forward, backward, filtered, sorted)
- **Separation of Concerns**: Keep collection and traversal logic separate
- **Simultaneous Iterations**: Multiple clients need to iterate independently over same collection
- **Internal Structure Privacy**: Hide collection implementation details
- **Lazy Loading**: Iterate large datasets without loading all into memory
- **Graph Traversals**: Implement DFS, BFS, or other graph iteration patterns
- **Custom Sequences**: Define custom iteration orders beyond default structure order

## Implementation

### PHP 8.3+ Example: File Collection Iterator

```php
<?php
declare(strict_types=1);

readonly interface Iterator {
    public function current(): mixed;
    public function key(): mixed;
    public function next(): void;
    public function rewind(): void;
    public function valid(): bool;
}

readonly interface Aggregate {
    public function createIterator(): Iterator;
}

readonly class FileIterator implements Iterator {
    private int $position = 0;

    public function __construct(
        private array $files
    ) {}

    public function current(): mixed {
        return $this->files[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        ++$this->position;
    }

    public function rewind(): void {
        $this->position = 0;
    }

    public function valid(): bool {
        return isset($this->files[$this->position]);
    }
}

readonly class FileCollection implements Aggregate {
    public function __construct(
        private array $files
    ) {}

    public function createIterator(): Iterator {
        return new FileIterator($this->files);
    }

    public function addFile(string $filename): void {
        $this->files[] = $filename;
    }
}

// Usage
$collection = new FileCollection(['file1.txt', 'file2.txt', 'file3.txt']);
$iterator = $collection->createIterator();

foreach ($iterator as $file) {
    echo "Processing: $file\n";
}
```

### Database Record Iterator

```php
<?php
declare(strict_types=1);

readonly class DatabaseRecordIterator implements Iterator {
    private int $position = 0;
    private array $records = [];

    public function __construct(
        private PDO $connection,
        private string $query
    ) {
        $this->loadRecords();
    }

    private function loadRecords(): void {
        $statement = $this->connection->prepare($this->query);
        $statement->execute();
        $this->records = $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    public function current(): mixed {
        return $this->records[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        ++$this->position;
    }

    public function rewind(): void {
        $this->position = 0;
    }

    public function valid(): bool {
        return isset($this->records[$this->position]);
    }
}

readonly class UserRepository {
    public function __construct(
        private PDO $connection
    ) {}

    public function findAllIterator(): Iterator {
        return new DatabaseRecordIterator(
            $this->connection,
            'SELECT id, name, email FROM users ORDER BY id'
        );
    }
}

// Usage
$pdo = new PDO('mysql:host=localhost;dbname=app', 'user', 'password');
$userRepo = new UserRepository($pdo);

foreach ($userRepo->findAllIterator() as $user) {
    echo "User: {$user['name']} ({$user['email']})\n";
}
```

### Reverse Iterator Implementation

```php
<?php
declare(strict_types=1);

readonly class ReverseIterator implements Iterator {
    private int $position;

    public function __construct(
        private array $items
    ) {
        $this->position = count($items) - 1;
    }

    public function current(): mixed {
        return $this->items[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        --$this->position;
    }

    public function rewind(): void {
        $this->position = count($this->items) - 1;
    }

    public function valid(): bool {
        return $this->position >= 0 && isset($this->items[$this->position]);
    }
}

// Usage
$items = ['apple', 'banana', 'cherry'];
$reverseIterator = new ReverseIterator($items);

foreach ($reverseIterator as $key => $item) {
    echo "[$key] => $item\n";
}
// Output: [2] => cherry, [1] => banana, [0] => apple
```

## Real-World Analogies

**Library Card Catalog**: Catalog drawers provide an iterator-like interface. You open a drawer and flip through cards sequentially without needing to understand how cards are organized internally.

**Restaurant Menu Navigation**: Waiters iterate through menu items when describing specials, following a sequence regardless of how items are internally categorized.

**Traffic Light Sequence**: A traffic signal cycles through states (red, yellow, green) following a predetermined iteration pattern that drivers depend on.

**Book Chapter Navigation**: A book's table of contents provides an iterator-like structure to move through chapters sequentially without reorganizing the book itself.

## Pros and Cons

### Advantages
- **Separation of Concerns**: Traversal logic separated from collection structure
- **Single Responsibility**: Collections manage storage, iterators handle traversal
- **Uniform Interface**: Access different collections consistently
- **Multiple Iterations**: Support simultaneous independent iterations
- **Encapsulation**: Hide collection implementation details
- **Extensibility**: Add new iteration strategies without modifying collections
- **Lazy Evaluation**: Iterate large datasets efficiently

### Disadvantages
- **Added Complexity**: Creates additional classes and interfaces
- **Performance Overhead**: Extra abstraction layer may slow simple iterations
- **Memory Usage**: Iterators maintain additional state and position tracking
- **Language Support**: Native PHP iteration sometimes simpler than custom iterators
- **Debugging Difficulty**: Abstraction can make tracking iteration flow harder
- **Synchronization Issues**: Concurrent modifications during iteration cause errors

## Relations with Other Patterns

- **Composite**: Iterator commonly traverses hierarchical Composite structures
- **Factory Method**: Collections use factories to create appropriate iterators
- **Strategy**: Different iterators act as strategies for different traversal approaches
- **Command**: Can encapsulate iteration sequences as command objects
- **Memento**: Iterators can capture and restore iteration state
- **Template Method**: Defines skeleton of iteration algorithm
- **Visitor**: Works with iterators to process collection elements

## Examples in Other Languages

### Java

Before and after: encapsulating iteration to prevent external access to internal collection:

```java
class IntegerBox {
    private List<Integer> list = new ArrayList<>();

    public class Iterator {
        private IntegerBox box;
        private java.util.Iterator iterator;
        private int value;

        public Iterator(IntegerBox integerBox) {
            box = integerBox;
        }

        public void first() {
            iterator = box.list.iterator();
            next();
        }

        public void next() {
            try {
                value = (Integer)iterator.next();
            } catch (NoSuchElementException ex) {
                value = -1;
            }
        }

        public boolean isDone() {
            return value == -1;
        }

        public int currentValue() {
            return value;
        }
    }

    public void add(int in) {
        list.add(in);
    }

    public Iterator getIterator() {
        return new Iterator(this);
    }
}

public class IteratorDemo {
    public static void main(String[] args) {
        IntegerBox integerBox = new IntegerBox();
        for (int i = 9; i > 0; --i) {
            integerBox.add(i);
        }
        // Supports multiple simultaneous iterators
        IntegerBox.Iterator firstItr = integerBox.getIterator();
        IntegerBox.Iterator secondItr = integerBox.getIterator();
        for (firstItr.first(); !firstItr.isDone(); firstItr.next()) {
            System.out.print(firstItr.currentValue() + "  ");
        }
        System.out.println();
        for (firstItr.first(), secondItr.first(); !firstItr.isDone();
             firstItr.next(), secondItr.next()) {
            System.out.print(firstItr.currentValue() + " "
                + secondItr.currentValue() + "  ");
        }
    }
}
```

### Python

```python
import collections.abc


class ConcreteAggregate(collections.abc.Iterable):
    """
    Implement the Iterator creation interface to return an instance of
    the proper ConcreteIterator.
    """

    def __init__(self):
        self._data = None

    def __iter__(self):
        return ConcreteIterator(self)


class ConcreteIterator(collections.abc.Iterator):
    """
    Implement the Iterator interface.
    """

    def __init__(self, concrete_aggregate):
        self._concrete_aggregate = concrete_aggregate

    def __next__(self):
        if True:  # if no_elements_to_traverse:
            raise StopIteration
        return None  # return element


def main():
    concrete_aggregate = ConcreteAggregate()
    for _ in concrete_aggregate:
        pass


if __name__ == "__main__":
    main()
```

### C++

Stack iterator with friend class access and operator overloading for equality comparison:

```cpp
#include <iostream>
using namespace std;

class Stack
{
    int items[10];
    int sp;
  public:
    friend class StackIter;
    Stack()
    {
        sp = -1;
    }
    void push(int in)
    {
        items[++sp] = in;
    }
    int pop()
    {
        return items[sp--];
    }
    bool isEmpty()
    {
        return (sp == -1);
    }
    StackIter *createIterator() const;
};

class StackIter
{
    const Stack *stk;
    int index;
  public:
    StackIter(const Stack *s)
    {
        stk = s;
    }
    void first()
    {
        index = 0;
    }
    void next()
    {
        index++;
    }
    bool isDone()
    {
        return index == stk->sp + 1;
    }
    int currentItem()
    {
        return stk->items[index];
    }
};

StackIter *Stack::createIterator() const
{
  return new StackIter(this);
}

bool operator == (const Stack &l, const Stack &r)
{
  StackIter *itl = l.createIterator();
  StackIter *itr = r.createIterator();
  for (itl->first(), itr->first(); !itl->isDone(); itl->next(), itr->next())
    if (itl->currentItem() != itr->currentItem())
      break;
  bool ans = itl->isDone() && itr->isDone();
  delete itl;
  delete itr;
  return ans;
}

int main()
{
  Stack s1;
  for (int i = 1; i < 5; i++)
    s1.push(i);
  Stack s2(s1), s3(s1), s4(s1), s5(s1);
  s3.pop();
  s5.pop();
  s4.push(2);
  s5.push(9);
  cout << "1 == 2 is " << (s1 == s2) << endl;
  cout << "1 == 3 is " << (s1 == s3) << endl;
  cout << "1 == 4 is " << (s1 == s4) << endl;
  cout << "1 == 5 is " << (s1 == s5) << endl;
}
```
